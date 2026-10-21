import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/session_controller.dart';
import '../data/legacy_local_reader.dart';
import '../../attendance/domain/entities/attendance_entity.dart';
import 'local_providers.dart';

/// Alimenta las mismas tarjetas del diseño original con marcas locales reales.
/// Conserva historial anterior del dispositivo y añade las nuevas fotos del
/// encargado por cédula; los demás trabajadores se consultan en su historial.
final localDayHistoryProvider =
    FutureProvider<List<AttendanceEntity>>((ref) async {
  final session = ref.watch(sessionControllerProvider);
  if (session is! SessionAuthenticated) return [];
  final user = session.user;
  final records = <AttendanceEntity>[];
  final legacy = await LegacyLocalReader().history(user.id,user.cedula);
  for (final row in legacy) {
    final date = DateTime.parse(row['fecha'] as String).toLocal();
    final parts = (row['hora'] as String).split(':');
    records.add(AttendanceEntity(
        id: row['id'] as int,
        usuarioId: user.id,
        fecha: date,
        hora: DateTime(date.year, date.month, date.day, int.parse(parts[0]),
            int.parse(parts[1])),
        tipo: row['tipo'] as String));
  }
  final repository = ref.watch(localPhotoRepositoryProvider);
  var skip = 0;
  while (true) {
    final rows =
        await repository.history(skip: skip, search: user.cedula, limit: 100);
    for (final row in rows.where((r) => r.document == user.cedula)) {
      records.add(AttendanceEntity(
          id: -(skip + records.length + 1),
          usuarioId: user.id,
          fecha: row.capturedAt,
          hora: row.capturedAt,
          tipo: row.type));
    }
    if (rows.length < 100) break;
    skip += 100;
  }
  return records..sort((a, b) => b.hora.compareTo(a.hora));
});
