// lib/features/attendance/presentation/screens/home_screen.dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/localstore/local_database_service.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/notifications/journey_reminders.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/excel_exporter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../../../core/utils/roles.dart';
import '../../../../core/utils/time_format.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/widgets/offline_status_banner.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../../../../shared/widgets/control_ai_logo.dart';
import '../../../history/presentation/viewmodels/history_viewmodel.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../qr/presentation/widgets/generate_qr_dialog.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../data/repositories/attendance_repository_impl.dart';

/// HomeScreen — Main dashboard.
/// SRP: displays quick actions and last activity. Delegates navigation.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Instancia única del servicio de ubicación (sin estados internos).
  static const _location = LocationService();

  int _currentNav = 0;
  bool _registering = false;

  String _currentAddress = 'Obteniendo GPS...';
  String _coordsStr = 'Buscando satélites...';
  bool _hasGpsFix = false;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  /// Estado GPS HONESTO: si no hay señal/permiso, se muestra tal cual —
  /// nunca coordenadas ficticias que aparenten un fix inexistente.
  Future<void> _startLocationTracking() async {
    setState(() => _loadingLocation = true);
    try {
      // Estado real de servicio + permiso (misma fuente que Configuración).
      final status = await _location.checkStatus();
      if (!mounted) return;

      if (!status.serviceEnabled) {
        _setGpsUnavailable('Servicio de ubicación desactivado',
            'Actívalo en los ajustes del sistema');
        return;
      }
      if (!status.permissionGranted) {
        _setGpsUnavailable('Permiso de ubicación denegado',
            'Concede el permiso en Configuración');
        return;
      }

      // Fix real con timeout duro (5s): GPS + geocoding inverso en un solo call.
      final location = await _location.capture();
      if (!mounted) return;

      if (location == null) {
        _setGpsUnavailable(
            'Ubicación no disponible', 'Toca refrescar para reintentar');
        return;
      }

      setState(() {
        _coordsStr =
            '${location.lat.toStringAsFixed(4)}°, ${location.lng.toStringAsFixed(4)}°';
        _currentAddress = location.dir ?? 'Posición GPS obtenida';
        _hasGpsFix = true;
        _loadingLocation = false;
      });
    } catch (_) {
      _setGpsUnavailable(
          'Ubicación no disponible', 'Toca refrescar para reintentar');
    }
  }

  void _setGpsUnavailable(String reason, String hint) {
    if (!mounted) return;
    setState(() {
      _currentAddress = reason;
      _coordsStr = hint;
      _hasGpsFix = false;
      _loadingLocation = false;
    });
  }

  /// C1: el flujo manual de "Marcar Asistencia" llama al endpoint real.
  /// El servidor decide el tipo (entrada/salida) — C2.
  Future<void> _registerAttendance() async {
    if (_registering) return;
    setState(() => _registering = true);

    try {
      // El id viene de la sesión autenticada (reactiva, no del storage crudo).
      final session = ref.read(sessionControllerProvider);
      if (session is! SessionAuthenticated) {
        throw UnknownException(
            message: 'Sesión inválida. Vuelve a iniciar sesión.');
      }

      final repository = ref.read(attendanceRepositoryProvider);
      final AttendanceEntity record =
          await repository.register(session.user.id);

      // Invalida el estado del historial para refrescar automáticamente el resumen del día
      ref.invalidate(historyViewModelProvider);

      if (!mounted) return;
      final query = StringBuffer('?tipo=${record.tipo}');
      query.write('&fecha=${record.fecha.toIso8601String().split('T').first}');
      query.write('&hora=${_formatHora(record.hora)}');
      context.go('${AppRoutes.confirmation}$query');
    } on AppException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  /// Próximo tipo de marca según los registros de HOY (más reciente primero).
  /// Espejo informativo de la máquina de estado del servidor.
  String _nextTipoJornada(List<AttendanceEntity> records) {
    final now = DateTime.now();
    AttendanceEntity? lastToday;
    for (final r in records) {
      // toLocal(): la fecha del servidor es UTC — se compara con el día local.
      final local = r.fecha.toLocal();
      if (local.year == now.year &&
          local.month == now.month &&
          local.day == now.day) {
        lastToday = r;
        break; // lista ordenada descendente: el primero de hoy es el último marcado
      }
    }
    if (lastToday == null) return 'entrada';
    return const {
          'entrada': 'salida_almuerzo',
          'salida_almuerzo': 'regreso_almuerzo',
          'regreso_almuerzo': 'salida',
          'salida': 'entrada',
        }[lastToday.tipo] ??
        'entrada';
  }

  String _formatHora(DateTime hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    final s = hora.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.systemRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// H3: exporta el Excel con token Bearer (Dio) y lo abre — lógica única
  /// en [ExcelExporter] (también la usa el panel admin).
  Future<void> _exportExcel() async {
    if (kIsWeb) {
      _showError('La exportación a Excel está disponible en la app móvil.');
      return;
    }

    try {
      final path = await ExcelExporter(
        ref.read(dioProvider),
        localDb: ref.read(localDatabaseServiceProvider),
      ).exportAndOpen();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Reporte Excel generado correctamente:\n$path'),
            backgroundColor: AppColors.systemGreen,
            duration: const Duration(seconds: 4),
          ),
        );
    } on AppException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(
          'Error al exportar: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'Buenos días,';
    if (hour >= 12 && hour < 19) {
      greeting = 'Buenas tardes,';
    } else if (hour >= 19 || hour < 5) {
      greeting = 'Buenas noches,';
    }

    // Sesión reactiva: el perfil actualizado se refleja sin releer storage.
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;

    final historyState = ref.watch(historyViewModelProvider);
    final records = historyState.valueOrNull ?? const <AttendanceEntity>[];

    // Recordatorios reales del día + preferencia de Configuración.
    final notificationsEnabled =
        ref.watch(notificationsEnabledProvider).valueOrNull ?? true;
    final pendingReminders =
        notificationsEnabled && computeJourneyReminders(records).isNotEmpty;

    final lastActivityStr = historyState.maybeWhen(
      data: (records) {
        if (records.isNotEmpty) {
          final r = records.first;
          final fecha = DateFormat('dd/MM/yyyy').format(r.fecha.toLocal());
          final hora = formatTimeOfDay(context, r.hora.toLocal());
          return '$fecha $hora';
        }
        return 'Sin registros';
      },
      orElse: () => '--:--',
    );

    // Próxima marca de la jornada — espejo de la máquina de estado del
    // servidor (entrada â†’ almuerzo â†’ regreso â†’ salida â†’ nueva entrada).
    // El servidor decide siempre; esto es solo información de UI.
    final nextTipo = _nextTipoJornada(records);
    final nextInfo = attendanceTypeInfo(nextTipo);

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: _buildCupertinoNavBar(hasPendingReminder: pendingReminders),
      body: Column(
        children: [
          const OfflineStatusBanner(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: context.cGradientBackground,
              ),
              child: SafeArea(
                child: IndexedStack(
                  index: _currentNav,
                  children: [
                    // Tab 0: Home Dashboard
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting — wireframe: nombre completo + cargo + ID
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: context.cGray,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                user?.fullName ?? 'Empleado',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: context.cTextPrimary,
                                      letterSpacing: -1.0,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${user?.cargo ?? 'Empleado'} · C.C. ${user?.cedula ?? '---'}',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: context.cGray,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 10),
                              // Reloj del DISPOSITIVO en tiempo real: la hora exacta
                              // del teléfono (zona horaria + formato 12/24h del
                              // sistema), actualizándose cada segundo.
                              const _LiveClock(),
                            ],
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.1, end: 0),
                          const SizedBox(height: 20),

                          // â”€â”€ Rastreador GPS en Tiempo Real & Punto de Trabajo â”€â”€
                          _LiveLocationTrackerCard(
                            address: _currentAddress,
                            coords: _coordsStr,
                            hasFix: _hasGpsFix,
                            isLoading: _loadingLocation,
                            onRefresh: _startLocationTracking,
                          )
                              .animate()
                              .fadeIn(delay: 100.ms, duration: 400.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 20),

                          // â”€â”€ Resumen del día (estado REAL de la jornada) â”€â”€
                          DaySummaryCard(
                            records: records,
                          )
                              .animate()
                              .fadeIn(delay: 150.ms, duration: 400.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 16),

                          // â”€â”€ Primary Action Card (Escanear QR) — acción principal del plano â”€â”€
                          _PremiumCard(
                            title: 'Escanear QR',
                            subtitle: 'Registra tu asistencia con el código',
                            icon: Icons.qr_code_scanner,
                            gradient: AppColors.gradientQR,
                            onTap: () => context.push(AppRoutes.qrScan),
                            height: 150,
                          )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 400.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 16),

                          // â”€â”€ Grid Dashboard — botón dinámico: muestra la PRÓXIMA
                          // marca de la jornada con su color e ícono semántico.
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final singleColumn = constraints.maxWidth < 520;
                              final cardWidth = singleColumn
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 16) / 2;
                              final cardHeight = singleColumn ? 136.0 : 170.0;

                              return Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    child: _PremiumCard(
                                      title: _registering
                                          ? 'Registrando...'
                                          : 'Marcar ${attendanceTypeShort(nextTipo)}',
                                      subtitle: 'Con ubicación en tiempo real',
                                      icon: nextInfo.icon,
                                      gradient: LinearGradient(
                                        colors: [
                                          nextInfo.color,
                                          Color.lerp(nextInfo.color,
                                              Colors.black, 0.25)!,
                                        ],
                                      ),
                                      onTap: _registering
                                          ? null
                                          : _registerAttendance,
                                      height: cardHeight,
                                      loading: _registering,
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(delay: 300.ms, duration: 400.ms)
                                      .slideY(begin: 0.1, end: 0),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _PremiumCard(
                                      title: 'Historial',
                                      subtitle: 'Tus registros',
                                      icon: Icons.history,
                                      gradient: AppColors.gradientHistory,
                                      onTap: () =>
                                          context.push(AppRoutes.history),
                                      height: cardHeight,
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(delay: 400.ms, duration: 400.ms)
                                      .slideY(begin: 0.1, end: 0),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 16),
                          _PremiumCard(
                            title: 'Mensajería interna',
                            subtitle: 'Chat privado con tu equipo de trabajo',
                            icon: Icons.forum_rounded,
                            gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
                            onTap: () => context.push(AppRoutes.messages),
                            height: 120,
                          )
                              .animate()
                              .fadeIn(delay: 430.ms, duration: 400.ms)
                              .slideY(begin: 0.1, end: 0),

                          if (AppRoles.isAdminRole(user?.cargo)) ...[
                            const SizedBox(height: 32),
                            Text(
                              'Panel Administrador',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: context.cTextPrimary,
                                letterSpacing: -0.5,
                              ),
                            ).animate().fadeIn(delay: 450.ms),
                            const SizedBox(height: 16),
                            // Asistencia Hoy — pantalla de empleados con estado del día.
                            _PremiumCard(
                              title: 'Asistencia de hoy',
                              subtitle:
                                  'Consulta llegadas, retrasos y pendientes',
                              icon: Icons.groups,
                              gradient: const LinearGradient(colors: [
                                AppColors.accentIndigo,
                                Color(0xFF4338CA)
                              ]),
                              onTap: () =>
                                  context.push(AppRoutes.employeeToday),
                              height: 120,
                            )
                                .animate()
                                .fadeIn(delay: 380.ms, duration: 400.ms)
                                .slideY(begin: 0.1, end: 0),
                            const SizedBox(height: 16),
                            Row(children: [
                              Expanded(
                                child: _PremiumCard(
                                  title: 'Exportar a Excel',
                                  subtitle: 'Reporte completo',
                                  icon: Icons.download,
                                  gradient: const LinearGradient(colors: [
                                    AppColors.systemGreenDark,
                                    Color(0xFF047857)
                                  ]),
                                  onTap: _exportExcel,
                                  height: 170,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _PremiumCard(
                                  title: 'Generar QR',
                                  subtitle: 'Para un empleado',
                                  icon: Icons.qr_code,
                                  gradient: const LinearGradient(colors: [
                                    AppColors.accentIndigo,
                                    Color(0xFF5B21B6)
                                  ]),
                                  onTap: () =>
                                      showGenerateQrDialog(context, ref),
                                  height: 170,
                                ),
                              ),
                            ]),
                          ],

                          const SizedBox(height: 32),

                          // â”€â”€ Info banner
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              // Fondo contextual: blanco translúcido en light, oscuro en dark.
                              color: context.isDark
                                  ? context.cSurface.withValues(alpha: 0.75)
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: context.isDark
                                    ? context.cBorder
                                    : Colors.white,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: AppColors.systemBlue
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.sync,
                                      color: AppColors.systemBlue),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Sincronizado',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      Text(
                                          'Última actividad: $lastActivityStr',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: context.cGray)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                        ],
                      ),
                    ),
                    // Tab 1: Perfil completo
                    const ProfileScreen(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // â”€â”€ Bottom Navigation
      bottomNavigationBar: _buildCupertinoBottomBar(),
    );
  }

  PreferredSizeWidget _buildCupertinoNavBar(
      {required bool hasPendingReminder}) {
    return AppBar(
      backgroundColor: context.cSurface,
      elevation: 0,
      centerTitle: true,
      title: _currentNav == 0
          ? const ControlAiLogo(size: 28, showSubtitle: false)
          : Text('Mi Perfil',
              style: TextStyle(
                  color: context.cTextPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  letterSpacing: -0.41)),
      actions: [
        // Campana con badge REAL: el punto rojo aparece solo cuando hay
        // recordatorios pendientes calculados y las notificaciones están activas.
        Stack(
          clipBehavior: Clip.none,
          children: [
            AppButtons.iconStandard(
              icon: Icons.notifications,
              color: AppColors.primary,
              onPressed: () => _showNotifications(context),
            ),
            if (hasPendingReminder)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.systemRed,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                        BorderSide(color: context.cSurface, width: 1.5)),
                  ),
                ),
              ),
          ],
        ),
        AppButtons.iconStandard(
          icon: Icons.settings,
          color: AppColors.primary,
          onPressed: () => context.push(AppRoutes.settings),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          color: context.cGray4.withValues(alpha: 0.5),
          height: 0.5,
        ),
      ),
    );
  }

  Widget _buildCupertinoBottomBar() {
    return CupertinoTabBar(
      currentIndex: _currentNav,
      onTap: (i) => setState(() => _currentNav = i),
      backgroundColor: context.cSurface.withValues(alpha: 0.9),
      activeColor: AppColors.systemBlue,
      inactiveColor: context.cGray,
      border: Border(
          top: BorderSide(
              color: context.cGray4.withValues(alpha: 0.5), width: 0.5)),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }

  /// Notificaciones REALES: recordatorios calculados desde la jornada del día
  /// (registros de la API). Sin sistema push — estado honesto y accionable.
  void _showNotifications(BuildContext context) {
    final records = ref.read(historyViewModelProvider).valueOrNull ??
        const <AttendanceEntity>[];
    final reminders = computeJourneyReminders(records);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notificaciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Recordatorios de tu jornada de hoy',
              style: TextStyle(fontSize: 13, color: context.cGray),
            ),
            const SizedBox(height: 16),
            if (reminders.isEmpty)
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.systemGreen,
                    child: Icon(Icons.check_circle, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Jornada al día — sin recordatorios pendientes',
                      style:
                          TextStyle(fontSize: 15, color: context.cTextPrimary),
                    ),
                  ),
                ],
              )
            else
              ...reminders.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: r.color.withValues(alpha: 0.12),
                        child: Icon(r.icon, color: r.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.titulo,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: context.cTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              r.detalle,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.cGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Premium Cards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PremiumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback? onTap;
  final double height;
  final bool loading;

  const _PremiumCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    required this.height,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final compact = height <= 140;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Padding(
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 18, vertical: 16)
                : const EdgeInsets.all(20),
            child: compact
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.84),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Resumen del día — estado REAL de la jornada desde los registros de la API.
/// Muestra las 4 marcas del plano: Entrada · Almuerzo · Regreso · Salida.
class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({super.key, required this.records});

  final List<AttendanceEntity> records;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // La fecha del registro viene del servidor en UTC: convertir a local
    // ANTES de comparar con "hoy" (si no, las marcas de la tarde/noche se
    // pierden del resumen del día).
    final todayLocal = records.where((r) {
      final local = r.fecha.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).toList()
      // Orden cronológico para aislar la jornada actual.
      ..sort((a, b) => a.hora.compareTo(b.hora));

    // â”€â”€ Jornada ACTUAL (la más reciente del día) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // El día puede tener varias jornadas (turnos/dobles marcas): el resumen
    // muestra SOLO la última secuencia entradaâ†’â€¦â†’salida, sin mezclar horas
    // de jornadas distintas (antes mezclaba y la secuencia era imposible).
    var inicio = 0;
    for (var i = 0; i < todayLocal.length; i++) {
      if (todayLocal[i].tipo == 'entrada') inicio = i;
    }
    final jornadaActual = todayLocal.sublist(inicio);

    AttendanceEntity? mEntrada;
    AttendanceEntity? mAlmuerzo;
    AttendanceEntity? mRegreso;
    AttendanceEntity? mSalida;
    for (final r in jornadaActual) {
      switch (r.tipo) {
        case 'entrada':
          mEntrada ??= r;
        case 'salida_almuerzo':
          mAlmuerzo = r;
        case 'regreso_almuerzo':
          mRegreso = r;
        case 'salida':
          mSalida = r;
      }
    }
    final marcas = [mEntrada, mAlmuerzo, mRegreso, mSalida];
    final ultima = jornadaActual.isNotEmpty ? jornadaActual.last : null;
    final completada = mEntrada != null &&
        mAlmuerzo != null &&
        mRegreso != null &&
        mSalida != null;

    final String estadoTitulo;
    final Color estadoColor;
    if (completada) {
      estadoTitulo = 'Jornada completada';
      estadoColor = AppColors.systemBlue;
    } else if (ultima != null) {
      final info = attendanceTypeInfo(ultima.tipo);
      // Etiqueta corta para que el chip no desborde en pantallas angostas.
      estadoTitulo = 'Activa · ${attendanceTypeShort(ultima.tipo)}';
      estadoColor = info.color;
    } else {
      estadoTitulo = 'Sin registrar hoy';
      estadoColor = context.cGray;
    }

    // Tiempo laborado del día COMPLETO (suma todas las jornadas del día).
    final workedLabel = calculateWorkedHoursLabel(todayLocal);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Fondo contextual: blanco translúcido en light, oscuro en dark.
        color: context.isDark
            ? context.cSurface.withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDark ? context.cBorder : Colors.white,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Estado del día',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.cTextPrimary,
                        fontSize: 15)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(estadoTitulo,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: estadoColor)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 4 marcas en orden de jornada. Organización responsive:
          // fila de 4 chips compactos en pantallas anchas, grid 2x2 con
          // etiquetas COMPLETAS ("Salida a almorzar", "Regreso de almuerzo")
          // en pantallas angostas — nada se corta.
          LayoutBuilder(
            builder: (context, constraints) {
              // Icono distintivo por marca (login/restaurant/work/logout).
              final tipos = [
                'entrada',
                'salida_almuerzo',
                'regreso_almuerzo',
                'salida'
              ];
              final labels = [
                for (final t in tipos)
                  (
                    attendanceTypeInfo(t).label,
                    attendanceTypeInfo(t).color,
                    attendanceTypeInfo(t).icon,
                    marcas[tipos.indexOf(t)],
                  ),
              ];
              final wide = constraints.maxWidth >= 480;

              if (wide) {
                return Row(
                  children: [
                    for (final (label, color, icon, marca) in labels) ...[
                      Expanded(
                        child: _MarkChip(
                          label: label,
                          hora: marca == null
                              ? '--:--'
                              : formatTimeOfDay(context, marca.hora),
                          color: color,
                          icon: icon,
                          active: marca != null,
                        ),
                      ),
                      if (label != labels.last.$1) const SizedBox(width: 8),
                    ],
                  ],
                );
              }
              // 2x2: chips más grandes con etiquetas completas legibles.
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                // Altura accesible para escala de fuente Android sin overflow.
                childAspectRatio: 1.9,
                children: [
                  for (final (label, color, icon, marca) in labels)
                    _MarkChip(
                      label: label,
                      hora: marca == null
                          ? '--:--'
                          : formatTimeOfDay(context, marca.hora),
                      color: color,
                      icon: icon,
                      active: marca != null,
                    ),
                ],
              );
            },
          ),
          if (todayLocal.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  // Flexible: en pantallas angostas el label se encoge y el
                  // tiempo calculado siempre queda visible (sin overflow).
                  Flexible(
                    child: Text(
                      'Tiempo Laborado Hoy: ',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.cTextSecondary,
                      ),
                    ),
                  ),
                  Text(
                    workedLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reloj en tiempo real del DISPOSITIVO.
/// Muestra la hora exacta del teléfono — con la zona horaria y el formato
/// (12h/24h) que el propio sistema maneja — actualizándose cada segundo.
class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    // Tick cada segundo: la hora mostrada es SIEMPRE la del dispositivo.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Fecha con el locale de la app (es): "sábado 2 ago 2026".
    final fecha = DateFormat('EEEE d \'de\' MMMM yyyy', 'es').format(now);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 16, color: context.cGray),
        const SizedBox(width: 6),
        Text(
          // Hora del dispositivo con su formato real (12h AM/PM o 24h).
          formatTimeOfDay(context, now),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.cTextPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 8),
        // Fecha larga: con ellipsis si la pantalla es muy angosta (evita solapamiento).
        Flexible(
          child: Text(
            fecha,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13,
                color: context.cGray,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _MarkChip extends StatelessWidget {
  const _MarkChip({
    required this.label,
    required this.hora,
    required this.color,
    required this.icon,
    required this.active,
  });

  final String label;
  final String hora;
  final Color color;

  /// Icono distintivo de la marca (login/restaurant/work/logout).
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.1)
              : context.cGray5.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: active ? color : context.cGray4),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: active ? color : context.cGray)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              hora,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: active ? context.cTextPrimary : context.cGray2,
              ),
            ),
          ],
        ),
      );
}

