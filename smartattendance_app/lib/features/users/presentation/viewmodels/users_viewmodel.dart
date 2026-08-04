// lib/features/users/presentation/viewmodels/users_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/users_remote_datasource.dart';
import '../../data/repositories/users_repository_impl.dart';
import '../../domain/repositories/users_repository.dart';

final usersViewModelProvider = FutureProvider<List<UserEntity>>((ref) {
  final repository = ref.watch(usersRepositoryProvider);
  return repository.listAll();
});

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepositoryImpl(
    UsersRemoteDataSource(ref.watch(dioProvider)),
  );
});
