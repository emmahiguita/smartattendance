// ============================================================================
// ARCHIVO: work_schedule.dart
// QUÉ HACE: Entidad de dominio para la jornada laboral pactada, plantillas de
//           turnos y ventana/rango de horas permitido para marcar.
// CÓMO FUNCIONA: Serializa a JSON para SQLite (`schedule_json`), calcula
//                horas diarias y evalúa si la hora actual está dentro del
//                rango permitido configurado por el supervisor (`markStart/End`).
// POR QUÉ: Permite al supervisor limitar de qué hora a qué hora puede marcar
//          el colaborador sin inventar cálculos rígidos (< 115 líneas).
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
    if (markStartMinute == null || markEndMinute == null) {
      return timeWindowFormatted;
    }
    final sH = (markStartMinute! ~/ 60).toString().padLeft(2, '0');
    final sM = (markStartMinute! % 60).toString().padLeft(2, '0');
    final eH = (markEndMinute! ~/ 60).toString().padLeft(2, '0');
    final eM = (markEndMinute! % 60).toString().padLeft(2, '0');
    return '$sH:$sM a $eH:$eM';
  }

  bool isTimeWithinMarkWindow(DateTime wallTime) {
    if (markStartMinute == null || markEndMinute == null) return true;
    final currentMinute = wallTime.hour * 60 + wallTime.minute;
    if (markStartMinute! <= markEndMinute!) {
      return currentMinute >= markStartMinute! && currentMinute <= markEndMinute!;
    } else {
      return currentMinute >= markStartMinute! || currentMinute <= markEndMinute!;
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
      weekdays: (data['weekdays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [1, 2, 3, 4, 5],
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