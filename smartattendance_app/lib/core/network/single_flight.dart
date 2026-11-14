// QUÉ HACE: Comparte una operación pendiente entre solicitudes concurrentes.
// CÓMO: Conserva el Future hasta terminar y libera el estado incluso al fallar.
// POR QUÉ: Un refresco de un solo uso no se debe enviar varias veces.
class SingleFlight<T> {
  Future<T>? _pending;
  Future<T> run(Future<T> Function() operation) {
    final active = _pending;
    if (active != null) return active;
    late Future<T> current;
    current = Future<T>.sync(operation).whenComplete(() {
      if (identical(_pending, current)) _pending = null;
    });
    _pending = current;
    return current;
  }
}
