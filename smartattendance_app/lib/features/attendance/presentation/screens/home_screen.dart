// ============================================================================
// ARCHIVO: home_screen.dart
// QUÉ HACE: Contenedor raíz de navegación estilo iOS 18 Liquid Glass con Modo
//           Oscuro 100% transparente profesional (`extendBody: true`, aurora
//           ambiental iOS y barra flotante con desenfoque `BackdropFilter`).
// CÓMO FUNCIONA:
// 1. Consulta la geocerca asignada a la cuadrilla del usuario autenticado, su
//    dirección física real y sus Horas Extras Asignadas (`assignedOvertimeMinutes`).
// 2. Sincroniza la telemetría GPS con `TraccarService` y renderiza un lienzo
//    ambiental iOS en modo oscuro para que los paneles de cristal refracten luz.
// POR QUÉ: Conecta geocerca, horas extras, Traccar y estética 100% iOS
//          transparente profesional (< 195 líneas).
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/location/traccar_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
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
  int _currentNav = 0, _assignedOvertimeMinutes = 0;
  double? _latitude, _longitude, _zoneLat, _zoneLng, _zoneRadius, _distance;
  String? _zoneName, _zoneAddress;
  bool _loadingLocation = true;
  bool? _insideZone;

  @override
  void initState() { super.initState(); _refreshLocation(); }

  Future<void> _refreshLocation() async {
    if (mounted) setState(() => _loadingLocation = true);
    try {
      final session = ref.read(sessionControllerProvider);
      final cedula = session is SessionAuthenticated ? session.user.cedula.trim() : '';
      final db = await ref.read(localPhotoDatabaseProvider).database;
      var rows = <Map<String, Object?>>[];
      if (cedula.isNotEmpty) {
        final wRows = await db.query('workers', columns: ['id', 'schedule_json'], where: 'document = ?', whereArgs: [cedula], limit: 1);
        if (wRows.isNotEmpty) {
          var sched = WorkSchedule.decode(wRows.first['schedule_json'] as String?);
          if (sched == null) {
            sched = const WorkSchedule(480, true, shiftName: 'Turno Operativo', startMinute: 480, endMinute: 1020, assignedOvertimeMinutes: 120);
            await db.update('workers', {'schedule_json': sched.encode()}, where: 'id = ?', whereArgs: [wRows.first['id']]);
          }
          _assignedOvertimeMinutes = sched.assignedOvertimeMinutes;
        }
        if (session is SessionAuthenticated && (session.user.fotoUrl == null || session.user.fotoUrl!.isEmpty)) {
          final pRows = await db.query('photo_marks', columns: ['local_path'], where: 'document = ?', whereArgs: [cedula], orderBy: 'captured_at DESC', limit: 1);
          final pPath = pRows.firstOrNull?['local_path'] as String?;
          if (pPath != null && pPath.isNotEmpty) {
            final u = session.user;
            await ref.read(sessionControllerProvider.notifier).authenticate(UserEntity(id: u.id, nombre: u.nombre, apellido: u.apellido, cedula: u.cedula, correo: u.correo, cargo: u.cargo, fotoUrl: pPath, isAdmin: u.isAdmin));
          }
        }
        rows = await db.rawQuery('SELECT z.* FROM workers w JOIN crews c ON c.id = w.crew_id JOIN work_zones z ON z.id = c.zone_id WHERE w.document = ? LIMIT 1', [cedula]);
      }
      if (rows.isEmpty) rows = await db.query('work_zones', orderBy: 'id ASC', limit: 1);
      if (rows.isNotEmpty) {
        final z = rows.first;
        _zoneName = (z['name'] ?? 'Geocerca Principal').toString();
        _zoneAddress = (z['address'] ?? 'Dosquebradas, Risaralda').toString();
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
      if (loc != null) const TraccarService().pushPosition(deviceId: cedula, latitude: loc.lat, longitude: loc.lng, zoneName: _zoneName);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _captureMark([String? requestedType]) async {
    try {
      final session = ref.read(sessionControllerProvider);
      final user = session is SessionAuthenticated ? session.user : null;
      final actor = ref.read(localActorProvider);
      var workers = await ref.read(localWorkersProvider.future).catchError((_) => <LocalWorker>[]);
      var target = (user != null) ? workers.where((w) => w.document.trim() == user.cedula.trim()).firstOrNull : null;
      if (target == null && user != null && RegExp(r'^\d{3,20}$').hasMatch(user.cedula.trim())) {
        await ref.read(localPhotoRepositoryProvider).addWorker(user.fullName, user.cedula.trim(), user.cargo);
        ref.invalidate(localWorkersProvider);
        workers = await ref.read(localWorkersProvider.future).catchError((_) => <LocalWorker>[]);
        target = workers.where((w) => w.document.trim() == user.cedula.trim()).firstOrNull;
      }
      target ??= actor.isAdmin ? workers.firstOrNull : null;
      if (target != null && (requestedType != null || !actor.isAdmin) && mounted) {
        await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => PhotoCaptureScreen(worker: target!, initialType: requestedType ?? 'entrada')));
        if (mounted) { ref.invalidate(localDayHistoryProvider); ref.invalidate(localWorkersProvider); await _refreshLocation(); }
        return;
      }
      if (actor.isAdmin && mounted) await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => LocalAttendanceHome(initialType: requestedType)));
    } catch (_) {}
    if (mounted) { ref.invalidate(localDayHistoryProvider); ref.invalidate(localWorkersProvider); await _refreshLocation(); }
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final sel = _currentNav == index;
    final activeColor = context.isDark ? AppColors.primaryDark : AppColors.primary;
    final color = sel ? activeColor : context.cTextSecondary;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () { setState(() => _currentNav = index); if (index == 0) _refreshLocation(); },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(sel ? activeIcon : icon, size: 21, color: color),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10.5, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: color, letterSpacing: -0.2)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;
    final isAdmin = ref.watch(localActorProvider).isAdmin;
    final records = ref.watch(localDayHistoryProvider).valueOrNull ?? const [];
    final navIdx = (!isAdmin && _currentNav == 1) ? 0 : _currentNav;
    final pages = [
      RefreshIndicator(
        onRefresh: () async { ref.invalidate(localDayHistoryProvider); await _refreshLocation(); },
        child: HomeDashboardBody(
          user: user, records: records, latitude: _latitude, longitude: _longitude, accuracy: 12.0,
          isLoadingLocation: _loadingLocation, isInsideZone: _insideZone, distanceMeters: _distance,
          zoneName: _zoneName, zoneLat: _zoneLat, zoneLng: _zoneLng, zoneRadius: _zoneRadius,
          assignedOvertimeMinutes: _assignedOvertimeMinutes, onRefreshLocation: _refreshLocation, onSelectMark: _captureMark,
        ),
      ),
      const AdminManagementScreen(),
      MapTabScreen(latitude: _latitude, longitude: _longitude, zoneLat: _zoneLat, zoneLng: _zoneLng, zoneRadius: _zoneRadius, zoneName: _zoneName, zoneAddress: _zoneAddress, userDocument: user?.cedula, onRefresh: _refreshLocation),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: context.cBackground,
      appBar: CorporateAppBar(user: user, currentNavIndex: navIdx, onProfileTap: () => setState(() => _currentNav = 3)),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.cGradientBackground),
        child: AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: KeyedSubtree(key: ValueKey<int>(navIdx), child: pages[navIdx])),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1728).withValues(alpha: 0.52) : context.cSurface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.20) : context.cBorder.withValues(alpha: 0.75), width: 0.9),
                ),
                child: Row(children: [
                  _navItem(0, CupertinoIcons.house, CupertinoIcons.house_fill, 'Inicio'),
                  if (isAdmin) _navItem(1, CupertinoIcons.doc_text, CupertinoIcons.doc_text_fill, 'Reportes'),
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
