/// Festivos nacionales de la Ley 51 de 1983. Calcula Pascua gregoriana y traslada
/// al lunes únicamente los festivos indicados; no consulta internet.
abstract final class ColombiaHolidays {
  static final _cache = <int, Set<String>>{};
  static String _key(DateTime d) => '${d.month}-${d.day}';
  static bool contains(DateTime wall) => _cache
      .putIfAbsent(wall.year, () => _year(wall.year))
      .contains(_key(wall));
  static Set<String> _year(int year) {
    final result = <String>{};
    void add(DateTime date, {bool monday = false}) {
      if (monday) date = date.add(Duration(days: (8 - date.weekday) % 7));
      result.add(_key(date));
    }

    for (final pair in const [
      (1, 1),
      (5, 1),
      (7, 20),
      (8, 7),
      (12, 8),
      (12, 25)
    ]) {
      add(DateTime.utc(year, pair.$1, pair.$2));
    }
    for (final pair in const [
      (1, 6),
      (3, 19),
      (6, 29),
      (8, 15),
      (10, 12),
      (11, 1),
      (11, 11)
    ]) {
      add(DateTime.utc(year, pair.$1, pair.$2), monday: true);
    }
    // Algoritmo gregoriano de Meeus: calendario, no reglas de remuneración.
    final a = year % 19, b = year ~/ 100, c = year % 100, d = b ~/ 4, e = b % 4;
    final f = (b + 8) ~/ 25, g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30, i = c ~/ 4, k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7,
        m = (a + 11 * h + 22 * l) ~/ 451;
    final value = h + l - 7 * m + 114;
    final easter = DateTime.utc(year, value ~/ 31, value % 31 + 1);
    add(easter.subtract(const Duration(days: 3)));
    add(easter.subtract(const Duration(days: 2)));
    for (final offset in [39, 60, 68]) {
      add(easter.add(Duration(days: offset)), monday: true);
    }
    return result;
  }
}
