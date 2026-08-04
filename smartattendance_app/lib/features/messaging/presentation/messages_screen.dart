import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../data/messaging_repository.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});
  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final composer = TextEditingController(), search = TextEditingController();
  List<MessageContact> contacts = const [];
  List<InternalMessage> messages = const [];
  MessageContact? selected;
  bool loading = true, sending = false;
  String? error;
  int? get me {
    final s = ref.read(sessionControllerProvider);
    return s is SessionAuthenticated ? s.user.id : null;
  }

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  @override
  void dispose() {
    composer.dispose();
    search.dispose();
    super.dispose();
  }

  Future<void> loadContacts() async {
    try {
      final value = await ref.read(messagingRepositoryProvider).contacts();
      if (mounted) {
        setState(() {
          contacts = value;
          loading = false;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'No fue posible cargar mensajería.';
        });
      }
    }
  }

  Future<void> open(MessageContact value) async {
    final contactId = value.id;
    setState(() {
      selected = value;
      loading = true;
      error = null;
    });
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final conversation = await repo.conversation(contactId);
      await repo.markConversationRead(contactId);
      final updatedContacts = await repo.contacts();
      if (mounted && selected?.id == contactId) {
        setState(() {
          contacts = updatedContacts;
          messages = conversation;
          loading = false;
          error = null;
        });
      }
    } catch (_) {
      if (mounted && selected?.id == contactId) {
        setState(() {
          loading = false;
          error = 'No fue posible cargar la conversación.';
        });
      }
    }
  }

  Future<void> send() async {
    final text = composer.text.trim();
    final contactId = selected?.id;
    if (text.isEmpty || contactId == null || sending) return;

    setState(() {
      sending = true;
      error = null;
    });

    try {
      final repo = ref.read(messagingRepositoryProvider);
      final sent = await repo.send(contactId, text);
      final updatedContacts = await repo.contacts();

      if (!mounted) return;
      setState(() {
        contacts = updatedContacts;
        sending = false;
        if (selected?.id == contactId) {
          messages = [...messages, sent];
          if (composer.text.trim() == text) composer.clear();
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          sending = false;
          error = 'No se pudo enviar el mensaje. Intenta nuevamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text.toLowerCase();
    final filtered = contacts
        .where((c) =>
            c.fullName.toLowerCase().contains(q) ||
            c.cargo.toLowerCase().contains(q))
        .toList();
    return Scaffold(
        backgroundColor: context.cBackground,
        appBar: AppBar(
            title: const Text('Mensajería interna',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            actions: [
              IconButton(
                  onPressed: loadContacts,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Actualizar')
            ]),
        body: LayoutBuilder(builder: (context, size) {
          final wide = size.maxWidth >= 800;
          if (loading && selected == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (wide) {
            return Row(children: [
              SizedBox(width: 340, child: contactsPane(filtered)),
              VerticalDivider(width: 1, color: context.cBorder),
              Expanded(child: conversationPane())
            ]);
          }
          return selected == null
              ? contactsPane(filtered)
              : conversationPane(mobile: true);
        }));
  }

  Widget contactsPane(List<MessageContact> value) => Container(
      color: context.cBackgroundSecondary,
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                    hintText: 'Buscar empleado o cargo',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: context.cSurface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none)))),
        if (error != null)
          Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error!,
                  style: const TextStyle(color: AppColors.systemRed))),
        Expanded(
            child: value.isEmpty
                ? const Center(child: Text('No hay empleados disponibles'))
                : ListView.separated(
                    itemCount: value.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, indent: 74, color: context.cBorder),
                    itemBuilder: (context, i) {
                      final c = value[i];
                      return ListTile(
                          selected: selected?.id == c.id,
                          selectedTileColor:
                              AppColors.primary.withValues(alpha: .08),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          leading: avatar(c.fullName),
                          title: Text(c.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(c.lastMessage ?? c.cargo,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: c.unreadCount > 0
                              ? Badge(label: Text(c.unreadCount.toString()))
                              : const Icon(Icons.chevron_right),
                          onTap: () => open(c));
                    }))
      ]));
  Widget conversationPane({bool mobile = false}) {
    if (selected == null) {
      return const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.forum_outlined, size: 64, color: AppColors.primary),
        SizedBox(height: 12),
        Text('Selecciona un empleado',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))
      ]));
    }
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: context.cSurface,
              border: Border(bottom: BorderSide(color: context.cBorder))),
          child: Row(children: [
            if (mobile)
              IconButton(
                  onPressed: () => setState(() => selected = null),
                  icon: const Icon(Icons.arrow_back)),
            avatar(selected!.fullName),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(selected!.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(selected!.cargo,
                      style: TextStyle(
                          color: context.cTextSecondary, fontSize: 12))
                ])),
            if (mobile)
              const Tooltip(
                  message: 'Conversación interna',
                  child: Icon(Icons.lock_outline_rounded, size: 20))
            else
              const Chip(
                  avatar: Icon(Icons.lock_outline, size: 14),
                  label: Text('Interno', style: TextStyle(fontSize: 11)))
          ])),
      if (error != null)
        MaterialBanner(content: Text(error!), actions: [
          TextButton(
              onPressed: () => open(selected!), child: const Text('Reintentar'))
        ]),
      Expanded(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : messages.isEmpty
                ? const Center(child: Text('Sin mensajes. Escribe el primero.'))
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[messages.length - 1 - index];
                      final mine = m.senderId == me;
                      return Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                              maxWidth: mobile
                                  ? MediaQuery.sizeOf(context).width * .78
                                  : 520),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                          decoration: BoxDecoration(
                            color: mine ? AppColors.primary : context.cSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: mine
                                ? null
                                : Border.all(color: context.cBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(m.body,
                                  style: TextStyle(
                                      color: mine
                                          ? Colors.white
                                          : context.cTextPrimary,
                                      height: 1.35)),
                              const SizedBox(height: 3),
                              Text(
                                  DateFormat('HH:mm')
                                      .format(m.createdAt.toLocal()),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: mine
                                          ? Colors.white70
                                          : context.cTextSecondary)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      SafeArea(
          top: false,
          child: Container(
              padding: const EdgeInsets.all(14),
              color: context.cSurface,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                    child: TextField(
                        controller: composer,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 2000,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => send(),
                        decoration: InputDecoration(
                            hintText: 'Escribe un mensaje profesional…',
                            counterText: '',
                            filled: true,
                            fillColor: context.cBackgroundSecondary,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none)))),
                const SizedBox(width: 10),
                IconButton.filled(
                    onPressed: sending ? null : send,
                    icon: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded))
              ]))),
    ]);
  }

  Widget avatar(String name) => CircleAvatar(
      backgroundColor: AppColors.primary.withValues(alpha: .12),
      foregroundColor: AppColors.primary,
      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w800)));
}
