// lib/features/attendance/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../photo_attendance/presentation/local_day_history.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/local_attendance_home.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../widgets/corporate_app_bar.dart';
import '../widgets/home_dashboard_body.dart';
import 'admin_management_screen.dart';

/// ============================================================================
/// PANTALLA PRINCIPAL: navegación de asistencia móvil
/// ============================================================================
/// La portada muestra jornada, equipo y ubicación. Una marcación abre el
/// directorio SQLite para que el operador elija una persona ya registrada;
/// su siguiente tipo de marca se resuelve desde el historial local.
/// Los datos de pantalla no aprovisionan trabajadores ni marcas por defecto.
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
      _address = loc?.dir ??
          (loc == null ? 'Ubicación no disponible' : 'Posición GPS obtenida');
      _coords = loc == null
          ? 'Toca refrescar'
          : '${loc.lat.toStringAsFixed(4)}°, ${loc.lng.toStringAsFixed(4)}°';
    });
  }

  Future<void> _capture() async {
    try {
      if (!mounted) return;
      // El supervisor elige a una persona real; su secuencia define la próxima marca.
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => const LocalAttendanceHome(),
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
          onRegisterAttendance: () => _capture(),
          onOpenStaff: () => setState(() => _currentNav = 2),
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
            icon: Icon(Icons.home_outlined, size: 20),
            selectedIcon:
                Icon(Icons.home_rounded, size: 20, color: AppColors.primary),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined, size: 20),
            selectedIcon: Icon(Icons.calendar_today_rounded,
                size: 20, color: AppColors.primary),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined, size: 20),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded,
                size: 20, color: AppColors.primary),
            label: 'Gestión RRHH',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: 20),
            selectedIcon:
                Icon(Icons.person_rounded, size: 20, color: AppColors.primary),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
