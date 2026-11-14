// ============================================================================
// ARCHIVO: messages_conversation_pane.dart
// QUÉ HACE: Renderiza la conversación activa entre dos usuarios, con burbujas
//           elásticas (desde un 'hola' hasta párrafos de 2000 caracteres),
//           chips de respuesta rápida inteligente y caja de texto multilínea.
// CÓMO FUNCIONA: Muestra mensajes ordenados cronológicamente con reverse: true,
//                soporta Material Expressive 3 y adapta tamaños en modo horizontal.
// POR QUÉ: Evita respuestas estáticas/robóticas ofreciendo opciones rápidas (< 195 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'messages_bubble.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/messaging_repository.dart';

class MessagesConversationPane extends StatelessWidget {
  const MessagesConversationPane({
    super.key,
    required this.selected,
    required this.messages,
    required this.currentUserId,
    required this.composer,
    required this.isLoading,
    required this.isSending,
    required this.onSend,
    required this.onBack,
    required this.isMobile,
    this.errorMessage,
  });

  final MessageContact? selected;
  final List<InternalMessage> messages;
  final int? currentUserId;
  final TextEditingController composer;
  final bool isLoading;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onBack;
  final bool isMobile;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (selected == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 56, color: context.cTextSecondary),
            const SizedBox(height: 12),
            const Text('Selecciona un empleado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      children: [
        // Header de la conversación
        _buildHeader(context),

        // Banner de error si falló el envío o carga
        if (errorMessage != null)
          MaterialBanner(
            content: Text(errorMessage!),
            actions: [
              TextButton(onPressed: onSend, child: const Text('Reintentar')),
            ],
          ),

        // Lista de mensajes con burbujas adaptativas
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : messages.isEmpty
                  ? const Center(child: Text('Sin mensajes aún. Escribe el primero.'))
                  : ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? 24 : 16,
                        vertical: 12,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (ctx, idx) {
                        final m = messages[messages.length - 1 - idx];
                        return MessagesBubble(
                            message: m, mine: m.senderId == currentUserId, isLandscape: isLandscape);
                      },
                    ),
        ),

        // Opciones de respuesta rápida para no escribir siempre a mano

        // Caja de entrada multilínea elástica
        _buildComposerBar(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.cSurface,
        border: Border(bottom: BorderSide(color: context.cBorder)),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          CircleAvatar(
            backgroundColor: context.cSurface,
            foregroundColor: context.cTextPrimary,
            child: Text(selected!.fullName.isEmpty ? '?' : selected!.fullName[0].toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selected!.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(selected!.cargo, style: TextStyle(color: context.cTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Chip(
            avatar: Icon(Icons.shield_outlined, size: 14),
            label: Text('Interno', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: context.cSurface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: composer,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje profesional…',
                  counterText: '',
                  filled: true,
                  fillColor: context.cBackgroundSecondary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
