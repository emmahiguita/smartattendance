// lib/features/photo_attendance/domain/face_verifier.dart

/// ============================================================================
/// PUERTO DE DOMINIO: FaceVerifier
/// ============================================================================
/// QUÉ HACE:
/// Define el contrato "¿esta foto contiene un rostro humano válido?".
///
/// CÓMO FUNCIONA:
/// La implementación real ([MlKitFaceVerifier], capa data) analiza la imagen
/// en el dispositivo. Si la foto NO sirve, lanza [FormatException] con un
/// mensaje listo para mostrar al usuario; si sirve, termina sin error.
///
/// POR QUÉ:
/// - DIP (SOLID): la pantalla depende de esta interfaz, no de ML Kit.
///   Mañana se puede cambiar el motor (p. ej. un modelo TFLite de
///   identidad) sin tocar la UI.
/// - Honestidad: esto es DETECCIÓN de rostro (hay una cara real, una sola,
///   con ojos abiertos). NO es identificación 1:1 contra una foto enrolada.
/// ============================================================================
abstract interface class FaceVerifier {
  /// Valida la foto en [imagePath]. Lanza [FormatException] si no es válida.
  Future<void> verify(String imagePath);
}
