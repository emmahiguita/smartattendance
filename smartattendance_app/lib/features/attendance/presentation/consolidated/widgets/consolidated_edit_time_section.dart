// ============================================================================
// ARCHIVO: consolidated_edit_time_section.dart
// CAPA: Presentation / Consolidated / Widgets
// QUÉ HACE: Editor visual reactivo de Fecha, Hora Entrada, Hora Salida y Horas Totales.
// CÓMO FUNCIONA: Despliega selectores con TimeOfDay y recalcula la duración activa.
// POR QUÉ: Permite corregir tiempos con estilo sobrio y cumple regla < 190 líneas.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';

class ConsolidatedEditTimeSection extends StatelessWidget {
  const ConsolidatedEditTimeSection({
    super.key,
    required this.selectedDate,
    required this.entradaTime,
    required this.salidaTime,
    required this.onDateChanged,
    required this.onEntradaChanged,
    required this.onSalidaChanged,
  });

  final DateTime selectedDate;
  final TimeOfDay? entradaTime;
  final TimeOfDay? salidaTime;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay?> onEntradaChanged;
  final ValueChanged<TimeOfDay?> onSalidaChanged;

  String _formatDuration() {
    if (entradaTime == null || salidaTime == null) return 'Pendiente';
    final inMin = entradaTime!.hour * 60 + entradaTime!.minute;
    var outMin = salidaTime!.hour * 60 + salidaTime!.minute;
    if (outMin < inMin) outMin += 24 * 60;
    final diff = outMin - inMin;
    final h = diff ~/ 60;
    final m = diff % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) onDateChanged(picked);
  }

  Future<void> _pickTime(BuildContext context, bool isEntrada) async {
    final current = isEntrada ? entradaTime : salidaTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? (isEntrada ? const TimeOfDay(hour: 7, minute: 0) : const TimeOfDay(hour: 17, minute: 0)),
    );
    if (picked != null) {
      if (isEntrada) {
        onEntradaChanged(picked);
      } else {
        onSalidaChanged(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateStr;
    try {
      dateStr = DateFormat('EEE, d MMM yyyy', 'es').format(selectedDate);
    } catch (_) {
      dateStr = '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
    }
    final inStr = entradaTime != null ? entradaTime!.format(context) : 'Sin marcar';
    final outStr = salidaTime != null ? salidaTime!.format(context) : 'Sin marcar';
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _pickDate(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.cBorder.withValues(alpha: 0.5), width: 0.8),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.calendar, size: 16, color: context.cTextSecondary),
                const SizedBox(width: 8),
                Text('Fecha:', style: TextStyle(fontSize: 12, color: context.cTextSecondary)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dateStr,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.cTextPrimary),
                  ),
                ),
                Text('Cambiar', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.cTextSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TimeBox(
                label: 'Hora Entrada',
                timeText: inStr,
                icon: CupertinoIcons.arrow_right_circle,
                onTap: () => _pickTime(context, true),
                onClear: entradaTime != null ? () => onEntradaChanged(null) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TimeBox(
                label: 'Hora Salida',
                timeText: outStr,
                icon: CupertinoIcons.arrow_left_circle,
                onTap: () => _pickTime(context, false),
                onClear: salidaTime != null ? () => onSalidaChanged(null) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.cBorder.withValues(alpha: 0.4), width: 0.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.stopwatch, size: 13, color: context.cTextSecondary),
              const SizedBox(width: 6),
              Text(
                'Jornada calculada: ${_formatDuration()}',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.cTextPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.label,
    required this.timeText,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String timeText;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: context.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.cBorder.withValues(alpha: 0.6), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: context.cTextSecondary),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 10.5, color: context.cTextSecondary)),
                const Spacer(),
                if (onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(CupertinoIcons.clear_circled, size: 14, color: context.cTextSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              timeText,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.cTextPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
