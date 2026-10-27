// ============================================================================
// ARCHIVO: home_dashboard_body.dart
// QUÉ HACE: Cuerpo principal de Inicio 100% limpio, transparente y no redundante.
// CÓMO FUNCIONA: Orquesta de forma directa, pequeña y transparente:
//                1. Logo Oficial 3D flotante interactivo (sin card ni cajas).
//                2. Encabezado institucional limpio con saludo al colaborador.
//                3. Los 4 botones pequeños y transparentes de marcación:
//                   Inicio, Salida Almuerzo, Regreso y Salida.
//                4. Barra de estado transparente con geocerca GPS y tiempo.
// POR QUÉ: Atiende la directiva: "DEPURA ESA CARD DEBE SER TRANSPARENTE TODO,
//          EL BOTON DE INICIO, SALIDA REGRESO A ALMORZAR Y SALIDA DEBE SER
//          PEQUEÑO, CORRIGE COMPONENTES NO DEBEN SER REDUNDANTES" (< 100 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../domain/entities/attendance_entity.dart';
import 'home_header.dart';
import 'serviciudad_3d_logo_hero.dart';
import 'serviciudad_hero_card.dart';
import 'serviciudad_status_grid.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Serviciudad3DLogoHero(height: 130),
          const SizedBox(height: 6),
          HomeHeader(
            user: user,
            onOpenDirectory: onOpenStaff ?? () => onSelectMark?.call(null),
          ),
          const SizedBox(height: 12),
          ServiciudadHeroCard(
            records: records,
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
          ),
        ],
      ),
    );
  }
}
