import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/core/localstore/local_database_service.dart';
import 'package:smartattendance/features/messaging/data/messaging_repository.dart';
import 'package:smartattendance/features/messaging/presentation/messages_screen.dart';

class FakeMessagingRepository extends MessagingRepository {
  FakeMessagingRepository() : super(Dio(), LocalDatabaseService());

  final sent = <InternalMessage>[];

  @override
  Future<List<MessageContact>> contacts() async => const [
        MessageContact(
          id: 2,
          nombre: 'María Fernanda',
          apellido: 'González Rodríguez',
          cargo: 'Coordinadora de Operaciones',
          unreadCount: 2,
          lastMessage: 'Revisa el informe del equipo',
        ),
        MessageContact(
          id: 3,
          nombre: 'Carlos',
          apellido: 'Pérez',
          cargo: 'Analista',
          unreadCount: 0,
        ),
      ];

  @override
  Future<List<InternalMessage>> conversation(int id) async => [
        InternalMessage(
          id: 1,
          senderId: id,
          recipientId: 99,
          body: 'Buenos días, ¿podemos revisar el reporte?',
          createdAt: DateTime(2026, 8, 3, 9),
        ),
        ...sent,
      ];

  @override
  Future<int> markConversationRead(int contactId) async => 2;

  @override
  Future<InternalMessage> send(int id, String body) async {
    final message = InternalMessage(
      id: 10,
      senderId: 99,
      recipientId: id,
      body: body,
      createdAt: DateTime(2026, 8, 3, 10),
    );
    sent.add(message);
    return message;
  }
}

Widget app(FakeMessagingRepository repository) => ProviderScope(
      overrides: [messagingRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: MessagesScreen()),
    );

void main() {
  testWidgets(
      'Mensajería móvil 360px: contactos, conversación y envío sin overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeMessagingRepository();
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();

    expect(find.text('María Fernanda González Rodríguez'), findsOneWidget);
    await tester.tap(find.text('María Fernanda González Rodríguez'));
    await tester.pumpAndSettle();

    expect(
        find.text('Buenos días, ¿podemos revisar el reporte?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Mensaje de prueba');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Mensaje de prueba'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mensajería escritorio 1200px muestra panel doble sin overflow',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(FakeMessagingRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona un empleado'), findsOneWidget);
    expect(find.text('María Fernanda González Rodríguez'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
