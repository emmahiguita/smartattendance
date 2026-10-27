// ============================================================================
// ARCHIVO: live_location_card.dart
// QUÉ HACE: Tarjeta de telemetría geoespacial en tiempo real con Frosted Glass
//           iOS, visor cartográfico interactivo, geocerca Serviciudad y métricas GPS.
// CÓMO FUNCIONA: Muestra coordenadas reales, precisión GNSS, distancia al centro
//                de la geocerca autorizada y visor `RealtimeMapViewer`.
// POR QUÉ: Satisface la especificación de telemetría profesional (< 185 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'realtime_map_viewer.dart';

class LiveLocationCard extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final bool isLoading;
  final bool? isInsideZone;
  final double? distanceMeters;
  final String? zoneName;
  final double? zoneLat;
  final double? zoneLng;
  final double? zoneRadius;
  final VoidCallback onRefresh;

  const LiveLocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.isLoading,
    required this.onRefresh,
    this.isInsideZone,
    this.distanceMeters,
    this.zoneName,
    this.zoneLat,
    this.zoneLng,
    this.zoneRadius,
  });

  Widget _buildMetric(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.cSurface.withValues(alpha: context.isDark ? 0.45 : 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.cBorder.withValues(alpha: 0.5), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 9.5, color: context.cTextSecondary, fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.cTextPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFix = latitude != null && longitude != null;
    final dotColor = !hasFix ? AppColors.titanium : (isInsideZone == false ? AppColors.error : AppColors.success);
    final statusLabel = !hasFix
        ? (isLoading ? 'Localizando…' : 'Sin señal GNSS')
        : (isInsideZone == null ? 'GPS Activo' : (isInsideZone! ? 'En zona autorizada' : 'Fuera de zona'));

    final badgeBg = !hasFix
        ? context.cSurface.withValues(alpha: 0.6)
        : (isInsideZone == true ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12));
    final badgeBorder = !hasFix
        ? context.cBorder.withValues(alpha: 0.5)
        : (isInsideZone == true ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3));

    return IosGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: const Icon(CupertinoIcons.location_north_fill, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zoneName != null ? 'Geocerca · $zoneName' : 'Ubicación GNSS · Serviciudad',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.cTextPrimary, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      hasFix ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}' : 'Esperando telemetría GNSS/GPS real',
                      style: TextStyle(fontSize: 11, color: context.cTextSecondary, fontFeatures: AppDesignTokens.tabularFigures),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: badgeBorder, width: 0.8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isInsideZone == true ? AppColors.success : context.cTextPrimary)),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                onPressed: isLoading ? null : onRefresh,
                visualDensity: VisualDensity.compact,
                tooltip: 'Actualizar GPS',
                icon: isLoading
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.8))
                    : Icon(CupertinoIcons.arrow_clockwise, size: 16, color: context.cTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RealtimeMapViewer(
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            hasFix: hasFix,
            isLoading: isLoading,
            zoneLat: zoneLat,
            zoneLng: zoneLng,
            zoneRadius: zoneRadius,
            zoneName: zoneName,
            onRetry: onRefresh,
          ),
          if (hasFix) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildMetric(context, icon: CupertinoIcons.scope, label: 'Precisión', value: accuracy != null ? '±${accuracy!.toStringAsFixed(0)} m' : 'Alta'),
                if (zoneRadius != null)
                  _buildMetric(context, icon: CupertinoIcons.circle, label: 'Radio geocerca', value: '${zoneRadius!.toStringAsFixed(0)} m'),
                if (distanceMeters != null)
                  _buildMetric(context, icon: CupertinoIcons.compass, label: 'Dist. centro', value: '${distanceMeters!.toStringAsFixed(0)} m'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
