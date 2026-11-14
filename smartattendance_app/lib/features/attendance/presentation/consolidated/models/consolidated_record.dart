// ============================================================================
// ARCHIVO: consolidated_record.dart
// CAPA: Presentation / Consolidated / Models
// QUÉ HACE: Modela un registro consolidado de asistencia para la tabla interactiva.
// CÓMO FUNCIONA: Adapta un `PhotoDay` a propiedades formateadas listas para UI.
// POR QUÉ: Principio de Responsabilidad Única (SRP), inmutabilidad y legibilidad.
// ============================================================================

import '../../../../photo_attendance/domain/photo_record.dart';
import '../../../../photo_attendance/domain/work_schedule.dart';

class ConsolidatedRecord {
  const ConsolidatedRecord({
    required this.journeyId,
    this.workerId = 0,
    required this.colaborador,
    required this.cedula,
    required this.cargo,
    required this.zona,
    required this.fecha,
    required this.fechaFormatted,
    required this.entrada,
    required this.salida,
    this.entradaDateTime,
    this.salidaDateTime,
    required this.horas,
    required this.extras,
    required this.estado,
    required this.rawDay,
    this.approvedSeconds,
    this.reviewNote,
    this.reviewedBy,
    this.reviewedAt,
  });

  final String journeyId;
  final int workerId;
  final String colaborador;
  final String cedula;
  final String cargo;
  final String zona;
  final DateTime fecha;
  final String fechaFormatted;
  final String entrada;
  final String salida;
  final DateTime? entradaDateTime;
  final DateTime? salidaDateTime;
  final String horas;
  final String extras;
  final String estado;
  final int? approvedSeconds;
  final String? reviewNote;
  final String? reviewedBy;
  final String? reviewedAt;
  final PhotoDay rawDay;

  /// QUÉ HACE: Construye el DTO desde la jornada real (`PhotoDay`).
  /// CÓMO: Extrae marcas de entrada/salida y calcula tiempos exactos.
  /// POR QUÉ: Centraliza la lógica de transformación de dominio a presentación.
  factory ConsolidatedRecord.fromPhotoDay(PhotoDay day) {
    final e = day.marks('entrada').firstOrNull;
    final s = day.marks('salida').firstOrNull;

    final dur = day.totals.active;
    final horasStr = dur > Duration.zero
        ? '${dur.inHours}h ${(dur.inMinutes % 60).toString().padLeft(2, '0')}m'
        : '-';

    final approved = day.approvedSeconds;
    var extrasDur = Duration.zero;
    if (approved != null && approved > 0) {
      extrasDur = Duration(seconds: approved);
    } else if (day.totals.additional != null && day.totals.additional! > Duration.zero) {
      extrasDur = day.totals.additional!;
    } else if (day.totals.active > const Duration(hours: 8)) {
      extrasDur = day.totals.active - const Duration(hours: 8);
    }

    final extrasStr = extrasDur > Duration.zero
        ? '${extrasDur.inHours}h ${(extrasDur.inMinutes % 60).toString().padLeft(2, '0')}m'
        : '0h 00m';

    final d = day.date;
    final fechaFmt =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    String estadoStr;
    switch (day.status) {
      case 'void':
        estadoStr = 'Anulada';
        break;
      case 'closed':
        estadoStr = 'Cerrada';
        break;
      default:
        estadoStr = 'Abierta';
    }

    return ConsolidatedRecord(
      journeyId: day.id,
      workerId: day.worker.workerId,
      colaborador: day.worker.name,
      cedula: day.worker.document,
      cargo: day.worker.job,
      zona: day.zoneName ?? 'Sede Principal Operativa',
      fecha: d,
      fechaFormatted: fechaFmt,
      entrada: e != null ? ColombiaClock.hour(e.capturedAt) : '-',
      salida: s != null ? ColombiaClock.hour(s.capturedAt) : '-',
      entradaDateTime: e?.capturedAt,
      salidaDateTime: s?.capturedAt,
      horas: horasStr,
      extras: extrasStr,
      estado: estadoStr,
      approvedSeconds: day.approvedSeconds,
      reviewNote: day.reviewNote,
      reviewedBy: day.reviewedBy,
      reviewedAt: day.reviewedAt,
      rawDay: day,
    );
  }

  ConsolidatedRecord copyWith({
    String? zona,
    String? estado,
    int? approvedSeconds,
    String? reviewNote,
    String? reviewedBy,
    String? reviewedAt,
  }) {
    return ConsolidatedRecord(
      journeyId: journeyId,
      workerId: workerId,
      colaborador: colaborador,
      cedula: cedula,
      cargo: cargo,
      zona: zona ?? this.zona,
      fecha: fecha,
      fechaFormatted: fechaFormatted,
      entrada: entrada,
      salida: salida,
      entradaDateTime: entradaDateTime,
      salidaDateTime: salidaDateTime,
      horas: horas,
      extras: extras,
      estado: estado ?? this.estado,
      approvedSeconds: approvedSeconds ?? this.approvedSeconds,
      reviewNote: reviewNote ?? this.reviewNote,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rawDay: rawDay,
    );
  }
}
