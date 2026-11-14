// ============================================================================
// ARCHIVO: traccar_sync_result.dart
// QUÉ HACE: Representa el resultado inmutable de una sincronización GPS.
// CÓMO FUNCIONA: Agrupa estado, servidor, mensaje y hora del intento.
// POR QUÉ: Separa el contrato de datos del cliente de red Traccar.
// ============================================================================

class TraccarSyncResult {
  final bool ok;
  final String serverUrl;
  final String statusText;
  final DateTime syncedAt;

  const TraccarSyncResult({
    required this.ok,
    required this.serverUrl,
    required this.statusText,
    required this.syncedAt,
  });
}
