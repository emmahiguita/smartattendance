// lib/features/attendance/presentation/widgets/home_dashboard_body.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/buen_tiempo_pop_banner.dart';
import '../../domain/entities/attendance_entity.dart';
import 'admin_access_banner.dart';
import 'day_summary_card.dart';
import 'home_header.dart';
import 'live_location_card.dart';
import 'smart_punch_card.dart';

/// ============================================================================
/// COMPONENTE: HomeDashboardBody (Módulo de Marcaje y Jornada Personal)
/// ============================================================================
/// QUÉ HACE:
/// Estructura la experiencia del colaborador para registrar su jornada diaria:
/// 1. Cabecera con saludo, documento y reloj en tiempo real.
/// 2. Tarjeta de acción inteligente primaria calculada por [MarkSequence.next].
/// 3. Resumen y secuencia horaria de la jornada actual (Entrada, Almuerzo, Salida).
/// 4. Validación y geolocalización GPS en tiempo real.
/// 5. Banner publicitario y de garantías de la app "BuenTiempo".
/// 6. Acceso al módulo ejecutivo de RRHH para supervisores/administradores.
///
/// CÓMO FUNCIONA:
/// Adapta el flujo mediante [LayoutBuilder] respondiendo a pantallas anchas
/// (tablets / foldables) o pantallas móviles estándar en modo vertical.
///
/// POR QUÉ:
/// Principio de Responsabilidad Única (SRP - SOLID):
/// Actúa como orquestador de alto nivel de los módulos de presentación,
/// delegando el renderizado a subcomponentes aislados de menos de 150 líneas.
/// ============================================================================
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
    required this.nextTipo,
    required this.registering,
    required this.onRegisterAttendance,
    required this.onSelectMark,
    this.onNavigateToAdmin,
  });

  final dynamic user;
  final String address, coords, nextTipo;
  final double? latitude, longitude;
  final bool hasFix, isLoadingLocation, registering;
  final VoidCallback onRefreshLocation, onRegisterAttendance;
  final ValueChanged<String> onSelectMark;
  final List<AttendanceEntity> records;
  final VoidCallback? onNavigateToAdmin;

  @override
  Widget build(BuildContext context) {
    // Componentes modulares reutilizables y livianos
    final location = LiveLocationCard(
      address: address,
      coords: coords,
      latitude: latitude,
      longitude: longitude,
      hasFix: hasFix,
      isLoading: isLoadingLocation,
      onRefresh: onRefreshLocation,
    );

    final summary = DaySummaryCard(
      records: records,
      onMarkTap: onSelectMark,
    );

    final punchAction = SmartPunchCard(
      nextTipo: nextTipo,
      onTap: onRegisterAttendance,
    );

    const popBanner = BuenTiempoPopBanner();

    return LayoutBuilder(builder: (context, size) {
      // 1. Pantalla Ancha (Tablets / Dispositivos Plegables)
      if (size.maxWidth >= 700) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                key: const PageStorageKey('home-location-wide'),
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeHeader(user: user, onRegisterTap: onRegisterAttendance),
                    const SizedBox(height: 14),
                    punchAction,
                    const SizedBox(height: 14),
                    summary,
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                key: const PageStorageKey('home-actions-wide'),
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    location,
                    const SizedBox(height: 14),
                    popBanner,
                    if (onNavigateToAdmin != null) ...[
                      const SizedBox(height: 14),
                      AdminAccessBanner(onNavigateToAdmin: onNavigateToAdmin!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }

      // 2. Pantalla Móvil Estándar (Smartphones en Vertical)
      return SingleChildScrollView(
        key: const PageStorageKey('home-portrait'),
        padding: const EdgeInsets.all(AppDesignTokens.mobileHorizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(user: user, onRegisterTap: onRegisterAttendance),
            const SizedBox(height: 14),
            punchAction,
            const SizedBox(height: 14),
            summary,
            const SizedBox(height: 14),
            location,
            const SizedBox(height: 14),
            popBanner,
            if (onNavigateToAdmin != null) ...[
              const SizedBox(height: 14),
              AdminAccessBanner(onNavigateToAdmin: onNavigateToAdmin!),
            ],
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }
}
