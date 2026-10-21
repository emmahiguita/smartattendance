import 'package:flutter/material.dart';
import '../../domain/entities/attendance_entity.dart';
import 'dashboard_staff_status.dart';
import 'day_summary_card.dart';
import 'home_header.dart';
import 'live_location_card.dart';
import 'smart_punch_card.dart';

/// Organiza la portada móvil con una sola ruta de marcación y datos existentes.
/// El componente no crea empleados ni registros: delega esas acciones a sus
/// pantallas y proveedores locales para mantener responsabilidades claras.
class HomeDashboardBody extends StatelessWidget {
  const HomeDashboardBody({
    super.key,
    required this.user,
    required this.address,
    required this.coords,
    this.latitude,
    this.longitude,
    required this.hasFix,
    required this.isLoadingLocation,
    required this.onRefreshLocation,
    required this.records,
    this.nextTipo,
    this.registering = false,
    required this.onRegisterAttendance,
    this.onSelectMark,
    this.onOpenStaff,
  });

  final dynamic user;
  final String address, coords;
  final double? latitude, longitude;
  final bool hasFix, isLoadingLocation;
  // Parámetros conservados para consumidores previos; la marca ya se resuelve
  // en el directorio de cada trabajador, no en el resumen agregado del panel.
  final String? nextTipo;
  final bool registering;
  final VoidCallback onRefreshLocation, onRegisterAttendance;
  final ValueChanged<String>? onSelectMark;
  final VoidCallback? onOpenStaff;
  final List<AttendanceEntity> records;

  @override
  Widget build(BuildContext context) {
    final location = LiveLocationCard(
      address: address,
      coords: coords,
      latitude: latitude,
      longitude: longitude,
      hasFix: hasFix,
      isLoading: isLoadingLocation,
      onRefresh: onRefreshLocation,
    );
    final team = DashboardStaffStatus(
      onOpenAll: onOpenStaff ?? onRegisterAttendance,
    );
    // El resumen solo informa; la tarjeta superior es el único acceso de marcación.
    final journey = DaySummaryCard(records: records);
    final punch = SmartPunchCard(onTap: onRegisterAttendance);

    return LayoutBuilder(builder: (context, size) {
      // En horizontal/tablet se separa el flujo de marcación del estado del equipo.
      if (size.maxWidth >= 700) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: _column([
            HomeHeader(user: user),
            punch,
            journey,
          ])),
          Expanded(child: _column([team, location])),
        ]);
      }

      // En teléfono, todo queda en una lista vertical que se adapta a la altura.
      return SingleChildScrollView(
        key: const PageStorageKey('home-dashboard'),
        padding: EdgeInsets.zero,
        child: _column([
          HomeHeader(user: user),
          punch,
          team,
          journey,
          location,
        ]),
      );
    });
  }

  /// Mantiene separación constante entre tarjetas en móvil y pantalla ancha.
  Widget _column(List<Widget> children) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              children[i],
            ],
          ],
        ),
      );
}
