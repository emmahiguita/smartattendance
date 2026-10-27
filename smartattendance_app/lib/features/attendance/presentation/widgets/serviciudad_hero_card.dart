// ============================================================================
// ARCHIVO: serviciudad_hero_card.dart
// QUÉ HACE: Panel transparente con los 4 botones pequeños de marcación:
//           1. Inicio (Entrada), 2. Salida Almuerzo, 3. Regreso, 4. Salida.
// CÓMO FUNCIONA: Muestra cada botón pequeño, transparente, con su estado real:
//                hora registrada, activo para el siguiente turno o pendiente.
// POR QUÉ: Atiende la directiva: "DEPURA ESA CARD DEBE SER TRANSPARENTE TODO,
//          EL BOTON DE INICIO, SALIDA REGRESO A ALMORZAR Y SALIDA DEBE SER
//          PEQUEÑO, CORRIGE COMPONENTES NO DEBEN SER REDUNDANTES" (< 155 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/mark_sequence.dart';
import '../../domain/entities/attendance_entity.dart';

class ServiciudadHeroCard extends StatelessWidget {
  const ServiciudadHeroCard({super.key, required this.records, required this.onTap});

  final List<AttendanceEntity> records;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = records.where((r) {
      final l = r.fecha.toLocal();
      return l.year == now.year && l.month == now.month && l.day == now.day;
    }).toList()..sort((a, b) => a.hora.compareTo(b.hora));

    final lastMark = today.isNotEmpty ? today.last.tipo.toLowerCase() : '';
    final nextTipo = MarkSequence.next(lastMark);

    final entrada = today.where((r) => r.tipo.toLowerCase() == 'entrada').firstOrNull;
    final salidaAlm = today.where((r) => r.tipo.toLowerCase() == 'salida_almuerzo').firstOrNull;
    final regresoAlm = today.where((r) => r.tipo.toLowerCase() == 'regreso_almuerzo').firstOrNull;
    final salida = today.where((r) => r.tipo.toLowerCase() == 'salida').firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSmallButton(
                context: context,
                tipo: 'entrada',
                title: 'Inicio',
                icon: CupertinoIcons.arrow_down_right_circle,
                record: entrada,
                isActive: nextTipo == 'entrada',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallButton(
                context: context,
                tipo: 'salida_almuerzo',
                title: 'Salida Almuerzo',
                icon: CupertinoIcons.pause_circle,
                record: salidaAlm,
                isActive: nextTipo == 'salida_almuerzo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSmallButton(
                context: context,
                tipo: 'regreso_almuerzo',
                title: 'Regreso Almuerzo',
                icon: CupertinoIcons.play_circle,
                record: regresoAlm,
                isActive: nextTipo == 'regreso_almuerzo',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallButton(
                context: context,
                tipo: 'salida',
                title: 'Salida',
                icon: CupertinoIcons.arrow_up_right_circle,
                record: salida,
                isActive: nextTipo == 'salida',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallButton({
    required BuildContext context,
    required String tipo,
    required String title,
    required IconData icon,
    required AttendanceEntity? record,
    required bool isActive,
  }) {
    final isDark = context.isDark;
    final isDone = record != null;
    final timeStr = isDone ? DateFormat('h:mm a').format(record.hora.toLocal()) : null;

    final Color borderColor = isDone
        ? AppColors.success.withValues(alpha: isDark ? 0.45 : 0.4)
        : (isActive ? AppColors.primary : context.cBorder.withValues(alpha: isDark ? 0.35 : 0.4));
    final Color bgColor = isDone
        ? AppColors.success.withValues(alpha: isDark ? 0.12 : 0.05)
        : (isActive ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08) : Colors.transparent);
    final Color iconColor = isDone ? AppColors.success : (isActive ? AppColors.primary : context.cTextSecondary.withValues(alpha: 0.6));
    final String label = isDone ? '$timeStr  ✓' : (isActive ? 'Toca para marcar' : 'Pendiente');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(tipo),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isActive ? 1.4 : 0.8),
          ),
          child: Row(
            children: [
              Icon(isDone ? CupertinoIcons.checkmark_alt_circle_fill : icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isDone ? AppColors.success : (isActive ? AppColors.primary : context.cTextPrimary),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: isDone || isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isDone ? AppColors.success : (isActive ? AppColors.primary : context.cTextSecondary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
