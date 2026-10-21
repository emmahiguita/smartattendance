import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../core/auth/session_controller.dart';
import '../../../core/localstore/local_database_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/dio_provider.dart';

class MessageContact {
  const MessageContact(
      {required this.id,
      required this.nombre,
      required this.apellido,
      required this.cargo,
      this.fotoUrl,
      required this.unreadCount,
      this.lastMessage});
  final int id;
  final String nombre, apellido, cargo;
  final String? fotoUrl;
  final int unreadCount;
  final String? lastMessage;
  String get fullName => '$nombre $apellido'.trim();
  String get cedula => ''; // solo disponible en modo offline
  factory MessageContact.fromJson(Map<String, dynamic> j) => MessageContact(
      id: j['id'] as int,
      nombre: j['nombre'] as String,
      apellido: j['apellido'] as String,
      cargo: j['cargo'] as String,
      fotoUrl: j['foto_url'] as String?,
      unreadCount: j['unread_count'] as int? ?? 0,
      lastMessage: j['last_message'] as String?);

  factory MessageContact.fromLocalRow(Map<String, dynamic> r, {int unread = 0, String? lastMsg}) => MessageContact(
      id: r['id'] as int,
      nombre: r['nombre'] as String,
      apellido: r['apellido'] as String,
      cargo: (r['cargo'] as String?) ?? 'Empleado',
      fotoUrl: r['foto_url'] as String?,
      unreadCount: unread,
      lastMessage: lastMsg);
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
  MessagingRepository(this.dio, this._localDb);
  final Dio dio;
  final LocalDatabaseService _localDb;

  /// ID del usuario actual. Se inyecta desde la UI vía el provider que
  /// lee la sesión. Necesario para filtrar self-contact y posicionar burbujas.
  int? currentUserId;

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.type == DioExceptionType.unknown &&
            e.error != null &&
            e.error.toString().contains('SocketException'));
  }

  Future<List<MessageContact>> contacts() async {
    try {
      return ((await dio.get<List<dynamic>>('/messages/contacts')).data!)
          .map((e) => MessageContact.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (!_isNetworkError(e)) rethrow;
      AppLogger.info('Offline mode: loading contacts from local SQLite');
      var users = await _localDb.getCachedEmpleados();
      if (users.isEmpty) {
        users = await _localDb.getAllLocalUsers();
      }
      // Filtrar el propio usuario para no verse a sí mismo (match backend)
      final me = currentUserId;
      if (me != null) {
        users = users.where((u) => u['id'] != me).toList();
      }
      // Calcular unread count y last message del offline_messages local
      final pending = await _localDb.getPendingOfflineMessages();
      final unreadByUser = <int, int>{};
      final lastByUser = <int, String>{};
      for (final m in pending) {
        final uid = m['recipient_id'] as int;
        unreadByUser[uid] = (unreadByUser[uid] ?? 0) + 1;
        lastByUser[uid] = m['body'] as String;
      }
      final contacts = users
          .map((u) => MessageContact.fromLocalRow(u,
                unread: unreadByUser[u['id'] as int] ?? 0,
                lastMsg: lastByUser[u['id'] as int]))
          .toList();
      // Ordenar: los que tienen lastMessage primero (más recientes al inicio)
      contacts.sort((a, b) {
        if (a.lastMessage != null && b.lastMessage == null) return -1;
        if (a.lastMessage == null && b.lastMessage != null) return 1;
        return a.fullName.compareTo(b.fullName);
      });
      return contacts;
    }
  }

  Future<List<InternalMessage>> conversation(int contactId) async {
    try {
      return ((await dio.get<List<dynamic>>('/messages/',
                  queryParameters: {'with_user_id': contactId, 'limit': 300}))
              .data!)
          .map((e) => InternalMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (!_isNetworkError(e)) rethrow;
      AppLogger.info('Offline mode: loading local conversation history');
      final all = await _localDb.getPendingOfflineMessages();
      final me = currentUserId ?? 0;
      return all
          .where((m) => m['recipient_id'] == contactId)
          .map((m) => InternalMessage(
                id: m['id'] as int,
                senderId: me,
                recipientId: m['recipient_id'] as int,
                body: m['body'] as String,
                createdAt: DateTime.tryParse(m['created_at'] as String) ??
                    DateTime.now(),
              ))
          .toList();
    }
  }

  Future<InternalMessage> send(int recipientId, String body,
      {int currentUserId = 0, String? recipientCedula}) async {
    try {
      return InternalMessage.fromJson((await dio.post<Map<String, dynamic>>(
              '/messages/',
              data: {'recipient_id': recipientId, 'body': body}))
          .data!);
    } on DioException catch (e) {
      if (!_isNetworkError(e)) rethrow;
      // Offline: save message locally for later sync
      AppLogger.info('Offline mode: saving message locally');
      await _localDb.insertOfflineMessage(recipientId, body,
          recipientCedula: recipientCedula);
      final now = DateTime.now();
      return InternalMessage(
        id: -(now.millisecondsSinceEpoch + Random().nextInt(10000)),
        senderId: currentUserId,
        recipientId: recipientId,
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

  /// Sincroniza mensajes guardados offline con el backend.
  /// Retorna la cantidad de mensajes procesados exitosamente.
  Future<int> syncPendingMessages() async {
    final pending = await _localDb.getPendingOfflineMessages();
    if (pending.isEmpty) return 0;

    AppLogger.info(
        'Sincronizando ${pending.length} mensajes offline con el backend...');

    final payload = pending.map((row) {
      return {
        'recipient_id': row['recipient_id'],
        'recipient_cedula': row['recipient_cedula'],
        'body': row['body'],
        'client_id': row['id'],
        'created_at': row['created_at'],
      };
    }).toList();

    try {
      final response = await dio.post(
        '/messages/sync',
        data: {'messages': payload},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final detalles = data['detalles'] as List<dynamic>? ?? [];

        final exitosos = <int>[];
        for (final d in detalles) {
          final detail = d as Map<String, dynamic>;
          final status = detail['status'] as String? ?? '';
          final clientId = detail['client_id'] as int?;
          if (clientId != null &&
              (status == 'creado' || status == 'duplicado_ignorado')) {
            exitosos.add(clientId);
          }
        }

        if (exitosos.isNotEmpty) {
          await _localDb.markMessagesAsSynced(exitosos);
        }

        AppLogger.info(
            'Sync mensajes: ${exitosos.length} procesados, '
            '${data['errores'] ?? 0} errores.');
        return exitosos.length;
      }
    } catch (e) {
      AppLogger.warning('Fallo durante sincronización de mensajes offline: $e');
    }
    return 0;
  }
}

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  final repo = MessagingRepository(
      ref.watch(dioProvider), ref.watch(localDatabaseServiceProvider));
  final session = ref.watch(sessionControllerProvider);
  repo.currentUserId =
      session is SessionAuthenticated ? session.user.id : null;
  return repo;
});
