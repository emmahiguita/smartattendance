import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localstore/local_database_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/dio_provider.dart';

class MessageContact {
  const MessageContact(
      {required this.id,
      required this.nombre,
      required this.apellido,
      required this.cargo,
      required this.unreadCount,
      this.lastMessage});
  final int id;
  final String nombre, apellido, cargo;
  final int unreadCount;
  final String? lastMessage;
  String get fullName => '$nombre $apellido'.trim();
  factory MessageContact.fromJson(Map<String, dynamic> j) => MessageContact(
      id: j['id'] as int,
      nombre: j['nombre'] as String,
      apellido: j['apellido'] as String,
      cargo: j['cargo'] as String,
      unreadCount: j['unread_count'] as int? ?? 0,
      lastMessage: j['last_message'] as String?);
}

class InternalMessage {
  const InternalMessage(
      {required this.id,
      required this.senderId,
      required this.recipientId,
      required this.body,
      required this.createdAt,
      this.readAt});
  final int id, senderId, recipientId;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  factory InternalMessage.fromJson(Map<String, dynamic> j) => InternalMessage(
      id: j['id'] as int,
      senderId: j['sender_id'] as int,
      recipientId: j['recipient_id'] as int,
      body: j['body'] as String,
      createdAt: DateTime.parse(j['created_at'] as String),
      readAt:
          j['read_at'] == null ? null : DateTime.parse(j['read_at'] as String));
}

class MessagingRepository {
  const MessagingRepository(this.dio, this._localDb);
  final Dio dio;
  final LocalDatabaseService _localDb;

  Future<List<MessageContact>> contacts() async {
    try {
      return ((await dio.get<List<dynamic>>('/messages/contacts')).data!)
          .map((e) => MessageContact.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (_) {
      AppLogger.info('Offline mode: loading contacts from local SQLite');
      var users = await _localDb.getCachedEmpleados();
      if (users.isEmpty) {
        users = await _localDb.getAllLocalUsers();
      }
      return users
          .map((u) => MessageContact(
                id: u['id'] as int,
                nombre: u['nombre'] as String,
                apellido: u['apellido'] as String,
                cargo: (u['cargo'] as String?) ?? 'Empleado',
                unreadCount: 0,
              ))
          .toList();
    }
  }

  Future<List<InternalMessage>> conversation(int id) async {
    try {
      return ((await dio.get<List<dynamic>>('/messages/',
                  queryParameters: {'with_user_id': id, 'limit': 300}))
              .data!)
          .map((e) => InternalMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (_) {
      AppLogger.info('Offline mode: no conversation history available');
      return [];
    }
  }

  Future<InternalMessage> send(int id, String body) async {
    try {
      return InternalMessage.fromJson((await dio.post<Map<String, dynamic>>(
              '/messages/',
              data: {'recipient_id': id, 'body': body}))
          .data!);
    } on DioException catch (_) {
      // Offline: save message locally for later sync
      AppLogger.info('Offline mode: saving message locally');
      await _localDb.insertOfflineMessage(id, body);
      final now = DateTime.now();
      return InternalMessage(
        id: -1 * now.millisecondsSinceEpoch,
        senderId: 0,
        recipientId: id,
        body: body,
        createdAt: now,
      );
    }
  }

  Future<int> markConversationRead(int contactId) async {
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/messages/read-all/$contactId',
      );
      return response.data?['updated'] as int? ?? 0;
    } on DioException catch (_) {
      return 0;
    }
  }
}

final messagingRepositoryProvider = Provider(
    (ref) => MessagingRepository(ref.watch(dioProvider), ref.watch(localDatabaseServiceProvider)));
