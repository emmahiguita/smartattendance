// lib/features/photo_attendance/domain/mark_sequence.dart
import '../../../../core/utils/attendance_type.dart';

/// ============================================================================
/// DOMINIO: MarkSequence (fuente única de "¿qué marca sigue?")
/// ============================================================================
/// QUÉ HACE:
/// Sugiere el orden natural de la jornada:
///   Entrada → Inicio almuerzo → Regreso almuerzo → Salida → (nueva Entrada)
///
/// CÓMO FUNCIONA:
/// [allowed] mapea "última marca" → "marcas permitidas"; la PRIMERA de cada
/// lista es la sugerida ([next]). Una última marca desconocida (p. ej. un
/// 'hora_extra_*' antiguo) se trata como "sin marca" → sugiere Entrada.
///
/// POR QUÉ:
/// Antes Home, la lista de trabajadores y el directorio calculaban "la
/// siguiente marca" cada uno a su manera (código duplicado y resultados
/// distintos). Ahora todos llaman a [next]. Las horas extras NO están:
/// las decide el administrador, no el trabajador marcando.
/// ============================================================================
abstract final class MarkSequence {
  /// Transiciones de la jornada. Clave '' = todavía no hay marcas.
  static const allowed = <String, List<String>>{
    '': ['entrada', 'salida_almuerzo', 'regreso_almuerzo', 'salida'],
    'entrada': ['salida_almuerzo', 'salida', 'regreso_almuerzo'],
    'salida_almuerzo': ['regreso_almuerzo', 'salida'],
    'regreso_almuerzo': ['salida', 'salida_almuerzo'],
    'salida': ['entrada'],
  };

  /// Marcas permitidas después de [last] (desconocida → como si no hubiera).
  static List<String> options(String? last) =>
      allowed[last ?? ''] ?? allowed['']!;

  /// Marca sugerida después de [last]. Ej.: next('entrada') = 'salida_almuerzo'.
  static String next(String? last) => options(last).first;

  /// Valida que [next] sea un tipo conocido. Acepta los tipos antiguos para
  /// que el cálculo de totales del historial no falle con registros viejos;
  /// la escritura de marcas NUEVAS se restringe aparte con [attendanceTypes].
  static void validate(String? previous, String next) {
    if (!knownAttendanceTypes.contains(next)) {
      throw FormatException('Tipo de marcación no reconocido: $next');
    }
  }
}
