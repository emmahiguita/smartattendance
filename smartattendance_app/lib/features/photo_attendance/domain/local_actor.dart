// ============================================================================
// ARCHIVO: local_actor.dart
// QUÉ HACE: Define la identidad y la jerarquía de 3 roles (RBAC) del operador:
//           1. `Administrador` (`isAdmin = true`, `isStrictAdmin = true`):
//              Control total de RRHH, zonas, cuadrillas, bajas y servidor.
//           2. `Supervisor` (`isAdmin = true`, `isStrictAdmin = false`,
//              `isSupervisor = true`): Supervisa cuadrilla, asigna turnos y
//              Horas Extras Asignadas y afilia operarios.
//           3. `Colaborador` (`isAdmin = false`): Marca sus 4 etapas del día,
//              ve su geocerca GPS y su marcador de Horas Extras Asignadas.
// POR QUÉ: Audita y separa formalmente las responsabilidades de cada rol (< 40 líneas).
// ============================================================================

class LocalActor {
  const LocalActor(
    this.document,
    this.isAdmin, {
    this.isStrictAdmin = false,
    this.isSupervisor = false,
  });

  final String document;
  final bool isAdmin;
  final bool isStrictAdmin;
  final bool isSupervisor;

  String visibleWorkers(String column) => isAdmin
      ? '1'
      : '''($column IN (
    SELECT w.id FROM workers w LEFT JOIN crews c ON c.id=w.crew_id
    WHERE w.document=? OR c.supervisor_document=? OR c.driver_document=?))''';

  List<Object?> get visibilityArgs =>
      isAdmin ? [] : [document, document, document];
}
