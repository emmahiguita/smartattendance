// QUÉ HACE: Muestra el contenido y la hora de un mensaje real.
// CÓMO: Alinea por remitente y separa cada mensaje con una línea neutra.
// POR QUÉ: Conserva legibilidad sin colores ni tarjetas decorativas.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/messaging_repository.dart';

class MessagesBubble extends StatelessWidget {
  const MessagesBubble({super.key, required this.message, required this.mine, required this.isLandscape});
  final InternalMessage message;
  final bool mine, isLandscape;
  @override
  Widget build(BuildContext context) => Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: isLandscape ? 480 : MediaQuery.sizeOf(context).width * .82),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.cBorder))),
          child:
              Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
            Text(message.body, style: TextStyle(color: context.cTextPrimary, fontSize: 15, height: 1.4)),
            const SizedBox(height: 6),
            Text(DateFormat('HH:mm').format(message.createdAt.toLocal()),
                style: TextStyle(color: context.cTextSecondary, fontSize: 12)),
          ]),
        ),
      );
}
