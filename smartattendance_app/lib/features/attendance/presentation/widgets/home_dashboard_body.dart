// ============================================================================
// ARCHIVO: home_dashboard_body.dart
// QUÉ HACE: Cuerpo principal de Inicio con el carrusel institucional superior
//           SIN CARD (`ServiciudadTopIosBanner`), seguido del texto de Misión
//           y Visión, saludo al colaborador, los 4 botones compactos de
//           marcación con Marcador de Horas Extras Asignadas y el estado GPS.
// CÓMO FUNCIONA: Renderiza `ServiciudadTopIosBanner` de borde a borde en la
//                parte superior y propaga `assignedOvertimeMinutes` a las tarjetas.
// POR QUÉ: Cumple Clean Architecture y el límite estricto de < 120 líneas.
// ============================================================================

import 'package:flutter/material.dart';
import '../../domain/entities/attendance_entity.dart';
import 'home_header.dart';
import 'serviciudad_hero_card.dart';
import 'serviciudad_status_grid.dart';
import 'serviciudad_top_ios_banner.dart';

class HomeDashboardBody extends StatelessWidget {
  final dynamic user;
  final List<AttendanceEntity> records;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final bool isLoadingLocation;
  final bool? isInsideZone;
  final double? distanceMeters;
  final String? zoneName;
  final double? zoneLat;
  final double? zoneLng;
  final double? zoneRadius;
  final int assignedOvertimeMinutes;
  final VoidCallback onRefreshLocation;
  final ValueChanged<String?>? onSelectMark;

  // Parámetros de compatibilidad
  final String? address;
  final String? coords;
  final bool? hasFix;
  final String? nextTipo;
  final bool? registering;
  final VoidCallback? onRegisterAttendance;
  final VoidCallback? onOpenStaff;

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
    this.assignedOvertimeMinutes = 0,
    this.address,
    this.coords,
    this.hasFix,
    this.nextTipo,
    this.registering,
    this.onRegisterAttendance,
    this.onOpenStaff,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('home-clean-scroll'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ServiciudadTopIosBanner(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                HomeHeader(
                  user: user,
                  onOpenDirectory: onOpenStaff ?? () => onSelectMark?.call(null),
                ),
                const SizedBox(height: 12),
                ServiciudadHeroCard(
                  records: records,
                  assignedOvertimeMinutes: assignedOvertimeMinutes,
                  onTap: (tipo) => onSelectMark?.call(tipo),
                ),
                const SizedBox(height: 10),
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
            ),
          ),
        ],
      ),
    );
  }
}
