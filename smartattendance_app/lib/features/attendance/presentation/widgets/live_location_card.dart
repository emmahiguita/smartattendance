// lib/features/attendance/presentation/widgets/live_location_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import 'realtime_map_viewer.dart';

/// ============================================================================
/// COMPONENTE: LiveLocationCard (Estilo iOS Glass)
/// ============================================================================
/// QUÉ HACE:
/// Muestra la última posición geográfica capturada por el sensor GPS y el visor
/// cartográfico en tiempo real para verificar presencia en sede autorizada.
///
/// CÓMO FUNCIONA:
/// Valida si el sensor obtuvo coordenadas fijas ([hasFix]). Presenta dirección,
/// latitud/longitud en cifras tabulares y un mapa satelital/vectorial integrado.
///
/// POR QUÉ:
/// Principio de Transparencia y Geocercas: permite al colaborador confirmar que
/// su registro se encuentra dentro del perímetro permitido sin textos redundantes.
/// ============================================================================
class LiveLocationCard extends StatelessWidget {
  final String address;
  final String coords;
  final double? latitude;
  final double? longitude;
  final bool hasFix;
  final bool isLoading;
  final VoidCallback onRefresh;

  const LiveLocationCard({
    super.key,
    required this.address,
    required this.coords,
    this.latitude,
    this.longitude,
    required this.hasFix,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return IosGlassCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Título, estado y refresco
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Ubicación GPS',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: context.cTextPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: (hasFix ? AppColors.systemGreen : AppColors.systemOrange)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hasFix ? 'GPS Activo' : 'Sin señal',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: hasFix ? AppColors.systemGreen : AppColors.systemOrange,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          iconSize: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                                ),
                          onPressed: isLoading ? null : onRefresh,
                          tooltip: 'Refrescar posición',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                thickness: 0.5,
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              ),
          const SizedBox(height: 10),

          // Dirección física legible
          Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.cTextPrimary,
            ),
          ),
          const SizedBox(height: 2),

          // Coordenadas en cifras tabulares
          Text(
            coords,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
              fontFeatures: AppDesignTokens.tabularFigures,
            ),
          ),
          const SizedBox(height: 10),

          // Visor de mapa interactivo y animado
          RealtimeMapViewer(
            latitude: latitude,
            longitude: longitude,
            hasFix: hasFix,
            address: address,
            height: 215.0,
          ),
        ],
      );
    }),
    );
  }
}
