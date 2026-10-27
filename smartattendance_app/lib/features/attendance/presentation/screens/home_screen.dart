// ============================================================================
// ARCHIVO: home_screen.dart
// QUÉ HACE: Contenedor raíz de navegación estilo iOS 18 (Inicio, Historial,
//           Gestión RRHH, Perfil) con barra inferior flotante translúcida y
//           orquestación de GPS + marcación directa.
// CÓMO FUNCIONA:
// 1. Consulta la posición GPS real mediante `LocationService` y la geocerca
//    activa en SQLite (`work_zones`), calculando distancia Haversine.
// 2. Renderiza una barra de navegación flotante estilo iOS (`CupertinoIcons`)
//    con `BackdropFilter` y bordes redondeados continuos.
// POR QUÉ: Cumple estética 100% iOS con menús flotantes limpios (< 180 líneas).
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/presentation/local_attendance_home.dart';
import '../../../photo_attendance/presentation/local_day_history.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/photo_capture_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../widgets/corporate_app_bar.dart';
import '../widgets/home_dashboard_body.dart';
import 'admin_management_screen.dart';
import 'map_tab_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNav = 0;
  double? _latitude, _longitude, _zoneLat, _zoneLng, _zoneRadius, _distance;
  String? _zoneName;
  bool _loadingLocation = true;
  bool? _insideZone;

  @override
  void initState() {
    super.initState();
    _refreshLocation();
  }

  Future<void> _refreshLocation() async {
    if (mounted) setState(() => _loadingLocation = true);
    try {
      final db = await ref.read(localPhotoDatabaseProvider).database;
      final rows = await db.query('work_zones', orderBy: 'id ASC', limit: 1);
      if (rows.isNotEmpty) {
        final z = rows.first;
        _zoneName = (z['name'] ?? 'Geocerca Principal').toString();
        _zoneLat = (z['latitude'] as num).toDouble();
        _zoneLng = (z['longitude'] as num).toDouble();
        _zoneRadius = (z['radius_m'] as num).toDouble();
      }
      final loc = await const LocationService().capture();
      if (!mounted) return;
      setState(() {
        _latitude = loc?.lat;
        _longitude = loc?.lng;
        if (loc != null && _zoneLat != null && _zoneLng != null && _zoneRadius != null) {
          _distance = const Distance().as(LengthUnit.Meter, LatLng(loc.lat, loc.lng), LatLng(_zoneLat!, _zoneLng!));
          _insideZone = _distance! <= _zoneRadius!;
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _captureMark([String? requestedType]) async {
    try {
      if (requestedType != null) {
        final workers = await ref.read(localWorkersProvider.future).catchError((_) => <LocalWorker>[]);
        final session = ref.read(sessionControllerProvider);
        final user = session is SessionAuthenticated ? session.user : null;
        final target = (user != null && workers.isNotEmpty)
            ? workers.where((w) => w.document.trim() == user.cedula.trim() || w.name.toLowerCase() == user.fullName.toLowerCase()).firstOrNull
            : workers.firstOrNull;
        if (target != null && mounted) {
          await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => PhotoCaptureScreen(worker: target, initialType: requestedType)));
          if (mounted) { ref.invalidate(localDayHistoryProvider); ref.invalidate(localWorkersProvider); }
          return;
        }
      }
      if (mounted) await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => LocalAttendanceHome(initialType: requestedType)));
    } catch (e) {
      debugPrint('Error en captura de asistencia: $e');
    }
    if (mounted) { ref.invalidate(localDayHistoryProvider); ref.invalidate(localWorkersProvider); }
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final sel = _currentNav == index;
    final color = sel ? AppColors.primary : context.cTextSecondary;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentNav = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(sel ? activeIcon : icon, size: 21, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;
    final records = ref.watch(localDayHistoryProvider).valueOrNull ?? const [];
    final pages = [
      RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(localDayHistoryProvider);
          await _refreshLocation();
        },
        child: HomeDashboardBody(
          user: user,
          records: records,
          latitude: _latitude,
          longitude: _longitude,
          accuracy: 12.0,
          isLoadingLocation: _loadingLocation,
          isInsideZone: _insideZone,
          distanceMeters: _distance,
          zoneName: _zoneName,
          zoneLat: _zoneLat,
          zoneLng: _zoneLng,
          zoneRadius: _zoneRadius,
          onRefreshLocation: _refreshLocation,
          onSelectMark: _captureMark,
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
        onRefresh: _refreshLocation,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: CorporateAppBar(user: user, currentNavIndex: _currentNav, onProfileTap: () => setState(() => _currentNav = 3)),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: KeyedSubtree(key: ValueKey<int>(_currentNav), child: pages[_currentNav])),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: context.cSurface.withValues(alpha: context.isDark ? 0.72 : 0.85),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: context.cBorder.withValues(alpha: context.isDark ? 0.55 : 0.75),
                    width: 0.8,
                  ),
                ),
                child: Row(children: [
                  _navItem(0, CupertinoIcons.house, CupertinoIcons.house_fill, 'Inicio'),
                  _navItem(1, CupertinoIcons.doc_text, CupertinoIcons.doc_text_fill, 'Reportes'),
                  _navItem(2, CupertinoIcons.map, CupertinoIcons.map_fill, 'Mapa'),
                  _navItem(3, CupertinoIcons.person, CupertinoIcons.person_fill, 'Perfil'),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
