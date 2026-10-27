// ============================================================================
// ARCHIVO: work_schedule.dart
// QUÉ HACE: Entidad de dominio para la jornada laboral pactada, plantillas de
//           turnos, ventana permitida para marcar y Horas Extras Asignadas
//           (`assignedOvertimeMinutes`).
// CÓMO FUNCIONA:
// 1. Serializa a JSON para SQLite (`schedule_json`), incluyendo `overtimeMinutes`.
// 2. Si el colaborador tiene `assignedOvertimeMinutes > 0`, extiende de forma
//    automática el límite de ventana de salida para permitirle marcar al
//    terminar sus horas extras o al cumplir su turno base.
// POR QUÉ: Soporta horas extras pre-asignadas que se contabilizan al cumplir
//          el horario pactado o al marcar salida de extras (< 145 líneas).
// ============================================================================

import 'dart:convert';

class WorkSchedule {
  const WorkSchedule(
    this.dailyMinutes,
    this.deductLunch, {
    this.nightStartMinute = 1140,
    this.nightEndMinute = 360,
    this.shiftName,
    this.startMinute,
    this.endMinute,
    this.markStartMinute,
    this.markEndMinute,
    this.weekdays = const [1, 2, 3, 4, 5],
    this.assignedOvertimeMinutes = 0,
  });

  final int dailyMinutes;
  final bool deductLunch;
  final int nightStartMinute, nightEndMinute;
  final String? shiftName;
  final int? startMinute;
  final int? endMinute;
  final int? markStartMinute;
  final int? markEndMinute;
  final List<int> weekdays;
  final int assignedOvertimeMinutes;

  bool get hasAssignedOvertime => assignedOvertimeMinutes > 0;

  String get overtimeFormatted {
    if (assignedOvertimeMinutes <= 0) return 'Sin horas extras';
    final h = assignedOvertimeMinutes ~/ 60;
    final m = assignedOvertimeMinutes % 60;
    return m > 0 ? '+${h}h ${m}m Extras' : '+${h}h Extras';
  }

  WorkSchedule copyWith({int? assignedOvertimeMinutes}) => WorkSchedule(
        dailyMinutes,
        deductLunch,
        nightStartMinute: nightStartMinute,
        nightEndMinute: nightEndMinute,
        shiftName: shiftName,
        startMinute: startMinute,
        endMinute: endMinute,
        markStartMinute: markStartMinute,
        markEndMinute: markEndMinute,
        weekdays: weekdays,
        assignedOvertimeMinutes: assignedOvertimeMinutes ?? this.assignedOvertimeMinutes,
      );

  String get timeWindowFormatted {
    if (startMinute == null || endMinute == null) {
      final hours = dailyMinutes ~/ 60;
      final mins = dailyMinutes % 60;
      return mins > 0 ? '$hours h $mins m / día' : '$hours h / día';
    }
    final sH = (startMinute! ~/ 60).toString().padLeft(2, '0');
    final sM = (startMinute! % 60).toString().padLeft(2, '0');
    final eH = (endMinute! ~/ 60).toString().padLeft(2, '0');
    final eM = (endMinute! % 60).toString().padLeft(2, '0');
    return '$sH:$sM - $eH:$eM';
  }

  String get markWindowFormatted {
    if (markStartMinute == null || markEndMinute == null) return timeWindowFormatted;
    final effectiveEnd = (markEndMinute! + assignedOvertimeMinutes) % 1440;
    final sH = (markStartMinute! ~/ 60).toString().padLeft(2, '0');
    final sM = (markStartMinute! % 60).toString().padLeft(2, '0');
    final eH = (effectiveEnd ~/ 60).toString().padLeft(2, '0');
    final eM = (effectiveEnd % 60).toString().padLeft(2, '0');
    return '$sH:$sM a $eH:$eM';
  }

  bool isTimeWithinMarkWindow(DateTime wallTime) {
    if (markStartMinute == null || markEndMinute == null) return true;
    final currentMinute = wallTime.hour * 60 + wallTime.minute;
    final effectiveEnd = (markEndMinute! + assignedOvertimeMinutes) % 1440;
    if (markStartMinute! <= effectiveEnd) {
      return currentMinute >= markStartMinute! && currentMinute <= effectiveEnd;
    } else {
      return currentMinute >= markStartMinute! || currentMinute <= effectiveEnd;
    }
  }

  String encode() => jsonEncode({
        'minutes': dailyMinutes,
        'deduct': deductLunch,
        'nightStart': nightStartMinute,
        'nightEnd': nightEndMinute,
        if (shiftName != null) 'name': shiftName,
        if (startMinute != null) 'start': startMinute,
        if (endMinute != null) 'end': endMinute,
        if (markStartMinute != null) 'markStart': markStartMinute,
        if (markEndMinute != null) 'markEnd': markEndMinute,
        'weekdays': weekdays,
        'overtimeMinutes': assignedOvertimeMinutes,
      });

  static WorkSchedule? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    final data = jsonDecode(text) as Map<String, dynamic>;
    return WorkSchedule(
      data['minutes'] as int,
      data['deduct'] as bool,
      nightStartMinute: data['nightStart'] as int? ?? 1140,
      nightEndMinute: data['nightEnd'] as int? ?? 360,
      shiftName: data['name'] as String?,
      startMinute: data['start'] as int?,
      endMinute: data['end'] as int?,
      markStartMinute: data['markStart'] as int?,
      markEndMinute: data['markEnd'] as int?,
      weekdays: (data['weekdays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [1, 2, 3, 4, 5],
      assignedOvertimeMinutes: data['overtimeMinutes'] as int? ?? 0,
    );
  }
}

abstract final class ColombiaClock {
  static DateTime wall(DateTime date) => date.toUtc().subtract(const Duration(hours: 5));
  static String day(DateTime date) => wall(date).toIso8601String().split('T').first;
  static String hour(DateTime date) {
    final d = wall(date);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String duration(Duration value) =>
      '${value.inHours.toString().padLeft(2, '0')}:${(value.inMinutes % 60).toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
}
