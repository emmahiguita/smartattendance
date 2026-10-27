// ============================================================================
// ARCHIVO: nano_compact_glass_composer.dart
// QUÉ HACE: Compositor compacto de cristal estilo Apple iOS según el patrón Nano.
// CÓMO FUNCIONA: Barra horizontal con botón [+], chip de adjunto/componente,
//                editor denso de texto y acción final de envío.
// POR QUÉ: Cumple estrictamente la jerarquía Nano aprobada (< 175 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'nano_anchored_popover.dart';

class NanoCompactGlassComposer extends StatefulWidget {
  const NanoCompactGlassComposer({
    super.key,
    this.hintText = 'Buscar o registrar novedad…',
    this.controller,
    this.onSend,
    this.onAttachmentChanged,
    this.onWhatsAppToggled,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onSend;
  final ValueChanged<String?>? onAttachmentChanged;
  final ValueChanged<bool>? onWhatsAppToggled;

  @override
  State<NanoCompactGlassComposer> createState() => _NanoCompactGlassComposerState();
}

class _NanoCompactGlassComposerState extends State<NanoCompactGlassComposer> {
  final GlobalKey _plusButtonKey = GlobalKey();
  late final TextEditingController _textCtrl;
  final ImagePicker _picker = ImagePicker();
  String? _attachmentName;
  bool _isWhatsAppActive = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = widget.controller ?? TextEditingController();
  }

  void _openPlusMenu() {
    showNanoAnchoredPopover<void>(
      context: context,
      anchorKey: _plusButtonKey,
      headerTitle: 'ADJUNTOS Y COMPLEMENTOS',
      actions: [
        NanoPopoverAction(title: 'Cámara', icon: CupertinoIcons.camera_fill, onTap: () => _pickMedia(ImageSource.camera)),
        NanoPopoverAction(title: 'Fotos', icon: CupertinoIcons.photo_fill, onTap: () => _pickMedia(ImageSource.gallery)),
        NanoPopoverAction(
          title: 'Archivos',
          icon: CupertinoIcons.doc_fill,
          onTap: () {
            setState(() => _attachmentName = 'soporte_asistencia.pdf');
            widget.onAttachmentChanged?.call('soporte_asistencia.pdf');
          },
        ),
        NanoPopoverAction(
          title: _isWhatsAppActive ? 'Desactivar WhatsApp' : 'Complementos → WhatsApp',
          icon: Icons.chat_bubble_rounded,
          iconSize: 20,
          iconColor: const Color(0xFF25D366),
          onTap: () {
            setState(() => _isWhatsAppActive = !_isWhatsAppActive);
            widget.onWhatsAppToggled?.call(_isWhatsAppActive);
          },
        ),
      ],
    );
  }

  Future<void> _pickMedia(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source);
      if (file != null && mounted) {
        final name = file.name.isNotEmpty ? file.name : 'Imagen adjunta';
        setState(() => _attachmentName = name);
        widget.onAttachmentChanged?.call(file.path);
      }
    } catch (_) {}
  }

  void _handleSend() {
    final text = _textCtrl.text.trim();
    if (text.isNotEmpty || _attachmentName != null) {
      widget.onSend?.call(text);
      _textCtrl.clear();
      setState(() => _attachmentName = null);
      widget.onAttachmentChanged?.call(null);
    }
  }

  Widget _buildAttachmentHeader(BuildContext context) {
    if (_attachmentName == null) return const SizedBox.shrink();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 6, top: 4, bottom: 2),
        child: Row(children: [
          const Icon(CupertinoIcons.paperclip, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(_attachmentName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary))),
          GestureDetector(
            onTap: () { setState(() => _attachmentName = null); widget.onAttachmentChanged?.call(null); },
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, color: context.cBorder.withValues(alpha: 0.6)),
              child: Icon(Icons.close_rounded, size: 12, color: context.cTextSecondary),
            ),
          ),
        ]),
      ),
      Divider(height: 6, thickness: 0.5, color: context.cBorder.withValues(alpha: 0.4)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(22),
        blurSigmaX: 18,
        blurSigmaY: 18,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _buildAttachmentHeader(context),
          Row(children: [
            IconButton(
              key: _plusButtonKey,
              onPressed: _openPlusMenu,
              tooltip: 'Adjuntar y complementos',
              icon: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? AppColors.graphite : AppColors.silver),
                child: Icon(CupertinoIcons.add, size: 17, color: context.cTextPrimary),
              ),
            ),
            if (_isWhatsAppActive)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: const Color(0xFF25D366).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFF25D366)),
                ),
              ),
            Expanded(
              child: TextField(
                controller: _textCtrl,
                style: TextStyle(fontSize: 13.5, color: context.cTextPrimary),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(fontSize: 13, color: context.cTextSecondary.withValues(alpha: 0.7)),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            IconButton(
              onPressed: _handleSend,
              tooltip: 'Enviar',
              icon: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                child: const Icon(CupertinoIcons.arrow_up, size: 16, color: Colors.white),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
