// lib/features/qr/presentation/viewmodels/qr_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/qr_remote_datasource.dart';
import '../../data/repositories/qr_repository_impl.dart';
import '../../domain/repositories/qr_repository.dart';
import '../../domain/usecases/validate_qr_usecase.dart';

sealed class QRState {
  const QRState();
}

final class QRInitial extends QRState {
  const QRInitial();
}

final class QRLoading extends QRState {
  const QRLoading();
}

/// Validación exitosa: el servidor registró la asistencia y decidió el tipo.
final class QRSuccess extends QRState {
  const QRSuccess({
    required this.userId,
    required this.tipo,
    this.fechaRegistro,
    this.horaRegistro,
  });

  final int userId;
  final String tipo; // 'entrada' | 'salida' — decidido por el servidor (C2)
  final String? fechaRegistro; // YYYY-MM-DD
  final String? horaRegistro; // HH:MM:SS
}

final class QRError extends QRState {
  const QRError(this.message);
  final String message;
}

class QRViewModel extends StateNotifier<QRState> {
  QRViewModel(this._useCase) : super(const QRInitial());

  final ValidateQRUseCase _useCase;

  Future<void> validateQR(String code) async {
    state = const QRLoading();
    try {
      final result = await _useCase(code);
      state = QRSuccess(
        userId: result.userId,
        tipo: result.tipo,
        fechaRegistro: result.fechaRegistro,
        horaRegistro: result.horaRegistro,
      );
    } on AppException catch (e) {
      state = QRError(e.message);
    } catch (e) {
      state = QRError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void reset() => state = const QRInitial();
}

final _qrRemoteDataSourceProvider = Provider<QRRemoteDataSource>(
  (ref) => QRRemoteDataSource(ref.watch(dioProvider)),
);

/// Público: compartido por el escáner y el panel admin para generar códigos.
final qrRepositoryProvider = Provider<QRRepository>(
  (ref) => QRRepositoryImpl(ref.watch(_qrRemoteDataSourceProvider)),
);

final _validateQRUseCaseProvider = Provider<ValidateQRUseCase>(
  (ref) => ValidateQRUseCase(ref.watch(qrRepositoryProvider)),
);

final qrViewModelProvider = StateNotifierProvider<QRViewModel, QRState>(
  (ref) => QRViewModel(ref.watch(_validateQRUseCaseProvider)),
);
