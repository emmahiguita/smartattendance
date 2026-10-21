// lib/features/photo_attendance/data/mlkit_face_verifier.dart
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../domain/face_verifier.dart';

/// ============================================================================
/// ADAPTADOR REAL: MlKitFaceVerifier (Google ML Kit, 100 % en el dispositivo)
/// ============================================================================
/// QUÉ HACE:
/// Analiza la foto tomada con la cámara frontal y exige:
///   1. Que exista un rostro (no se acepta una foto de pared, techo, etc.).
///   2. Que haya UN solo rostro (evita marcar por otra persona en grupo).
///   3. Que el rostro ocupe un tamaño mínimo (cara cerca, no al fondo).
///   4. Que los ojos estén abiertos (filtro básico contra fotos de fotos
///      impresas borrosas o capturas con los ojos cerrados).
///
/// CÓMO FUNCIONA:
/// Crea un [FaceDetector] por análisis y lo CIERRA en `finally`. Cerrarlo
/// libera el modelo nativo: si no se cerrara quedaría un proceso/recurso
/// "zombi" consumiendo memoria tras cada marcación.
///
/// POR QUÉ:
/// Sin internet ni servidor: ML Kit trae el modelo embebido en la app.
/// ============================================================================
class MlKitFaceVerifier implements FaceVerifier {
  const MlKitFaceVerifier();

  /// Probabilidad mínima (0..1) para considerar un ojo "abierto".
  static const _eyeOpenMin = 0.25;

  @override
  Future<void> verify(String imagePath) async {
    // accurate: prioriza precisión sobre velocidad (es UNA foto, no video).
    // enableClassification: activa las probabilidades de ojos abiertos.
    // minFaceSize 0.15: la cara debe ocupar al menos el 15 % de la imagen.
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableClassification: true,
        minFaceSize: 0.15,
      ),
    );
    try {
      final faces =
          await detector.processImage(InputImage.fromFilePath(imagePath));

      // Regla 1: sin rostro no hay marcación.
      if (faces.isEmpty) {
        throw const FormatException(
            'No se detectó un rostro. Mira de frente a la cámara con buena luz.');
      }
      // Regla 2: un solo rostro por marcación.
      if (faces.length > 1) {
        throw const FormatException(
            'Hay más de un rostro en la foto. Debe aparecer solo el trabajador.');
      }
      // Regla 4: ojos abiertos. Si ML Kit no pudo calcularlo (null) no se
      // bloquea, para no rechazar fotos válidas por falta de dato.
      final face = faces.single;
      final left = face.leftEyeOpenProbability;
      final right = face.rightEyeOpenProbability;
      if (left != null && right != null &&
          left < _eyeOpenMin && right < _eyeOpenMin) {
        throw const FormatException(
            'Los ojos aparecen cerrados. Abre los ojos y vuelve a intentarlo.');
      }
    } finally {
      await detector.close(); // Libera el modelo nativo (evita fugas).
    }
  }
}
