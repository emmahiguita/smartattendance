// lib/features/attendance/presentation/widgets/day_summary_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../domain/entities/attendance_entity.dart';
import 'day_marks_grid.dart';

/// ============================================================================
/// COMPONENTE: DaySummaryCard (Estilo iOS Inset Grouped)
/// ============================================================================
/// QUÉ HACE:
/// Tarjeta consolidada del ciclo laboral diario del colaborador:
/// Entrada, Almuerzo, Regreso y Salida con horas laboradas en tiempo real.
///
/// CÓMO FUNCIONA:
/// Identifica la jornada actual en tiempo local de Colombia, mapea los 4 eventos
/// reales y delega la visualización táctil a [DayMarksGrid].
///
/// POR QUÉ:
/// Cumple con las directrices de UX: acceso instantáneo con tap directo,
/// cero horas extras artificiales (regla del administrador) y menos de 200 líneas.
/// ============================================================================
class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({
    super.key,
    required this.records,
    this.onMarkTap,
  });

  final List<AttendanceEntity> records;
  final ValueChanged<String>? onMarkTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDark = context.isDark;

    // 1. Filtrar registros del día actual
    final todayLocal = records.where((r) {
      final local = r.fecha.toLocal();
      return local.year == now.year && local.month == now.month && local.day == now.day;
    }).toList()..sort((a, b) => a.hora.compareTo(b.hora));

    var inicio = 0;
    for (var i = 0; i < todayLocal.length; i++) {
      if (todayLocal[i].tipo == 'entrada') inicio = i;
    }
    final jornadaActual = todayLocal.sublist(inicio);

    // 2. Extraer mapa de las 4 marcas fundamentales
    final marksMap = <String, AttendanceEntity?>{
      'entrada': null,
      'salida_almuerzo': null,
      'regreso_almuerzo': null,
      'salida': null,
    };

    for (final r in jornadaActual) {
      if (marksMap.containsKey(r.tipo)) {
        marksMap[r.tipo] = r;
      }
    }

    final mEntrada = marksMap['entrada'];
    final mSalida = marksMap['salida'];
    final ultima = jornadaActual.isNotEmpty ? jornadaActual.last : null;
    final completada = mEntrada != null && mSalida != null;

    final String estadoTitulo;
    final Color estadoColor;

    if (completada) {
      estadoTitulo = 'Jornada cerrada';
      estadoColor = AppColors.systemBlue;
    } else if (ultima != null) {
      final info = attendanceTypeInfo(ultima.tipo);
      estadoTitulo = 'Activa · ${attendanceTypeShort(ultima.tipo)}';
      estadoColor = info.color;
    } else {
      estadoTitulo = 'Sin registrar hoy';
      estadoColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);
    }

    final workedLabel = calculateWorkedHoursLabel(todayLocal);

    return IosGlassCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Jornada de Hoy',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        estadoTitulo,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: estadoColor),
                      ),
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            thickness: 0.5,
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
          ),
          const SizedBox(height: 12),
          DayMarksGrid(marks: marksMap, onMarkTap: onMarkTap),
          if (todayLocal.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Tiempo Laborado Hoy: ',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    workedLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.cTextPrimary,
                      fontFeatures: AppDesignTokens.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    },
  ),
);
  }
}
