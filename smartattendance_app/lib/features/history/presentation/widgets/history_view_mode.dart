// lib/features/history/presentation/widgets/history_view_mode.dart

/// ============================================================================
/// ENUM: HistoryViewMode (Modos de Visualización de Historial)
/// ============================================================================
/// QUÉ HACE:
/// Define las 3 modalidades de exploración de asistencias laborales:
/// 1. [calendar]: Cuadrícula mensual interactiva estilo Apple Calendar.
/// 2. [timeline]: Agenda horaria diaria estilo Google Calendar con Google Meet.
/// 3. [list]: Lista continua agrupada cronológicamente con filtros por tipo.
///
/// CÓMO FUNCIONA:
/// Utilizado como estado de visualización por [IosAttendanceCalendar] para
/// permutar fluidamente entre componentes especializados sin acoplamiento.
///
/// POR QUÉ:
/// Desacopla el tipo de vista de la lógica de renderizado, permitiendo
/// agregar nuevas vistas (ej. trimestral, anual) sin romper las existentes.
///
/// PRINCIPIOS SOLID:
/// - O (Open/Closed): Abierto a extensión para nuevos modos de auditoría.
/// ============================================================================
enum HistoryViewMode {
  calendar,
  timeline,
  list,
}
