// lib/features/qr/presentation/widgets/qr_scanner_help_sheet.dart
import 'package:flutter/material.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// ============================================================================
/// COMPONENTE: QrScannerHelpSheet
/// ============================================================================
/// QUÉ HACE:
/// Muestra un panel modal inferior (BottomSheet) con instrucciones didácticas
/// para el uso correcto del escáner de códigos QR corporativos.
///
/// PARA QUÉ SIRVE:
/// Orienta al trabajador sobre cómo enfocar la cámara, usar imágenes guardadas
/// y comprender la validez de un solo uso por código.
///
/// PRINCIPIOS SOLID APLICADOS:
/// - S (Single Responsibility): Responsabilidad única de renderizar la ayuda.
/// ============================================================================
class QrScannerHelpSheet extends StatelessWidget {
  const QrScannerHelpSheet({super.key});

  /// Método estático de conveniencia para abrir la hoja modal.
  static Future<void> show(BuildContext context) {
    return showIosFloatingGlassSheet<void>(
      context: context,
      title: 'Cómo escanear tu asistencia',
      subtitle: 'Instrucciones para el uso correcto del QR',
      child: const QrScannerHelpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          const _HelpRow(
              icon: Icons.qr_code_scanner,
              text: 'Apunta la cámara al código QR generado por tu supervisor o terminal.',
            ),
            const SizedBox(height: 12),
            const _HelpRow(
              icon: Icons.photo_library,
              text: 'Si te enviaron el QR, pulsa "Galería" para seleccionarlo de tu dispositivo.',
            ),
            const SizedBox(height: 12),
            const _HelpRow(
              icon: Icons.location_on_rounded,
              text: 'El sistema valida automáticamente tus coordenadas GPS satelitales.',
            ),
            const SizedBox(height: 12),
            const _HelpRow(
              icon: Icons.verified_user,
              text: 'Cada código es personal y de un solo uso para garantizar seguridad.',
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fila descriptiva individual dentro del modal de ayuda.
class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.5, color: context.cTextPrimary, height: 1.35),
          ),
        ),
      ],
    );
  }
}
