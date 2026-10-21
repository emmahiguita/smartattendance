/// Identidad del encargado guardada en el dispositivo. No equivale a una
/// autenticación central de empresa; el teléfono debe permanecer bajo su control.
class LocalActor {
  const LocalActor(this.document, this.isAdmin);
  final String document;
  final bool isAdmin;
  String visibleWorkers(String column) => isAdmin
      ? '1'
      : '''($column IN (
    SELECT w.id FROM workers w JOIN crews c ON c.id=w.crew_id
    WHERE c.supervisor_document=? OR c.driver_document=?)
    OR (SELECT COUNT(*) FROM crews) = 0
    OR (SELECT crew_id FROM workers WHERE id=$column) IS NULL)''';
  List<Object?> get visibilityArgs => isAdmin ? [] : [document, document];
}
