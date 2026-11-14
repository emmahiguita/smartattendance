// ============================================================================
// ARCHIVO: home_dashboard_body.dart
// QUÉ HACE: Cuerpo principal de Inicio con encabezado del usuario/administrador,
//           acciones de marcación, horario asignado y mapa en tiempo real.
// CÓMO FUNCIONA:
//   - PORTRAIT: encabezado -> divisor -> secciones operativas compactas.
//   - LANDSCAPE: identidad a la izquierda; operaciones a la derecha.
// POR QUÉ: Presentación limpia estilo iOS sin banners residuales debajo del
//          saludo para priorizar el registro de asistencia (< 175 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../domain/entities/attendance_entity.dart';
import 'home_header.dart';
import 'home_schedule_card.dart';
import 'home_visual_map_card.dart';
import 'serviciudad_hero_card.dart';
import 'serviciudad_status_grid.dart';

class HomeDashboardBody extends StatelessWidget {
  final dynamic user;
  final List<AttendanceEntity> records;
  final double? latitude,
      longitude,
      accuracy,
      distanceMeters,
      zoneLat,
      zoneLng,
      zoneRadius;
  final bool isLoadingLocation;
  final bool? isInsideZone, hasFix, registering;
  final String? zoneName, address, coords, nextTipo;
  final WorkSchedule? schedule;
  final int assignedOvertimeMinutes;
  final VoidCallback onRefreshLocation;
  final ValueChanged<String?>? onSelectMark;
  final VoidCallback? onRegisterAttendance, onOpenStaff;

  const HomeDashboardBody({
    super.key,
    required this.user,
    required this.records,
    required this.isLoadingLocation,
    required this.onRefreshLocation,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.onSelectMark,
    this.isInsideZone,
    this.distanceMeters,
    this.zoneName,
    this.zoneLat,
    this.zoneLng,
    this.zoneRadius,
    this.schedule,
    this.assignedOvertimeMinutes = 0,
    this.address,
    this.coords,
    this.hasFix,
    this.nextTipo,
    this.registering,
    this.onRegisterAttendance,
    this.onOpenStaff,
  });

  // QUÉ HACE: Construye las secciones operativas con divisores finos iOS (0.5px).
  Widget _cardsBlock(BuildContext context) {
    final div = Divider(height: 1, thickness: 0.5, color: context.cBorder);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ServiciudadHeroCard(
        records: records,
        assignedOvertimeMinutes: assignedOvertimeMinutes,
        onTap: (tipo) => onSelectMark?.call(tipo),
      ),
      div,
      HomeScheduleCard(
        schedule: schedule,
        assignedOvertimeMinutes: assignedOvertimeMinutes,
      ),
      div,
      ServiciudadStatusGrid(
        records: records,
        isInsideZone: isInsideZone,
        zoneName: zoneName,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        zoneLat: zoneLat,
        zoneLng: zoneLng,
        zoneRadius: zoneRadius,
        assignedOvertimeMinutes: assignedOvertimeMinutes,
      ),
      div,
      HomeVisualMapCard(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        zoneLat: zoneLat,
        zoneLng: zoneLng,
        zoneRadius: zoneRadius,
        zoneName: zoneName,
        isInsideZone: isInsideZone,
        distanceMeters: distanceMeters,
        onRefresh: onRefreshLocation,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) => OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          return SafeArea(
            top: true,
            bottom: false,
            child: isLandscape
                ? SingleChildScrollView(
                    key: const PageStorageKey('home-landscape'),
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 250,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: HomeHeader(
                                user: user,
                                onOpenDirectory: onOpenStaff ??
                                    () => onSelectMark?.call(null),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right: 14, top: 6, bottom: 12),
                              child: _cardsBlock(context),
                            ),
                          ),
                        ]),
                  )
                : SingleChildScrollView(
                    key: const PageStorageKey('home-clean-scroll'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HomeHeader(
                            user: user,
                            onOpenDirectory:
                                onOpenStaff ?? () => onSelectMark?.call(null),
                          ),
                          const SizedBox(height: 6),
                          Divider(
                              height: 1,
                              thickness: 0.5,
                              color: context.cBorder),
                          _cardsBlock(context),
                        ],
                      ),
                    ),
                  ),
          );
        },
      );
}
