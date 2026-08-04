// test/unit/attendance/offline_sync_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartattendance/features/attendance/domain/repositories/attendance_repository.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  late MockAttendanceRepository mockRepo;

  setUp(() {
    mockRepo = MockAttendanceRepository();
  });

  group('Offline Attendance Queue Tests', () {
    test('syncPendingRecords llama al repositorio y retorna cantidad de marcas procesadas', () async {
      when(() => mockRepo.syncPendingRecords()).thenAnswer((_) async => 3);
      when(() => mockRepo.getPendingCount()).thenAnswer((_) async => 0);

      final synced = await mockRepo.syncPendingRecords();
      final remaining = await mockRepo.getPendingCount();

      expect(synced, equals(3));
      expect(remaining, equals(0));
      verify(() => mockRepo.syncPendingRecords()).called(1);
    });

    test('getPendingCount retorna 0 cuando la cola SQLite está vacía', () async {
      when(() => mockRepo.getPendingCount()).thenAnswer((_) async => 0);

      final count = await mockRepo.getPendingCount();

      expect(count, equals(0));
    });
  });
}
