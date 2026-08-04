// lib/features/profile/presentation/viewmodels/edit_profile_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';

sealed class EditProfileState {
  const EditProfileState();
}

final class EditProfileIdle extends EditProfileState {
  const EditProfileIdle();
}

final class EditProfileSaving extends EditProfileState {
  const EditProfileSaving();
}

final class EditProfileSuccess extends EditProfileState {
  const EditProfileSuccess(this.user);
  final UserEntity user;
}

final class EditProfileError extends EditProfileState {
  const EditProfileError(this.message);
  final String message;
}

class EditProfileViewModel extends StateNotifier<EditProfileState> {
  EditProfileViewModel(this._repository) : super(const EditProfileIdle());

  final ProfileRepository _repository;

  Future<UserEntity?> save({
    required String nombre,
    required String apellido,
    required String correo,
    String? fechaNacimiento,
    String? telefono,
    String? direccion,
  }) async {
    state = const EditProfileSaving();
    try {
      final user = await _repository.updateProfile(
        nombre: nombre.trim(),
        apellido: apellido.trim(),
        correo: correo.trim(),
        fechaNacimiento: fechaNacimiento?.trim(),
        telefono: telefono?.trim(),
        direccion: direccion?.trim(),
      );
      state = EditProfileSuccess(user);
      return user;
    } on AppException catch (e) {
      state = EditProfileError(e.message);
      return null;
    } catch (e) {
      final appError = ErrorHandler.handle(e);
      state = EditProfileError(appError.message);
      return null;
    }
  }

  void reset() => state = const EditProfileIdle();

  /// Sube la foto de perfil. Retorna el usuario actualizado con la nueva URL.
  Future<UserEntity?> uploadPhoto(String filePath) async {
    state = const EditProfileSaving();
    try {
      final user = await _repository.uploadPhoto(filePath);
      state = EditProfileSuccess(user);
      return user;
    } on AppException catch (e) {
      state = EditProfileError(e.message);
      return null;
    } catch (e) {
      state = EditProfileError(ErrorHandler.handle(e).message);
      return null;
    }
  }
}

final _profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => ProfileRemoteDataSource(ref.watch(dioProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(_profileRemoteDataSourceProvider)),
);

final editProfileViewModelProvider =
    StateNotifierProvider<EditProfileViewModel, EditProfileState>(
  (ref) => EditProfileViewModel(ref.watch(profileRepositoryProvider)),
);
