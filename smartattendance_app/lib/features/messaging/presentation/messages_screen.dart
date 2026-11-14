// ============================================================================
// ARCHIVO: messages_screen.dart
// QUÉ HACE: Pantalla principal de Mensajería Interna Corporativa. Orquesta
//           la lista de contactos y la conversación activa según el dispositivo.
// CÓMO FUNCIONA: En pantallas anchas (>= 800 dp o landscape de tablet) muestra
//                vista dividida (contactos + chat). En teléfonos móviles alterna
//                entre lista y chat mediante navegación interna.
// POR QUÉ: Desacopla presentación y lógica bajo Clean Architecture (< 160 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../data/messaging_repository.dart';
import 'widgets/messages_contacts_pane.dart';
import 'widgets/messages_conversation_pane.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _composer = TextEditingController();
  final _search = TextEditingController();
  List<MessageContact> _contacts = const [];
  List<InternalMessage> _messages = const [];
  MessageContact? _selected;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  int? get _currentUserId {
    final s = ref.read(sessionControllerProvider);
    return s is SessionAuthenticated ? s.user.id : null;
  }

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _composer.dispose();
    _search.dispose();
    super.dispose();
  }

  // QUÉ HACE: Consulta la lista de contactos desde la API o la nómina local SQLite.
  // CÓMO: Usa el repositorio de mensajería con fallback automático offline.
  // POR QUÉ: Permite comunicación interna fluida en cualquier condición de red.
  Future<void> _loadContacts() async {
    try {
      final value = await ref.read(messagingRepositoryProvider).contacts();
      if (mounted) {
        setState(() {
          _contacts = value;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No fue posible sincronizar la lista de contactos.';
        });
      }
    }
  }

  // QUÉ HACE: Abre la conversación con el contacto seleccionado y marca leídos.
  Future<void> _openContact(MessageContact contact) async {
    final contactId = contact.id;
    setState(() {
      _selected = contact;
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(messagingRepositoryProvider);
      final conversation = await repo.conversation(contactId);
      await repo.markConversationRead(contactId);
      final updatedContacts = await repo.contacts();

      if (mounted && _selected?.id == contactId) {
        setState(() {
          _contacts = updatedContacts;
          _messages = conversation;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && _selected?.id == contactId) {
        setState(() {
          _loading = false;
          _error = 'No se pudo cargar la conversación.';
        });
      }
    }
  }

  // QUÉ HACE: Envía el mensaje compuesto y actualiza la lista en memoria.
  Future<void> _sendMessage() async {
    final text = _composer.text.trim();
    final contactId = _selected?.id;
    if (text.isEmpty || contactId == null || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final repo = ref.read(messagingRepositoryProvider);
      final sent = await repo.send(contactId, text, currentUserId: _currentUserId ?? 0);
      final updatedContacts = await repo.contacts();

      if (!mounted) return;
      setState(() {
        _contacts = updatedContacts;
        _sending = false;
        if (_selected?.id == contactId) {
          _messages = [..._messages, sent];
          if (_composer.text.trim() == text) _composer.clear();
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'No se pudo entregar el mensaje. Reintenta.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.toLowerCase();
    final filtered = _contacts
        .where((c) =>
            c.fullName.toLowerCase().contains(q) ||
            c.cargo.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppBar(
        title: const Text(
          'Mensajería interna',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: _loadContacts,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, size) {
          final isWide = size.maxWidth >= 800;

          if (_loading && _selected == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (isWide) {
            return Row(
              children: [
                SizedBox(
                  width: 320,
                  child: MessagesContactsPane(
                    contacts: filtered,
                    selected: _selected,
                    searchController: _search,
                    onSearchChanged: (_) => setState(() {}),
                    onSelectContact: _openContact,
                    errorMessage: _error,
                  ),
                ),
                VerticalDivider(width: 1, color: context.cBorder),
                Expanded(
                  child: MessagesConversationPane(
                    selected: _selected,
                    messages: _messages,
                    currentUserId: _currentUserId,
                    composer: _composer,
                    isLoading: _loading,
                    isSending: _sending,
                    onSend: _sendMessage,
                    onBack: () => setState(() => _selected = null),
                    isMobile: false,
                    errorMessage: _error,
                  ),
                ),
              ],
            );
          }

          // Modo móvil (vista única)
          return _selected == null
              ? MessagesContactsPane(
                  contacts: filtered,
                  selected: _selected,
                  searchController: _search,
                  onSearchChanged: (_) => setState(() {}),
                  onSelectContact: _openContact,
                  errorMessage: _error,
                )
              : MessagesConversationPane(
                  selected: _selected,
                  messages: _messages,
                  currentUserId: _currentUserId,
                  composer: _composer,
                  isLoading: _loading,
                  isSending: _sending,
                  onSend: _sendMessage,
                  onBack: () => setState(() => _selected = null),
                  isMobile: true,
                  errorMessage: _error,
                );
        },
      ),
    );
  }
}
