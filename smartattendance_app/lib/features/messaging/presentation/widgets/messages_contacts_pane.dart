// ============================================================================
// ARCHIVO: messages_contacts_pane.dart
// QUÉ HACE: Renderiza la lista de contactos y empleados disponibles para mensajería
//           interna, incluyendo barra de búsqueda en tiempo real y contador de no leídos.
// CÓMO FUNCIONA: Filtra en memoria los contactos según el texto de búsqueda, muestra
//                avatares con iniciales y badges con número de mensajes pendientes.
// POR QUÉ: Principio de Responsabilidad Única (SRP) y modularización (< 160 líneas).
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/messaging_repository.dart';

// QUÉ HACE: Panel de selección de contactos para mensajería.
// CÓMO: Recibe la lista filtrada, el contacto seleccionado y callbacks de acción.
// POR QUÉ: Desacopla la vista de contactos del contenedor principal.
class MessagesContactsPane extends StatelessWidget {
  const MessagesContactsPane({
    super.key,
    required this.contacts,
    required this.selected,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSelectContact,
    this.errorMessage,
  });

  final List<MessageContact> contacts;
  final MessageContact? selected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<MessageContact> onSelectContact;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.cBackground,
      child: Column(
        children: [
          // QUÉ HACE: Barra de búsqueda reactiva por nombre o cargo.
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar empleado o cargo…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: context.cSurface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Alerta de error si falló la carga
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                errorMessage!,
                style: TextStyle(color: context.cTextPrimary, fontSize: 13),
              ),
            ),

          // QUÉ HACE: Lista de colaboradores de la empresa.
          Expanded(
            child: contacts.isEmpty
                ? const Center(
                    child: Text(
                      'No hay empleados disponibles',
                      style: TextStyle(fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    itemCount: contacts.length,
                    separatorBuilder: (_, __) => Divider(height: 1, indent: 74, color: context.cBorder),
                    itemBuilder: (context, i) {
                      final c = contacts[i];
                      final isSelected = selected?.id == c.id;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: context.cTextPrimary.withValues(alpha: .08),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: context.cSurface,
                          foregroundColor: context.cTextPrimary,
                          child: Text(
                            c.fullName.isEmpty ? '?' : c.fullName[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(
                          c.fullName,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          c.lastMessage ?? c.cargo,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: c.unreadCount > 0
                            ? Badge(label: Text(c.unreadCount.toString()))
                            : const Icon(Icons.chevron_right_rounded, size: 20),
                        onTap: () => onSelectContact(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
