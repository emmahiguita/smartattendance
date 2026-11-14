// ============================================================================
// ARCHIVO: home_screen.dart
// QUÉ HACE: Organiza navegación y operaciones de inicio con superficie plana.
// CÓMO: Reserva el espacio de navegación y muestra la asignación real del usuario.
// POR QUÉ: Evita superposiciones y datos de horarios o personas inventadas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../../photo_attendance/presentation/local_day_history.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../widgets/corporate_app_bar.dart';
import '../widgets/home_dashboard_body.dart';
import '../widgets/home_navigation_bar.dart';
import '../widgets/home_location_snapshot.dart';
import '../widgets/home_mark_launcher.dart';
import 'admin_management_screen.dart';
import 'map_tab_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNav = 0, _assignedOvertimeMinutes = 0;
  WorkSchedule? _schedule;
  double? _latitude, _longitude, _zoneLat, _zoneLng, _zoneRadius, _distance;
  String? _zoneName, _zoneAddress;
  bool _loadingLocation = true, _insideZone = false;

  @override
  void initState() {
    super.initState();
    _refreshLocation();
  }

  // QUÉ HACE: Actualiza coordenadas GPS y evalúa pertenencia a la geocerca.
  // CÓMO: Lee la zona del trabajador en SQLite, captura posición y calcula distancia euclidiana.
  // POR QUÉ: Garantiza validación de asistencia geolocalizada en tiempo real sin simulación.
  Future<void> _refreshLocation() async {
    if (mounted) setState(() => _loadingLocation = true);
    try {
      final session = ref.read(sessionControllerProvider);
      final cedula =
          session is SessionAuthenticated ? session.user.cedula.trim() : '';
      final db = await ref.read(localPhotoDatabaseProvider).database;
      final data = await HomeLocationSnapshot.capture(db, cedula);
      if (!mounted) return;
      setState(() {
        _latitude = data.latitude;
        _longitude = data.longitude;
        _zoneLat = data.zoneLat;
        _zoneLng = data.zoneLng;
        _zoneRadius = data.radius;
        _zoneName = data.name;
        _zoneAddress = data.address;
        _distance = data.distance;
        _insideZone = data.inside;
        _schedule = data.schedule;
        _assignedOvertimeMinutes = data.schedule?.assignedOvertimeMinutes ?? 0;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  // QUÉ HACE: Abre el flujo fotográfico biométrico o administrativo según el rol del usuario.
  // CÓMO: Resuelve el trabajador autenticado en BD y navega a PhotoCaptureScreen.
  // POR QUÉ: Desacopla la lógica de captura fotográfica manteniendo Clean Architecture.
  Future<void> _captureMark([String? requestedType]) async {
    await launchHomeMark(context, ref, requestedType);
    if (mounted) {
      ref.invalidate(localDayHistoryProvider);
      ref.invalidate(localWorkersProvider);
      await _refreshLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;
    final isAdmin = ref.watch(localActorProvider).isAdmin;
    final records = ref.watch(localDayHistoryProvider).valueOrNull ?? const [];
    final navIdx = (!isAdmin && _currentNav == 1) ? 0 : _currentNav;
    final pages = [
      RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(localDayHistoryProvider);
          await _refreshLocation();
        },
        child: SizedBox.expand(
          child: HomeDashboardBody(
            user: user,
            records: records,
            latitude: _latitude,
            longitude: _longitude,
            isLoadingLocation: _loadingLocation,
            isInsideZone: _insideZone,
            distanceMeters: _distance,
            zoneName: _zoneName,
            zoneLat: _zoneLat,
            zoneLng: _zoneLng,
            zoneRadius: _zoneRadius,
            schedule: _schedule,
            assignedOvertimeMinutes: _assignedOvertimeMinutes,
            onRefreshLocation: _refreshLocation,
            onSelectMark: _captureMark,
          ),
        ),
      ),
      const AdminManagementScreen(),
      MapTabScreen(
          latitude: _latitude,
          longitude: _longitude,
          zoneLat: _zoneLat,
          zoneLng: _zoneLng,
          zoneRadius: _zoneRadius,
          zoneName: _zoneName,
          zoneAddress: _zoneAddress,
          userDocument: user?.cedula,
          onRefresh: _refreshLocation),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: false,
      extendBodyBehindAppBar: false,
      backgroundColor: context.isDark ? Colors.black : Colors.white,
      appBar: (navIdx == 0)
          ? null
          : CorporateAppBar(
              user: user,
              currentNavIndex: navIdx,
              onProfileTap: () => setState(() => _currentNav = 3)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            layoutBuilder: (child, prev) => Stack(
                alignment: Alignment.topCenter,
                fit: StackFit.expand,
                children: [...prev, if (child != null) child]),
            child: KeyedSubtree(
                key: ValueKey<int>(navIdx),
                child: SizedBox.expand(child: pages[navIdx])),
          ),
        ],
      ),
      bottomNavigationBar: HomeNavigationBar(
        currentNav: _currentNav,
        isAdmin: isAdmin,
        onNavChanged: (idx) {
          setState(() => _currentNav = idx);
          if (idx == 0) _refreshLocation();
        },
      ),
    );
  }
}
