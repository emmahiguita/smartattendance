// ============================================================================
// ARCHIVO: shift_template.dart
// QUÉ HACE: Entidad de dominio para plantillas de turno laboral configuradas por
//           el Administrador. Soporta horarios base y ventanas de marcación.
// CÓMO FUNCIONA: Serializa a SQLite (`shift_templates`) y genera instancias de
//                `WorkSchedule` con restricciones de tiempo para marcar.
// POR QUÉ: Permite al Administrador habilitar o deshabilitar libremente los
//          horarios y ventanas de marcación según necesidades de la empresa.
// ============================================================================

import 'dart:convert';
import 'work_schedule.dart';

/// Plantilla predefinida o personalizada de turno laboral.
class ShiftTemplate {
  const ShiftTemplate({
    this.id,
    required this.name,
    required this.startMinute,
    required this.endMinute,
    required this.dailyMinutes,
    this.deductLunch = true,
    this.nightStartMinute = 1140,
    this.nightEndMinute = 360,
    this.weekdays = const [1, 2, 3, 4, 5],
    this.enableMarkWindow = false,
    this.markStartMinute,
    this.markEndMinute,
  });

  final int? id;
  final String name;
  final int startMinute;
  final int endMinute;
  final int dailyMinutes;
  final bool deductLunch;
  final int nightStartMinute;
  final int nightEndMinute;
  final List<int> weekdays;
  final bool enableMarkWindow;
  final int? markStartMinute;
  final int? markEndMinute;

  String get timeFormatted {
    final sH = (startMinute ~/ 60).toString().padLeft(2, '0');
    final sM = (startMinute % 60).toString().padLeft(2, '0');
    final eH = (endMinute ~/ 60).toString().padLeft(2, '0');
    final eM = (endMinute % 60).toString().padLeft(2, '0');
    return '$sH:$sM - $eH:$eM';
  }

  String get durationFormatted {
    final hours = dailyMinutes ~/ 60;
    final mins = dailyMinutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  String get markWindowSummary {
    if (!enableMarkWindow || markStartMinute == null || markEndMinute == null) {
      return 'Marcación libre (Sin restricción horaria)';
    }
    final sH = (markStartMinute! ~/ 60).toString().padLeft(2, '0');
    final sM = (markStartMinute! % 60).toString().padLeft(2, '0');
    final eH = (markEndMinute! ~/ 60).toString().padLeft(2, '0');
    final eM = (markEndMinute! % 60).toString().padLeft(2, '0');
    return 'Marcar permitido: $sH:$sM a $eH:$eM';
  }

  String get weekdaysSummary {
    if (weekdays.length == 7) return 'Todos los días';
    if (weekdays.length == 5 && weekdays.contains(1) && weekdays.contains(5)) {
      return 'Lun - Vie';
    }
    if (weekdays.length == 6 && weekdays.contains(1) && weekdays.contains(6)) {
      return 'Lun - Sáb';
    }
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return weekdays.map((d) => (d >= 1 && d <= 7) ? days[d - 1] : '').join(', ');
  }

  WorkSchedule toSchedule() => WorkSchedule(
        dailyMinutes,
        deductLunch,
        shiftName: name,
        startMinute: startMinute,
        endMinute: endMinute,
        markStartMinute: enableMarkWindow ? markStartMinute : null,
        markEndMinute: enableMarkWindow ? markEndMinute : null,
        nightStartMinute: nightStartMinute,
        nightEndMinute: nightEndMinute,
        weekdays: weekdays,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'start_minute': startMinute,
        'end_minute': endMinute,
        'daily_minutes': dailyMinutes,
        'deduct_lunch': deductLunch ? 1 : 0,
        'night_start_minute': nightStartMinute,
        'night_end_minute': nightEndMinute,
        'weekdays': jsonEncode(weekdays),
        'enable_mark_window': enableMarkWindow ? 1 : 0,
        'mark_start_minute': markStartMinute,
        'mark_end_minute': markEndMinute,
      };

  factory ShiftTemplate.fromMap(Map<String, Object?> map) {
    List<int> parsedWeekdays = const [1, 2, 3, 4, 5];
    final rawWd = map['weekdays'];
    if (rawWd is String && rawWd.isNotEmpty) {
      try {
        parsedWeekdays = (jsonDecode(rawWd) as List<dynamic>).map((e) => e as int).toList();
      } catch (_) {}
    }
    return ShiftTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      startMinute: map['start_minute'] as int,
      endMinute: map['end_minute'] as int,
      dailyMinutes: map['daily_minutes'] as int,
      deductLunch: (map['deduct_lunch'] as int? ?? 1) == 1,
      nightStartMinute: map['night_start_minute'] as int? ?? 1140,
      nightEndMinute: map['night_end_minute'] as int? ?? 360,
      weekdays: parsedWeekdays,
      enableMarkWindow: (map['enable_mark_window'] as int? ?? 0) == 1,
      markStartMinute: map['mark_start_minute'] as int?,
      markEndMinute: map['mark_end_minute'] as int?,
    );
  }
}