/// Widget de Rastreo GPS y Ubicación en Tiempo Real
class _LiveLocationTrackerCard extends StatelessWidget {
  const _LiveLocationTrackerCard({
    required this.address,
    required this.coords,
    required this.hasFix,
    required this.isLoading,
    required this.onRefresh,
  });

  final String address;
  final String coords;
  final bool hasFix;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Fondo contextual: la card era blanca fija â†’ textos claros invisibles en dark.
        color: context.cSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cBorder),
        boxShadow: DesignTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.my_location,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UBICACIÓN GPS EN TIEMPO REAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rastreo de punto de trabajo activo',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.cTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary))
                    : Icon(Icons.refresh, size: 20, color: context.cGray),
                onPressed: isLoading ? null : onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.cBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasFix
                      ? AppColors.systemGreen.withValues(alpha: 0.12)
                      : AppColors.systemOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        hasFix ? AppColors.systemGreen : AppColors.systemOrange,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: hasFix
                            ? AppColors.systemGreen
                            : AppColors.systemOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasFix
                          ? 'GPS ACTIVO — POSICIÓN REAL'
                          : 'SIN SEÑAL GPS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hasFix
                            ? AppColors.systemGreenDark
                            : AppColors.systemOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.cTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Coordenadas: $coords',
            style: TextStyle(
              fontSize: 12,
              color: context.cGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
