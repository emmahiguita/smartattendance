// ============================================================================
// ARCHIVO: serviciudad_hero_card.dart
// QUÉ HACE: Panel con los 4 botones compactos de marcación de la jornada:
//           1. Inicio (`entrada`), 2. Salida Almuerzo (`salida_almuerzo`),
//           3. Regreso Almuerzo (`regreso_almuerzo`), 4. Salida (`salida`).
// CÓMO FUNCIONA:
// - Calcula el estado real de hoy y habilita ÚNICAMENTE el botón que
//   corresponde al paso actual (`nextTipo`).
// - Bloquea el toque en botones ya marcados (`isDone`) o fuera de orden
//   (`!isActive`), mostrando un aviso claro si el usuario intenta saltar pasos.
// POR QUÉ: Corrige el bug que permitía tocar Salida, Regreso o Almuerzo sin
//          haber marcado Entrada o repetir Salida (< 180 líneas).
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
    final now = DateTime.now();
    final today = records.where((r) {
      final l = r.fecha.toLocal();
      return l.year == now.year && l.month == now.month && l.day == now.day;
    }).toList()
      ..sort((a, b) => a.hora.compareTo(b.hora));

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
                nextTipo: nextTipo,
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
                nextTipo: nextTipo,
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
                nextTipo: nextTipo,
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
                nextTipo: nextTipo,
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
    required String nextTipo,
  }) {
    final isDark = context.isDark;
    final isDone = record != null;
    final isActive = !isDone && nextTipo == tipo;
    final timeStr = isDone ? DateFormat('h:mm a').format(record.hora.toLocal()) : null;

    final Color borderColor = isDone
        ? AppColors.success.withValues(alpha: isDark ? 0.45 : 0.4)
        : (isActive ? AppColors.primary : context.cBorder.withValues(alpha: isDark ? 0.35 : 0.4));
    final Color bgColor = isDone
        ? AppColors.success.withValues(alpha: isDark ? 0.12 : 0.05)
        : (isActive ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08) : Colors.transparent);
    final Color iconColor = isDone
        ? AppColors.success
        : (isActive ? AppColors.primary : context.cTextSecondary.withValues(alpha: 0.45));
    final String label = isDone ? '$timeStr  ✓' : (isActive ? 'Toca para marcar' : 'Bloqueado');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isDone) {
            _notifyBlocked(context, 'Ya registraste "$title" hoy a las $timeStr.');
            return;
          }
          if (!isActive) {
            final msg = nextTipo.isEmpty
                ? 'Tu jornada de hoy ya finalizó con tu Salida.'
                : 'Orden de jornada: primero debes marcar "${MarkSequence.labelOf(nextTipo)}".';
            _notifyBlocked(context, msg);
            return;
          }
          onTap(tipo);
        },
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
              Icon(
                isDone ? CupertinoIcons.checkmark_alt_circle_fill : (isActive ? icon : CupertinoIcons.lock_fill),
                size: 19,
                color: iconColor,
              ),
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
                        color: isDone ? AppColors.success : (isActive ? AppColors.primary : context.cTextSecondary),
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
