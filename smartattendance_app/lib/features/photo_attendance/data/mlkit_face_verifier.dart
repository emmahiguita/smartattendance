// ============================================================================
// ARCHIVO: mlkit_face_verifier.dart
// QUÉ HACE: Verificador biométrico facial multiplataforma:
//           - En Android e iOS ejecuta Google ML Kit (`FaceDetector`) 100% on-device.
//           - En escritorio (Windows/macOS/Linux) valida integridad y resolución
//             real del archivo de imagen decodificado (`image`).
// CÓMO FUNCIONA: Crea `FaceDetector` en móvil y lo cierra en `finally` para
//                evitar procesos zombi; en escritorio decodifica bytes reales.
// POR QUÉ: Evita `MissingPluginException` en Windows Desktop (< 95 líneas).
// ============================================================================

import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../domain/face_verifier.dart';

class MlKitFaceVerifier implements FaceVerifier {
  const MlKitFaceVerifier();

  static const _eyeOpenMin = 0.25;

  @override
  Future<void> verify(String imagePath) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      final file = File(imagePath);
      if (!file.existsSync() || file.lengthSync() == 0) {
        throw const FormatException('No se encontró la fotografía capturada.');
      }
      final decoded = img.decodeImage(await file.readAsBytes());
      if (decoded == null || decoded.width < 120 || decoded.height < 120) {
        throw const FormatException(
            'La imagen seleccionada no tiene resolución válida para evidencia.');
      }
      return;
    }

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
      if (faces.isEmpty) {
        throw const FormatException(
            'No se detectó un rostro. Mira de frente a la cámara con buena luz.');
      }
      if (faces.length > 1) {
        throw const FormatException(
            'Hay más de un rostro en la foto. Debe aparecer solo el trabajador.');
      }
      final face = faces.single;
      final left = face.leftEyeOpenProbability;
      final right = face.rightEyeOpenProbability;
      if (left != null &&
          right != null &&
          left < _eyeOpenMin &&
          right < _eyeOpenMin) {
        throw const FormatException(
            'Los ojos aparecen cerrados. Abre los ojos y vuelve a intentarlo.');
      }
    } finally {
      await detector.close();
    }
  }
}
