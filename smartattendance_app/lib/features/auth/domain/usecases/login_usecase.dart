// lib/features/auth/domain/usecases/login_usecase.dart
import 'package:smartattendance/core/validators/input_validators.dart';

import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case: authenticate a user by cédula (+password when the account has one).
/// SRP: does one thing — delegates login to repository.
/// DIP: depends on AuthRepository interface.
final class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  /// Execute the login flow.
  /// [cedula] must be valid per InputValidators.
  Future<(String token, UserEntity user)> call(String cedula,
      {String? password}) async {
    final validationError = InputValidators.validateCedula(cedula);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    return _repository.loginByCedula(cedula.trim(), password: password);
  }

  /// Login con Google: delega en el repositorio (el id_token lo verifica el
  /// servidor contra el client ID configurado).
  Future<(String token, UserEntity user)> googleLogin(String idToken) async {
    return _repository.googleLogin(idToken);
  }
}
