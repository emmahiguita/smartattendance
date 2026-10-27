// lib/features/history/presentation/widgets/history_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../../../core/utils/time_format.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';

/// ============================================================================
/// COMPONENTE: HistoryDetailSheet (Estilo iOS Glass Bottom Sheet)
/// ============================================================================
/// QUÉ HACE:
/// Muestra los detalles de una marcación histórica: tipo de registro, fecha,
/// hora exacta, dirección y coordenadas GPS fijadas.
///
/// CÓMO FUNCIONA:
/// Se despliega mediante [showModalBottomSheet] con fondo difuminado y tarjetas
/// translúcidas de cristal esmerilado sin solapamientos visuales.
///
/// POR QUÉ:
/// Principio de Responsabilidad Única (SRP) en menos de 200 líneas de código.
/// ============================================================================
class HistoryDetailSheet extends StatelessWidget {
  const HistoryDetailSheet({super.key, required this.record});
  final AttendanceEntity record;

  static Future<void> show(BuildContext context, AttendanceEntity record) {
    return showIosFloatingGlassSheet<void>(
      context: context,
      title: 'Detalle de Marcación',
      subtitle: attendanceTypeInfo(record.tipo).label,
      child: SingleChildScrollView(
        child: HistoryDetailSheet(record: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = attendanceTypeInfo(record.tipo);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd/MM/yyyy').format(record.fecha.toLocal());
    final timeStr = formatTimeOfDay(context, record.hora.toLocal());

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(info.icon, color: info.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.label,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.cTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Registro verificado en SQLite',
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: IosGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70))),
                      const SizedBox(height: 2),
                      Text(dateStr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.cTextPrimary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: IosGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hora', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70))),
                      const SizedBox(height: 2),
                      Text(timeStr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.cTextPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (record.direccion != null || record.latitud != null) ...[
            const SizedBox(height: 12),
            IosGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.systemRed),
                      const SizedBox(width: 4),
                      Text(
                        'Ubicación física',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                      ),
                    ],
                  ),
                  if (record.direccion != null && record.direccion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(record.direccion!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.cTextPrimary)),
                  ],
                  if (record.latitud != null && record.longitud != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${record.latitud!.toStringAsFixed(5)}°, ${record.longitud!.toStringAsFixed(5)}°',
                      style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 44,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                foregroundColor: context.cTextPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
