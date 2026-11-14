// ============================================================================
// ARCHIVO: traccar_url_policy.dart
// QUÉ HACE: Centraliza la política de transporte del servidor Traccar.
// CÓMO FUNCIONA: Normaliza HTTPS, permite HTTP local y migra valores antiguos.
// POR QUÉ: Mantiene la seguridad de red separada del cliente de telemetría.
// ============================================================================

final class TraccarUrlPolicy {
  const TraccarUrlPolicy._();

  static const defaultServerUrl = '';
  static const _localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};

  static String normalize(String value) {
    final clean = value.trim();
    final candidate = clean.contains('://') ? clean : 'https://$clean';
    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.host.isEmpty) {
      throw const FormatException('URL de Traccar inválida.');
    }
    if (uri.scheme == 'http' && !_localHosts.contains(uri.host.toLowerCase())) {
      throw const FormatException(
        'Traccar requiere HTTPS fuera del entorno local.',
      );
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const FormatException('Traccar requiere una URL HTTP o HTTPS.');
    }
    return uri.toString();
  }

  static String? fromStored(String? value) {
    final clean = value?.trim() ?? '';
    if (clean.isEmpty) return null;
    try {
      return normalize(clean);
    } on FormatException {
      return null;
    }
  }
}
