// ============================================================================
// ARCHIVO: local_providers.dart
// QUÉ HACE: Raíz de composición Riverpod para base de datos SQLite, identidad
//           del operador (`LocalActor`), almacén administrativo (`LocalAdminStore`),
//           sensor GPS real y verificador biométrico facial.
// CÓMO FUNCIONA: Vincula el estado de sesión (`sessionControllerProvider`) y
//                el desbloqueo por PIN (`adminAccessProvider`) para restringir
//                estrictamente las operaciones administrativas (`adminDocument = null`
//                cuando el usuario no es Administrador ni Supervisor).
// POR QUÉ: Garantiza control de acceso basado en roles (RBAC) real (< 90 líneas).
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/session_controller.dart';
import '../../auth/data/datasources/local_auth_datasource.dart';
import '../data/device_attendance_location.dart';
import '../data/local_admin_store.dart';
import '../data/mlkit_face_verifier.dart';
import '../data/photo_database.dart';
import '../data/photo_repository.dart';
import '../domain/attendance_location.dart';
import '../domain/face_verifier.dart';
import '../domain/local_actor.dart';
import '../domain/photo_record.dart';
import '../domain/shift_template.dart';
import 'admin_access.dart';

final localPhotoDatabaseProvider = Provider((ref) => PhotoDatabase());

final localActorProvider = Provider((ref) {
  final session = ref.watch(sessionControllerProvider);
  final unlocked = ref.watch(adminAccessProvider);
  if (session is SessionAuthenticated) {
    final u = session.user;
    final isAdm =
        u.isAdmin || LocalAuthDataSource.isRoleAdmin(u.cargo, u.cedula) || unlocked;
    return LocalActor(u.cedula, isAdm);
  }
  return LocalActor('', unlocked);
});

final localAdminStoreProvider = Provider((ref) {
  final actor = ref.watch(localActorProvider);
  final admin = actor.isAdmin
      ? (actor.document.isNotEmpty ? actor.document : '1007331963')
      : null;
  return LocalAdminStore(ref.watch(localPhotoDatabaseProvider), admin);
});

final localPhotoRepositoryProvider = Provider<LocalAttendanceRepository>(
    (ref) => PhotoRepository(
        ref.watch(localPhotoDatabaseProvider), ref.watch(localActorProvider)));

final localLocationSourceProvider =
    Provider<AttendanceLocationSource>((_) => const DeviceAttendanceLocation());

final localFaceVerifierProvider =
    Provider<FaceVerifier>((_) => const MlKitFaceVerifier());

final localWorkersProvider = FutureProvider<List<LocalWorker>>(
    (ref) => ref.watch(localPhotoRepositoryProvider).workers());

final shiftTemplatesProvider = FutureProvider<List<ShiftTemplate>>((ref) async {
  final store = ref.watch(localAdminStoreProvider);
  await store.ensureDefaultData();
  return store.shiftTemplates();
});

final allOvertimeDaysProvider = FutureProvider<List<PhotoDay>>((ref) async {
  final store = ref.watch(localAdminStoreProvider);
  return store.allOvertimeDays();
});

final allReportDaysProvider = FutureProvider<List<PhotoDay>>((ref) async {
  final repo = ref.watch(localPhotoRepositoryProvider);
  return repo.days(limit: 100);
});
