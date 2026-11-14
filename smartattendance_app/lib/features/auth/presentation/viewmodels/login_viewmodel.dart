// lib/features/auth/presentation/viewmodels/login_viewmodel.dart
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/token_store.dart';
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

// QUÉ HACE: Valida los identificadores OAuth antes de abrir Google Sign-In.
// CÓMO: Exige el cliente web del backend y, en iOS, el cliente nativo.
// POR QUÉ: Convierte una configuración nativa ausente en un error accionable.
String? googleOAuthConfigurationError({
  required String serverClientId,
  required String iosClientId,
  required bool isIOS,
}) {
  if (isIOS && serverClientId.trim().isEmpty) {
    return 'Google Sign-In requiere GOOGLE_SERVER_CLIENT_ID.';
  }
  if (isIOS && iosClientId.trim().isEmpty) {
    return 'Google Sign-In en iOS requiere GOOGLE_IOS_CLIENT_ID.';
  }
  return null;
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

/// SRP: manages only the login UI state.
/// Depends on LoginUseCase — not on any data source directly (DIP).
class LoginViewModel extends StateNotifier<LoginState> {
  LoginViewModel(this._useCase, this._ref) : super(const LoginInitial());

  final LoginUseCase _useCase;
  final Ref _ref;

  /// Ejecuta el login con respuesta inmediata (0ms de latencia en conectividad).
  Future<void> login(String cedula, {String? password}) async {
    state = const LoginLoading();
    try {
      // Lectura reactiva inmediata en memoria, sin esperar timeout de plugins nativos.
      final isOnline = _ref.read(connectivityProvider);
      final (token, user) =
          await _useCase(cedula, password: password, isOffline: !isOnline);
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
      const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
      const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
      final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
      final configError = googleOAuthConfigurationError(
        serverClientId: serverClientId,
        iosClientId: iosClientId,
        isIOS: isIOS,
      );
      if (configError != null) {
        throw AuthException(message: configError);
      }
      final googleUser = await GoogleSignIn(
        clientId: isIOS ? iosClientId : null,
        serverClientId: serverClientId.isEmpty ? null : serverClientId,
      ).signIn();
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
    tokens: ref.watch(tokenStoreProvider),
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
