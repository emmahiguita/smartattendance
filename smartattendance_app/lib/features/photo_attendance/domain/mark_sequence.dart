// ============================================================================
// ARCHIVO: mark_sequence.dart
// QUÉ HACE: Define y valida de forma estricta la secuencia única de una
//           jornada laboral diaria:
//           1. `entrada` (Inicio)
//           2. `salida_almuerzo` (Salida a almuerzo)
//           3. `regreso_almuerzo` (Regreso de almuerzo)
//           4. `salida` (Salida final - cierra la jornada del día)
// CÓMO FUNCIONA:
// - `allowed` mapea la última marca del día hacia la única marca siguiente
//   válida. Cuando ya se marcó `salida`, retorna lista vacía `[]` porque la
//   jornada del día está cerrada.
// - `validate` lanza `FormatException` descriptiva si se intenta saltar un
//   paso, repetir una marca o marcar `salida` sin haber iniciado jornada.
// POR QUÉ: Corrige el bug que permitía marcar Salida, Almuerzo o Regreso sin
//          orden lógico o repetir Salida en una misma jornada (< 85 líneas).
// ============================================================================

import '../../../../core/utils/attendance_type.dart';

abstract final class MarkSequence {
  /// Transiciones estrictas paso a paso dentro de una jornada diaria.
  static const allowed = <String, List<String>>{
    '': ['entrada'],
    'entrada': ['salida_almuerzo'],
    'salida_almuerzo': ['regreso_almuerzo'],
    'regreso_almuerzo': ['salida'],
    'salida': <String>[],
  };

  /// QUÉ HACE: Devuelve las marcas permitidas después de `last`.
  static List<String> options(String? last) {
    final key = (last ?? '').trim().toLowerCase();
    return allowed[key] ?? const ['entrada'];
  }

  /// QUÉ HACE: Devuelve el siguiente paso obligatorio de la jornada, o `''`
  ///           si la jornada de hoy ya concluyó con `salida`.
  static String next(String? last) {
    final opts = options(last);
    return opts.isEmpty ? '' : opts.first;
  }

  /// QUÉ HACE: Nombre legible en español para mensajes de validación.
  static String labelOf(String type) => switch (type.trim().toLowerCase()) {
        'entrada' => 'Inicio (Entrada)',
        'salida_almuerzo' => 'Salida a Almuerzo',
        'regreso_almuerzo' => 'Regreso de Almuerzo',
        'salida' => 'Salida Final',
        _ => 'Jornada Completada',
      };

  /// QUÉ HACE: Valida estrictamente que `nextType` sea el paso que sigue a `previous`.
  static void validate(String? previous, String nextType) {
    final cleanNext = nextType.trim().toLowerCase();
    if (!knownAttendanceTypes.contains(cleanNext)) {
      throw FormatException('Tipo de marcación no reconocido: $nextType');
    }
    final cleanPrev = (previous ?? '').trim().toLowerCase();
    if (cleanPrev == 'salida') {
      throw const FormatException(
        'La jornada de hoy ya fue cerrada con tu Salida. No puedes registrar más marcas hoy.',
      );
    }
    final expected = next(cleanPrev);
    if (cleanNext != expected) {
      if (cleanPrev.isEmpty) {
        throw const FormatException(
          'No puedes marcar Almuerzo ni Salida sin haber registrado primero tu Inicio (Entrada).',
        );
      }
      throw FormatException(
        'Orden de jornada inválido: tu última marca fue "${labelOf(cleanPrev)}", por lo tanto debes registrar "${labelOf(expected)}".',
      );
    }
  }
}
