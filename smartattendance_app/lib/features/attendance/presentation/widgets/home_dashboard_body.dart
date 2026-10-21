// lib/features/attendance/presentation/widgets/home_dashboard_body.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/attendance_entity.dart';
import 'day_summary_card.dart';
import 'home_header.dart';
import 'live_location_card.dart';

/// ============================================================================
/// COMPONENTE: HomeDashboardBody (Módulo de Marcaje y Jornada Personal)
/// ============================================================================
/// QUÉ HACE:
/// Estructura la experiencia del colaborador para registrar su jornada diaria:
/// 1. Cabecera con saludo, documento y reloj en tiempo real.
/// 2. Tarjeta de acción inteligente primaria calculada por [MarkSequence.next].
/// 3. Resumen y secuencia horaria de la jornada actual (Entrada, Almuerzo, Salida).
/// 4. Validación y geolocalización GPS en tiempo real.
/// 5. Acceso al módulo ejecutivo de RRHH para supervisores/administradores.
///
/// POR QUÉ:
/// Principio de Responsabilidad Única (SRP - SOLID):
/// Desacopla el marcaje individual de las métricas masivas de supervisión,
/// eliminando saturación visual y facilitando la ubicación inmediata de opciones.
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

  Widget _buildSmartPunchCard(BuildContext context) {
    final (label, icon, color) = switch (nextTipo) {
      'entrada' => ('REGISTRAR ENTRADA', Icons.login_rounded, AppColors.primary),
      'salida_almuerzo' => ('REGISTRAR INICIO DE ALMUERZO', Icons.restaurant_rounded, const Color(0xFFF59E0B)),
      'regreso_almuerzo' => ('REGISTRAR REGRESO DE ALMUERZO', Icons.work_history_rounded, const Color(0xFF10B981)),
      'salida' => ('REGISTRAR SALIDA', Icons.logout_rounded, const Color(0xFFEF4444)),
      _ => ('REGISTRAR ENTRADA', Icons.camera_alt_rounded, AppColors.primary),
    };

    return Container(
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRegisterAttendance,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'PRÓXIMA MARCACIÓN',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: color,
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: context.cTextPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Apertura facial biométrica instantánea',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.cTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminAccessBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel de Talento Humano',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Gestión de plantilla, jornadas y horas extras',
                  style: TextStyle(fontSize: 11.5, color: context.cTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onNavigateToAdmin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ver módulo', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

    final summary = DaySummaryCard(
      records: records,
      onMarkTap: onSelectMark,
    );

    final punchAction = _buildSmartPunchCard(context);

    return LayoutBuilder(builder: (context, size) {
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
                    if (onNavigateToAdmin != null) ...[
                      const SizedBox(height: 14),
                      _buildAdminAccessBanner(context),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }

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
            if (onNavigateToAdmin != null) ...[
              const SizedBox(height: 14),
              _buildAdminAccessBanner(context),
            ],
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }
}
