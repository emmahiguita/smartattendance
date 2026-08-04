// lib/features/qr/domain/repositories/qr_repository.dart

/// Resultado de validación de un QR — el servidor decide todo.
/// `tipo` viene del servidor: el dispositivo no elige entrada/salida (C2).
typedef QRValidationResult = ({
  int userId,
  String tipo,
  String? fechaRegistro,
  String? horaRegistro,
});

/// Interface for QR Repository.
/// Dependency Inversion Principle (DIP): ViewModels and UseCases depend on this abstraction,
/// not on the concrete QRRepositoryImpl.
abstract interface class QRRepository {
  Future<QRValidationResult> validateQR(String code);

  /// Genera un código QR nuevo para [userId]. Requiere rol admin (server-side).
  Future<String> generateQR(int userId);
}
