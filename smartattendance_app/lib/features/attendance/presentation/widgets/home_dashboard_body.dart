// ============================================================================
// ARCHIVO: home_dashboard_body.dart
// QUÉ HACE: Cuerpo principal de Inicio adaptativo (Móvil iOS/Android y
//           Escritorio Windows/macOS/Linux) con olas azules vectoriales 3D.
// CÓMO FUNCIONA:
// 1. En móvil (`maxWidth < 820`) conserva intacto el diseño vertical iOS/Android.
// 2. En escritorio (`maxWidth >= 820`) centra un contenedor ejecutivo de 1060px
//    en 2 columnas (tarjetas de asistencia + horario/estado a la izquierda, y
//    visor cartográfico 3D ampliado a la derecha) sin deformar componentes.
// 3. Mantiene `RoyalBlueBottomWavePainter` anclado en `bottom: 0`.
// POR QUÉ: Adapta la versión de escritorio sin dañar el diseño móvil (< 195 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../domain/entities/attendance_entity.dart';
import 'home_header.dart';
import 'home_schedule_card.dart';
import 'home_visual_map_card.dart';
import 'royal_blue_wave_painter.dart';
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

  Widget _leftAttendanceColumn(BuildContext context, Widget div) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            'Registrar asistencia',
            style: TextStyle(
              fontSize: 16.0,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        ServiciudadHeroCard(
          records: records,
          assignedOvertimeMinutes: assignedOvertimeMinutes,
          onTap: (tipo) => onSelectMark?.call(tipo),
        ),
        const SizedBox(height: 8),
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
      ],
    );
  }

  Widget _mapWidget({double mapHeight = 116.0}) => HomeVisualMapCard(
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
        mapHeight: mapHeight,
      );

  Widget _cardsBlock(BuildContext context, {required bool isDesktop}) {
    final isDark = context.isDark;
    final div = Divider(
      height: 1,
      thickness: 0.6,
      color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
    );
    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _leftAttendanceColumn(context, div),
          div,
          _mapWidget(mapHeight: 116.0),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 11, child: _leftAttendanceColumn(context, div)),
        const SizedBox(width: 26),
        Expanded(flex: 10, child: _mapWidget(mapHeight: 218.0)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 820;
          final pad = MediaQuery.paddingOf(context);
          final topBarOffset = pad.top + 48;
          final bottomWaveHeight = pad.bottom + 72;
          final waveHeight = topBarOffset + (isDesktop ? 68 : 64);

          return ColoredBox(
            color: context.isDark ? const Color(0xFF060E1C) : Colors.white,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SingleChildScrollView(
                  key: PageStorageKey(
                      isDesktop ? 'home-desktop' : 'home-clean-scroll'),
                  physics: const ClampingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: waveHeight + 24,
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter:
                                  RoyalBlueWavePainter(waveHeight: waveHeight),
                            ),
                          ),
                        ),
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 1060 : double.infinity,
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: topBarOffset,
                                left: isDesktop ? 24 : 16,
                                right: isDesktop ? 24 : 16,
                                bottom: bottomWaveHeight + 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  HomeHeader(
                                    user: user,
                                    onOpenDirectory: onOpenStaff ??
                                        () => onSelectMark?.call(null),
                                  ),
                                  SizedBox(height: isDesktop ? 28 : 22),
                                  _cardsBlock(context, isDesktop: isDesktop),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: bottomWaveHeight,
                  child: const IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: RoyalBlueBottomWavePainter(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
