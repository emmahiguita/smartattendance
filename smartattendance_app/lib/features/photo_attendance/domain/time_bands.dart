import 'work_schedule.dart';
import 'colombia_holidays.dart';

/// Parte intervalos en medianoche y cambios de franja. Dominical y festivo son
/// etiquetas superpuestas: NO se suman otra vez al tiempo total trabajado.
class TimeBands {
  TimeBands(this.schedule);
  final WorkSchedule schedule;
  Duration day = Duration.zero,
      night = Duration.zero,
      extraDay = Duration.zero,
      extraNight = Duration.zero,
      sunday = Duration.zero,
      holiday = Duration.zero;
  Duration _used = Duration.zero;
  void add(DateTime start, DateTime end) {
    var cursor = start.toUtc();
    while (cursor.isBefore(end.toUtc())) {
      final wall = ColombiaClock.wall(cursor);
      final midnight = DateTime.utc(wall.year, wall.month, wall.day);
      var next = midnight.add(const Duration(days: 1, hours: 5));
      for (final minute in [
        schedule.nightStartMinute,
        schedule.nightEndMinute
      ]) {
        final boundary = midnight.add(Duration(minutes: minute, hours: 5));
        if (boundary.isAfter(cursor) && boundary.isBefore(next)) {
          next = boundary;
        }
      }
      if (end.toUtc().isBefore(next)) next = end.toUtc();
      final duration = next.difference(cursor);
      final quota = Duration(minutes: schedule.dailyMinutes) - _used;
      final ordinary = quota.isNegative
          ? Duration.zero
          : (quota < duration ? quota : duration);
      final extra = duration - ordinary;
      final minute = wall.hour * 60 + wall.minute;
      final isNight = schedule.nightStartMinute > schedule.nightEndMinute
          ? minute >= schedule.nightStartMinute ||
              minute < schedule.nightEndMinute
          : minute >= schedule.nightStartMinute &&
              minute < schedule.nightEndMinute;
      if (isNight) {
        night += ordinary;
        extraNight += extra;
      } else {
        day += ordinary;
        extraDay += extra;
      }
      if (wall.weekday == DateTime.sunday) sunday += duration;
      if (ColombiaHolidays.contains(wall)) holiday += duration;
      _used += duration;
      cursor = next;
    }
  }

  List<Duration> get values =>
      [day, night, extraDay, extraNight, sunday, holiday];
}
