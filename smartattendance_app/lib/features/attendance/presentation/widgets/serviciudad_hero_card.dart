// ============================================================================
// ARCHIVO: serviciudad_hero_card.dart
// QUÉ HACE: Panel con los 4 botones compactos de marcación de la jornada
//           (`Inicio`, `Salida Almuerzo`, `Regreso Almuerzo`, `Salida`) y el
//           Marcador de Horas Extras Asignadas con cristal translúcido 100% iOS
//           en Modo Oscuro (`BackdropFilter`).
// CÓMO FUNCIONA:
// 1. Determina `nextTipo` evaluando en orden estricto las 4 etapas del día.
// 2. Renderiza cada botón con cristal esmerilado iOS (`ImageFilter.blur`) y
//    borde especular en modo oscuro, junto al marcador de Horas Extras Asignadas.
// POR QUÉ: Cumple la regla de negocio de Horas Extras Asignadas + secuencia
//          estricta + modo oscuro 100% iOS transparente profesional (< 165 líneas).
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/mark_sequence.dart';
import '../../domain/entities/attendance_entity.dart';

class ServiciudadHeroCard extends StatelessWidget {
  const ServiciudadHeroCard({
    super.key,
    required this.records,
    required this.onTap,
    this.assignedOvertimeMinutes = 0,
  });

  final List<AttendanceEntity> records;
  final ValueChanged<String> onTap;
  final int assignedOvertimeMinutes;

  void _notifyBlocked(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final now = DateTime.now();
    final today = records.where((r) {
      final l = r.fecha.toLocal();
      return l.year == now.year && l.month == now.month && l.day == now.day;
    }).toList()..sort((a, b) => a.hora.compareTo(b.hora));

    final entrada = today.where((r) => r.tipo.toLowerCase() == 'entrada').firstOrNull;
    final salidaAlm = today.where((r) => r.tipo.toLowerCase() == 'salida_almuerzo').firstOrNull;
    final regresoAlm = today.where((r) => r.tipo.toLowerCase() == 'regreso_almuerzo').firstOrNull;
    final salida = today.where((r) => r.tipo.toLowerCase() == 'salida').firstOrNull;

    final nextTipo = entrada == null
        ? 'entrada'
        : (salidaAlm == null
            ? 'salida_almuerzo'
            : (regresoAlm == null ? 'regreso_almuerzo' : (salida == null ? 'salida' : '')));

    final hasExtra = assignedOvertimeMinutes > 0;
    final extraHours = assignedOvertimeMinutes ~/ 60;
    final extraColor = salida != null ? (isDark ? AppColors.successDark : AppColors.success) : const Color(0xFFF59E0B);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: _btn(context, 'entrada', 'Inicio', CupertinoIcons.arrow_down_right_circle, entrada, nextTipo)),
        const SizedBox(width: 8),
        Expanded(child: _btn(context, 'salida_almuerzo', 'Salida Almuerzo', CupertinoIcons.pause_circle, salidaAlm, nextTipo)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _btn(context, 'regreso_almuerzo', 'Regreso Almuerzo', CupertinoIcons.play_circle, regresoAlm, nextTipo)),
        const SizedBox(width: 8),
        Expanded(child: _btn(context, 'salida', hasExtra ? 'Salida (+${extraHours}h Ext)' : 'Salida', CupertinoIcons.arrow_up_right_circle, salida, nextTipo)),
      ]),
      if (hasExtra) ...[
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: extraColor.withValues(alpha: isDark ? 0.14 : 0.10),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: extraColor.withValues(alpha: isDark ? 0.50 : 0.45), width: 0.9),
              ),
              child: Row(children: [
                Icon(salida != null ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.bolt_badge_a_fill, size: 16, color: extraColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    salida != null
                        ? 'Horas Extras Contabilizadas (+${extraHours}h): Jornada y extras cumplidas'
                        : 'Marcador Horas Extras Asignadas (+${extraHours}h): Se cuentan al cumplir horario o al marcar Salida final',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: salida != null ? extraColor : context.cTextPrimary),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _btn(BuildContext context, String tipo, String title, IconData icon, AttendanceEntity? record, String nextTipo) {
    final isDark = context.isDark;
    final isDone = record != null;
    final isActive = !isDone && nextTipo == tipo;
    final timeStr = isDone ? DateFormat('h:mm a').format(record.hora.toLocal()) : null;
    final activeBlue = isDark ? AppColors.primaryDark : AppColors.primary;
    final doneGreen = isDark ? AppColors.successDark : AppColors.success;

    final borderColor = isDone
        ? doneGreen.withValues(alpha: isDark ? 0.55 : 0.40)
        : (isActive ? activeBlue : (isDark ? Colors.white.withValues(alpha: 0.16) : context.cBorder.withValues(alpha: 0.4)));
    final bgColor = isDone
        ? doneGreen.withValues(alpha: isDark ? 0.15 : 0.05)
        : (isActive ? activeBlue.withValues(alpha: isDark ? 0.22 : 0.08) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent));
    final fgColor = isDone ? doneGreen : (isActive ? activeBlue : context.cTextSecondary);
    final label = isDone ? '$timeStr  ✓' : (isActive ? 'Toca para marcar' : 'Bloqueado');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isDone) return _notifyBlocked(context, 'Ya registraste "$title" hoy a las $timeStr.');
              if (!isActive) {
                return _notifyBlocked(context, nextTipo.isEmpty ? 'Tu jornada de hoy ya finalizó con tu Salida.' : 'Orden de jornada: primero debes marcar "${MarkSequence.labelOf(nextTipo)}".');
              }
              onTap(tipo);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor, width: isActive ? 1.3 : 0.85)),
              child: Row(children: [
                Icon(isDone ? CupertinoIcons.checkmark_alt_circle_fill : (isActive ? icon : CupertinoIcons.lock_fill), size: 19, color: isDone || isActive ? fgColor : fgColor.withValues(alpha: 0.55)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: fgColor, letterSpacing: -0.2)),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, fontWeight: isDone || isActive ? FontWeight.w600 : FontWeight.w400, color: fgColor)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
