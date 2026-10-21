import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/photo_database.dart';
import '../data/photo_repository.dart';
import '../data/device_attendance_location.dart';
import '../data/mlkit_face_verifier.dart';
import '../domain/attendance_location.dart';
import '../domain/face_verifier.dart';
import '../domain/photo_record.dart';
import '../domain/shift_template.dart';
import '../data/local_admin_store.dart';
import '../../../../core/auth/session_controller.dart';
import '../domain/local_actor.dart';
import 'admin_access.dart';

/// Composition root local: una conexión compartida; ningún proveedor usa Dio,
/// tokens o conectividad. La base vive durante la aplicación, no cada pantalla.
final localPhotoDatabaseProvider = Provider((ref) => PhotoDatabase());
final localActorProvider = Provider((ref) {
  final session = ref.watch(sessionControllerProvider);
  return session is SessionAuthenticated
      ? LocalActor(session.user.cedula,
          session.user.isAdmin || ref.watch(adminAccessProvider))
      : const LocalActor('', false);
});
final localAdminStoreProvider = Provider((ref) {
  final actor = ref.watch(localActorProvider);
  final admin = actor.isAdmin ? actor.document : null;
  return LocalAdminStore(ref.watch(localPhotoDatabaseProvider), admin);
});
final localPhotoRepositoryProvider = Provider<LocalAttendanceRepository>(
    (ref) => PhotoRepository(
        ref.watch(localPhotoDatabaseProvider), ref.watch(localActorProvider)));

/// Sensor GPS real (puerto de dominio → adaptador Geolocator). La pantalla de
/// captura lo pide EN PARALELO con la cámara para no sumar esperas.
final localLocationSourceProvider =
    Provider<AttendanceLocationSource>((_) => const DeviceAttendanceLocation());

/// Detector facial real en el dispositivo (Google ML Kit). Sustituible por
/// otro motor sin tocar la UI gracias a la interfaz [FaceVerifier].
final localFaceVerifierProvider =
    Provider<FaceVerifier>((_) => const MlKitFaceVerifier());

/// Invalidar tras crear trabajadores refresca sus consumidores automáticamente.
final localWorkersProvider = FutureProvider<List<LocalWorker>>(
    (ref) => ref.watch(localPhotoRepositoryProvider).workers());

/// Plantillas de turnos configuradas en SQLite
final shiftTemplatesProvider = FutureProvider<List<ShiftTemplate>>((ref) async {
  final store = ref.watch(localAdminStoreProvider);
  await store.ensureDefaultData();
  return store.shiftTemplates();
});

/// Bandeja global de jornadas con horas extras
final allOvertimeDaysProvider = FutureProvider<List<PhotoDay>>((ref) async {
  final store = ref.watch(localAdminStoreProvider);
  return store.allOvertimeDays();
});

