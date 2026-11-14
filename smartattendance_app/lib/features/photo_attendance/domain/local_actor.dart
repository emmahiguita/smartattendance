// ============================================================================
// ARCHIVO: local_actor.dart
// QUÉ HACE: Define la identidad y la jerarquía de 3 roles (RBAC) del operador:
//           1. `Administrador` (`isAdmin = true`, `isStrictAdmin = true`):
//              Control total de RRHH, zonas, cuadrillas, puestos, bajas y servidor.
//           2. `Supervisor` (`isAdmin = true`, `isStrictAdmin = false`,
//              `isSupervisor = true`): Supervisa cuadrilla, asigna turnos y
//              Horas Extras Asignadas y afilia operadores, colaboradores y operarios.
//           3. `Colaborador` (`isAdmin = false`): Marca sus 4 etapas del día,
//              ve su geocerca GPS y su marcador de Horas Extras Asignadas.
// POR QUÉ: Audita y separa formalmente las responsabilidades de cada rol (< 55 líneas).
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

  /// QUÉ HACE: Autoriza altas según rol/puesto y pertenencia al equipo.
  /// CÓMO: Permite al Administrador cualquier rol y al Supervisor los puestos
  ///       operativos base (`Operador`, `Colaborador`, `Operario`, `Promotor`,
  ///       `Técnico de Campo`, `Auxiliar Operativo`, `Conductor`) más los
  ///       puestos creados por el Administrador (`customAllowed`).
  /// POR QUÉ: La interfaz no es una barrera de autorización suficiente.
  bool canCreateWorker(
    String role, {
    required bool ownsCrew,
    Iterable<String> customAllowed = const [],
  }) {
    if (isStrictAdmin) return true;
    const allowed = {
      'operador',
      'colaborador',
      'operario',
      'promotor',
      'técnico de campo',
      'auxiliar operativo',
      'conductor',
    };
    final clean = role.trim().toLowerCase();
    final isCustom = customAllowed.any(
      (c) =>
          c.trim().toLowerCase() == clean &&
          clean != 'administrador' &&
          clean != 'supervisor',
    );
    return isSupervisor && ownsCrew && (allowed.contains(clean) || isCustom);
  }

  String visibleWorkers(String column) => isStrictAdmin
      ? '1'
      : '''($column IN (
    SELECT w.id FROM workers w LEFT JOIN crews c ON c.id=w.crew_id
    WHERE w.document=? OR c.supervisor_document=? OR c.driver_document=?))''';

  List<Object?> get visibilityArgs =>
      isStrictAdmin ? [] : [document, document, document];
}
