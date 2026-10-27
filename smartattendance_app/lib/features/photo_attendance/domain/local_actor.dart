// ============================================================================
// ARCHIVO: local_actor.dart
// QUÉ HACE: Define la identidad y el alcance de visibilidad de datos (RBAC)
//           del operador autenticado en el dispositivo.
// CÓMO FUNCIONA: Si `isAdmin` es verdadero, tiene visibilidad global (`'1'`).
//                Si es colaborador o supervisor de cuadrilla, restringe las
//                consultas SQL exclusivamente a su propia cédula (`w.document`)
//                o al personal de la cuadrilla a su cargo (`supervisor_document`).
// POR QUÉ: Aísla los datos entre empleados y evita fugas de información (< 35 líneas).
// ============================================================================

class LocalActor {
  const LocalActor(this.document, this.isAdmin);
  final String document;
  final bool isAdmin;

  String visibleWorkers(String column) => isAdmin
      ? '1'
      : '''($column IN (
    SELECT w.id FROM workers w LEFT JOIN crews c ON c.id=w.crew_id
    WHERE w.document=? OR c.supervisor_document=? OR c.driver_document=?))''';

  List<Object?> get visibilityArgs =>
      isAdmin ? [] : [document, document, document];
}
