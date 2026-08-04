import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/localstore/secure_storage_provider.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/notifications/journey_reminders.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/confirm_logout.dart';
import '../../../../shared/widgets/app_appbar.dart';

/// Módulo Configuración — preferencias reales y estado de permisos.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _location = LocationService();
  String _appVersion = '1.0.0';
  bool _cameraOk = false;
  bool _checkingCamera = false;
  bool _locationOk = false;
  bool _locationService = false;
  bool _clearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    _appVersion = AppConfig.appVersion;
    _refreshPermissions();
  }

  /// Estado REAL de permisos vía LocationService (misma fuente que el Home).
  Future<void> _refreshPermissions() async {
    final status = await _location.checkStatus();
    if (!mounted) return;
    setState(() {
      _locationOk = status.permissionGranted;
      _locationService = status.serviceEnabled;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    // Estado reactivo vía provider: el switch refleja la preferencia real.
    await ref.read(secureStorageProvider).write(
          key: AppConfig.keyNotificationsEnabled,
          value: value.toString(),
        );
    ref.invalidate(notificationsEnabledProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(value
              ? 'Recordatorios de jornada activados'
              : 'Recordatorios de asistencia desactivados'),
          backgroundColor: value ? AppColors.systemGreen : context.cGray,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// Verificación de cámara bajo demanda (el usuario la solicita explícitamente).
  Future<void> _checkCamera() async {
    if (_checkingCamera) return;
    setState(() => _checkingCamera = true);
    bool cam = false;
    try {
      final ctrl = MobileScannerController();
      await ctrl.start();
      cam = true;
      await ctrl.stop();
      await ctrl.dispose();
    } catch (_) {
      cam = false;
    }
    if (!mounted) return;
    setState(() {
      _cameraOk = cam;
      _checkingCamera = false;
    });
  }

  Future<void> _openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {}
  }

  Future<void> _openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);
    // Preferencia real de recordatorios (persistida en secure storage).
    final notificationsEnabled =
        ref.watch(notificationsEnabledProvider).valueOrNull ?? true;

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppAppBar(
        title: 'Configuración',
        centerTitle: true,
        leadingWidget: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, color: AppColors.systemBlue),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Encabezado de la app ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.verified_user,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SmartAttendance',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 2),
                      Text('Sistema de control de asistencia',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('v$_appVersion',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Tema ──
          const _SectionTitle('Apariencia'),
          _SettingsCard(
            children: [
              const _SettingRow(
                icon: Icons.dark_mode,
                accentColor: Color(0xFF8B5CF6),
                title: 'Tema',
                subtitle: 'Sistema, claro u oscuro',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.system, label: Text('Auto')),
                      ButtonSegment(
                          value: ThemeMode.light, label: Text('Claro')),
                      ButtonSegment(
                          value: ThemeMode.dark, label: Text('Oscuro')),
                    ],
                    selected: {themeMode},
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 10),
                      iconSize: 16,
                      visualDensity: VisualDensity.compact,
                      // Cada etiqueta escala si la pantalla es angosta:
                      // "Oscuro" ya no se corta en móviles pequeños.
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onSelectionChanged: (sel) => ref
                        .read(themeControllerProvider.notifier)
                        .setMode(sel.first),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Notificaciones ──
          const _SectionTitle('Notificaciones'),
          _SettingsCard(
            children: [
              _SettingRow(
                icon: Icons.notifications,
                accentColor: const Color(0xFFF59E0B),
                title: 'Recordatorios de jornada',
                subtitle: notificationsEnabled
                    ? 'Alertas activas para marcas de entrada y salida'
                    : 'Notificaciones desactivadas',
                trailing: Switch(
                  value: notificationsEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: _toggleNotifications,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Permisos (estado real) ──
          const _SectionTitle('Permisos'),
          _SettingsCard(
            children: [
              _SettingRow(
                icon: Icons.photo_camera,
                accentColor: const Color(0xFF3B82F6),
                title: 'Cámara',
                subtitle: _cameraOk
                    ? 'Disponible para escanear QR'
                    : (_checkingCamera
                        ? 'Verificando...'
                        : 'Toca para verificar el acceso a la cámara'),
                trailing: _checkingCamera
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : _statusChip(_cameraOk),
                onTap: _checkCamera,
              ),
              const Divider(height: 1),
              _SettingRow(
                icon: Icons.location_on,
                accentColor: const Color(0xFF22C55E),
                title: 'Ubicación',
                subtitle: _locationOk
                    ? 'Permiso concedido'
                    : 'Sin permiso — necesario para registrar la dirección',
                trailing: _statusChip(_locationOk),
                onTap: _openAppSettings,
              ),
              const Divider(height: 1),
              _SettingRow(
                icon: Icons.my_location,
                accentColor: const Color(0xFF14B8A6),
                title: 'Servicio de ubicación',
                subtitle:
                    _locationService ? 'Activado' : 'Desactivado en el sistema',
                trailing: TextButton(
                  onPressed: _openLocationSettings,
                  child: const Text('Abrir ajustes'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Acerca de & Legal ──
          const _SectionTitle('Acerca de & Legal'),
          _SettingsCard(
            children: [
              _SettingRow(
                icon: Icons.description,
                accentColor: const Color(0xFF6366F1),
                title: 'Términos y Políticas de Privacidad',
                subtitle: 'Tratamiento de datos personales y ubicación',
                trailing: Icon(Icons.chevron_right, color: context.cGray),
                onTap: () => _showTermsModal(context),
              ),
              const Divider(height: 1),
              _SettingRow(
                icon: Icons.cleaning_services,
                accentColor: const Color(0xFFF59E0B),
                title: 'Limpiar caché local',
                subtitle: _clearingCache
                    ? 'Limpiando...'
                    : 'Elimina archivos temporales (exportaciones, etc.)',
                trailing: _clearingCache
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.chevron_right, color: context.cGray),
                onTap: _clearingCache ? null : _clearCache,
              ),
              const Divider(height: 1),
              _SettingRow(
                icon: Icons.info,
                accentColor: context.cGray,
                title: 'Versión de la aplicación',
                subtitle: 'v$_appVersion',
                trailing: const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Sesión ──
          const _SectionTitle('Sesión'),
          _SettingsCard(
            children: [
              _SettingRow(
                icon: Icons.logout,
                accentColor: AppColors.systemRed,
                title: 'Cerrar sesión',
                subtitle: 'Sal de la cuenta en este dispositivo',
                trailing: Icon(Icons.chevron_right, color: context.cGray),
                onTap: _confirmLogout,
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Cierre de sesión real: diálogo compartido + limpieza de secure storage;
  /// el router observa la sesión y redirige a login.
  Future<void> _confirmLogout() async {
    await confirmLogout(context, ref);
  }

  void _showTermsModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Términos y Privacidad',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.cTextPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'SmartAttendance es la plataforma de registro de jornada laboral de tu organización.\n\n'
                  '1. Tratamiento de Datos Personales: Los datos recopilados (cédula, nombre, cargo) se utilizan exclusivamente para la gestión interna de nómina y control de asistencia.\n\n'
                  '2. Geolocalización: Los datos de ubicación se registran únicamente en el instante en que el usuario presiona el botón de registro o escanea un código QR, garantizando la privacidad fuera de la marca.\n\n'
                  '3. Seguridad de Acceso: El token de sesión y las credenciales permanecen encriptados localmente mediante enclaves seguros (Keystore / Keychain).\n\n'
                  'Para más información o consultas, contacta al departamento de Talento Humano de tu organización.',
                  style: TextStyle(
                      fontSize: 14, height: 1.5, color: context.cTextSecondary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Limpieza REAL: borra el contenido del directorio temporal de la app
  /// (exportaciones Excel, archivos intermedios). Reporta bytes liberados.
  Future<void> _clearCache() async {
    if (kIsWeb) {
      _showCacheResult('La limpieza de caché no aplica en la versión web',
          ok: false);
      return;
    }

    setState(() => _clearingCache = true);
    int freedBytes = 0;
    bool ok = true;
    try {
      final dir = await getTemporaryDirectory();
      await for (final entity in dir.list()) {
        try {
          if (entity is File) {
            freedBytes += await entity.length();
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        } catch (_) {
          // Archivo en uso por el SO — se omite sin abortar la limpieza.
        }
      }
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    setState(() => _clearingCache = false);
    final freedStr = freedBytes > 1024 * 1024
        ? '${(freedBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(freedBytes / 1024).toStringAsFixed(0)} KB';
    _showCacheResult(
      ok ? 'Caché liberado: $freedStr' : 'No se pudo limpiar el caché',
      ok: ok,
    );
  }

  void _showCacheResult(String message, {required bool ok}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(ok ? Icons.check_circle : Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: ok ? AppColors.systemGreen : AppColors.systemRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Widget _statusChip(bool ok) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (ok ? AppColors.systemGreen : AppColors.systemRed)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          ok ? 'OK' : 'Falta',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ok ? AppColors.systemGreen : AppColors.systemRed,
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.cGray,
                letterSpacing: 0.5)),
      );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(children: children),
      );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor = AppColors.primary,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12.5,
                          ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      );
}
