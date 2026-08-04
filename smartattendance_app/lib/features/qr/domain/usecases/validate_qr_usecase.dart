// lib/features/qr/domain/usecases/validate_qr_usecase.dart
import '../repositories/qr_repository.dart';

final class ValidateQRUseCase {
  const ValidateQRUseCase(this._repository);

  final QRRepository _repository;

  Future<QRValidationResult> call(String qrCode) async {
    if (qrCode.trim().isEmpty) {
      throw ArgumentError('El código QR está vacío.');
    }
    return _repository.validateQR(qrCode.trim());
  }
}
