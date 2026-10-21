// lib/features/history/presentation/widgets/history_record_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../../../core/utils/time_format.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import 'history_detail_sheet.dart';

/// ============================================================================
/// COMPONENTE: HistoryRecordTile (Estilo iOS Glass)
/// ============================================================================
/// QUÉ HACE:
/// Tarjeta translúcida individual para cada evento de asistencia histórica.
/// Muestra tipo de marca, fecha, hora en cifras tabulares y ubicación GPS.
///
/// CÓMO FUNCIONA:
/// Envuelve el contenido en [IosGlassCard] con tap interactivo que abre
/// [HistoryDetailSheet] para inspección detallada.
///
/// POR QUÉ:
/// Principio de Responsabilidad Única (SRP) y Clean Architecture (< 200 líneas).
/// ============================================================================
class HistoryRecordTile extends StatelessWidget {
  const HistoryRecordTile({super.key, required this.record});
  final AttendanceEntity record;

  @override
  Widget build(BuildContext context) {
    final info = attendanceTypeInfo(record.tipo);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd/MM/yyyy').format(record.fecha.toLocal());
    final timeStr = formatTimeOfDay(context, record.hora.toLocal());

    return IosGlassCard(
      onTap: () => HistoryDetailSheet.show(context, record),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, color: info.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.cTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$dateStr · $timeStr',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                    fontFeatures: AppDesignTokens.tabularFigures,
                  ),
                ),
                if (record.direccion != null && record.direccion!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 11, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          record.direccion!,
                          style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              attendanceTypeShort(record.tipo).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: info.color,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
