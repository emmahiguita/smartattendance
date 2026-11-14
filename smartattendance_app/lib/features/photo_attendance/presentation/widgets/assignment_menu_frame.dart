// QUÉ HACE: Presenta formularios compactos y legibles de alta en un menú.
// CÓMO: Limita el ancho y permite desplazar el contenido al aparecer el teclado.
// POR QUÉ: Evita recortes en teléfonos pequeños y mantiene las acciones visibles.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AssignmentMenuFrame extends StatelessWidget {
  const AssignmentMenuFrame(
      {super.key,
      required this.title,
      required this.children,
      required this.busy,
      required this.onCancel,
      required this.onSave,
      this.error});
  final String title;
  final List<Widget> children;
  final bool busy;
  final VoidCallback onCancel, onSave;
  final String? error;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: (MediaQuery.sizeOf(context).width - 48).clamp(240, 360),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .72),
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: context.cTextPrimary)),
                    const SizedBox(height: 16),
                    ...children,
                    if (error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(error!, style: TextStyle(color: context.cTextPrimary))),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: context.cBorder),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(onPressed: busy ? null : onCancel, child: const Text('Cancelar')),
                      const SizedBox(width: 8),
                      FilledButton(
                          onPressed: busy ? null : onSave, child: Text(busy ? 'Guardando…' : 'Guardar')),
                    ]),
                  ])),
        ),
      );
}

/// Campo con etiqueta permanente para accesibilidad y automatización.
Widget assignmentField(BuildContext context, TextEditingController controller, String label,
        {TextInputType? keyboard}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
          controller: controller,
          keyboardType: keyboard,
          style: TextStyle(color: context.cTextPrimary, fontSize: 15),
          decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: context.cTextSecondary),
              border: const UnderlineInputBorder())),
    );
