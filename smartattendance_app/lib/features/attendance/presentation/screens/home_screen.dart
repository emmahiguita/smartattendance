// lib/features/attendance/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../photo_attendance/domain/mark_sequence.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/presentation/local_day_history.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/photo_capture_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../widgets/corporate_app_bar.dart';
import '../widgets/home_dashboard_body.dart';
import 'admin_management_screen.dart';

/// ============================================================================
/// PANTALLA PRINCIPAL: HomeScreen (Arquitectura Modular SOLID)
/// ============================================================================
/// QUÉ HACE:
/// Contenedor de la navegación operativa de la app con separación estricta:
/// 1. Tab Marcaje: Marcación personal, cámara frontal y retícula Face ID inmediata.
/// 2. Tab Historial: Auditoría cronológica de registros del usuario.
/// 3. Tab Gestión RRHH: Módulo exclusivo de Talento Humano (jornadas, horas extras, plantilla).
/// 4. Tab Perfil: Ajustes de cuenta y sesión corporativa.
///
/// CÓMO FUNCIONA:
/// 1. Resuelve o auto-crea el trabajador en la base SQLite para garantizar que
///    tocar cualquier botón de marcaje (Entrada, Almuerzo, Salida) abra DE INMEDIATO
///    la cámara de reconocimiento facial con Google ML Kit sin pantallas intermedias.
/// 2. Separa las responsabilidades administrativas en un módulo dedicado y limpio.
/// ============================================================================
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNav = 0;
  String _address = 'Obteniendo ubicación…';
  String _coords = 'Sin coordenadas';
  double? _latitude, _longitude;
  bool _hasGpsFix = false, _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _refreshLocation();
  }

  Future<void> _refreshLocation() async {
    if (!_loadingLocation && mounted) setState(() => _loadingLocation = true);
    final loc = await const LocationService().capture();
    if (!mounted) return;
    setState(() {
      _latitude = loc?.lat;
      _longitude = loc?.lng;
      _hasGpsFix = loc != null;
      _loadingLocation = false;
      _address = loc?.dir ?? (loc == null ? 'Ubicación no disponible' : 'Posición GPS obtenida');
      _coords = loc == null ? 'Toca refrescar' : '${loc.lat.toStringAsFixed(4)}°, ${loc.lng.toStringAsFixed(4)}°';
    });
  }

  String _calculateNextTipo(List<dynamic> records) {
    final now = DateTime.now();
    final today = records.where((r) {
      final d = (r.fecha as DateTime).toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
    if (today.isEmpty) return 'entrada';
    return MarkSequence.next(today.last.tipo as String?);
  }

  Future<LocalWorker> _resolveOrCreateWorker() async {
    final workers = ref.read(localWorkersProvider).valueOrNull ?? const [];
    final session = ref.read(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;

    if (user != null) {
      for (final w in workers) {
        if (w.document == user.cedula ||
            (w.document.isNotEmpty && user.cedula.contains(w.document))) {
          return w;
        }
      }
    } else if (workers.isNotEmpty) {
      return workers.first;
    }

    // Auto-aprovisionar en SQLite si aún no existe para cumplir integridad referencial
    final db = await ref.read(localPhotoDatabaseProvider).database;
    final doc = (user?.cedula != null && user!.cedula.trim().isNotEmpty)
        ? user.cedula.trim()
        : '10000001';
    final name = (user?.fullName != null && user!.fullName.trim().isNotEmpty)
        ? user.fullName.trim()
        : 'Colaborador';
    final job = (user?.cargo != null && user!.cargo.trim().isNotEmpty)
        ? user.cargo.trim()
        : 'Personal Operativo';

    final existing = await db.query('workers', where: 'document = ?', whereArgs: [doc]);
    int workerId;
    if (existing.isEmpty) {
      workerId = await db.insert('workers', {
        'name': name,
        'document': doc,
        'job': job,
      });
    } else {
      workerId = existing.first['id'] as int;
    }

    ref.invalidate(localWorkersProvider);
    return LocalWorker(
      id: workerId,
      name: name,
      document: doc,
      job: job,
    );
  }

  Future<void> _capture([String? type]) async {
    try {
      final targetWorker = await _resolveOrCreateWorker();
      final markType = type ?? _calculateNextTipo(ref.read(localDayHistoryProvider).valueOrNull ?? const []);

      if (!mounted) return;
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoCaptureScreen(
            worker: targetWorker,
            initialType: markType,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error abriendo reconocimiento facial: $e');
    }

    if (mounted) {
      ref.invalidate(localDayHistoryProvider);
      ref.invalidate(localWorkersProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;
    final records = ref.watch(localDayHistoryProvider).valueOrNull ?? const [];
    final nextTipo = _calculateNextTipo(records);

    final body = IndexedStack(
      index: _currentNav,
      children: [
        HomeDashboardBody(
          user: user,
          address: _address,
          coords: _coords,
          latitude: _latitude,
          longitude: _longitude,
          hasFix: _hasGpsFix,
          isLoadingLocation: _loadingLocation,
          onRefreshLocation: _refreshLocation,
          records: records,
          nextTipo: nextTipo,
          registering: false,
          onRegisterAttendance: () => _capture(nextTipo),
          onSelectMark: (t) => _capture(t),
          onNavigateToAdmin: () => setState(() => _currentNav = 2),
        ),
        const HistoryScreen(),
        const AdminManagementScreen(),
        const ProfileScreen(),
      ],
    );

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: CorporateAppBar(
        user: user,
        currentNavIndex: _currentNav,
        onProfileTap: () => setState(() => _currentNav = 3),
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNav,
        onDestinationSelected: (idx) => setState(() => _currentNav = idx),
        height: 60,
        backgroundColor: context.cSurface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined, size: 20),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
            label: 'Marcaje',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined, size: 20),
            selectedIcon: Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined, size: 20),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded, size: 20, color: AppColors.primary),
            label: 'Gestión RRHH',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: 20),
            selectedIcon: Icon(Icons.person_rounded, size: 20, color: AppColors.primary),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
