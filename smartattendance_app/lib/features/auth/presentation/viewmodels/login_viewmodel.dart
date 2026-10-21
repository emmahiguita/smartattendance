// lib/features/auth/presentation/viewmodels/login_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/localstore/local_database_service.dart';
import '../../../../core/localstore/secure_storage_provider.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class LoginState {
  const LoginState();
}

final class LoginInitial extends LoginState {
  const LoginInitial();
}

final class LoginLoading extends LoginState {
  const LoginLoading();
}

final class LoginSuccess extends LoginState {
  const LoginSuccess({
    required this.token,
    required this.user,
  });

  /// Access token emitido por el servidor — lo usa la pantalla para la
  /// sesión efímera (Recordar sesión desmarcado).
  final String token;
  final UserEntity user;
}

final class LoginError extends LoginState {
  const LoginError(this.message);
  final String message;
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

/// SRP: manages only the login UI state.
/// Depends on LoginUseCase — not on any data source directly (DIP).
class LoginViewModel extends StateNotifier<LoginState> {
  LoginViewModel(this._useCase, this._ref) : super(const LoginInitial());

  final LoginUseCase _useCase;
  final Ref _ref;

  /// Ejecuta el login. [remember] se propaga al SessionController desde la
  /// pantalla (LoginSuccess lleva el token para la sesión efímera).
  Future<void> login(String cedula, {String? password}) async {
    state = const LoginLoading();
    try {
      // Si NO hay internet, login local instantáneo — sin esperar timeout.
      final isOffline = !_ref.read(connectivityProvider);
      final (token, user) = await _useCase(cedula, password: password, isOffline: isOffline);
      state = LoginSuccess(token: token, user: user);
    } catch (e) {
      final appError = ErrorHandler.handle(e);
      state = LoginError(appError.message);
    }
  }

  /// Login con Google: obtiene el id_token y lo envía al servidor.
  /// El token de Google jamás se guarda localmente — solo los JWT propios.
  Future<void> loginWithGoogle() async {
    state = const LoginLoading();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // El usuario canceló el diálogo de Google — volver al estado inicial.
        state = const LoginInitial();
        return;
      }
      final idToken =
          await googleUser.authentication.then((auth) => auth.idToken);
      if (idToken == null) {
        throw AuthException(
            message: 'Google no entregó un token de identidad.');
      }

      final (token, user) = await _useCase.googleLogin(idToken);
      state = LoginSuccess(token: token, user: user);
    } catch (e) {
      final appError = ErrorHandler.handle(e);
      state = LoginError(appError.message);
    }
  }

  void reset() => state = const LoginInitial();
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(dioProvider)),
);

/// Público: register y forgot-password lo reutilizan (mismo Dio y storage).
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remoteDataSource: ref.watch(_authRemoteDataSourceProvider),
    storage: ref.watch(secureStorageProvider),
    localDb: ref.watch(localDatabaseServiceProvider),
  ),
);

final _loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

/// Public provider — screens depend only on this.
final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginState>(
  (ref) => LoginViewModel(ref.watch(_loginUseCaseProvider), ref),
);
