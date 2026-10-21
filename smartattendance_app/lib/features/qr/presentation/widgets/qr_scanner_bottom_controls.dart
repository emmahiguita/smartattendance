// lib/features/qr/presentation/widgets/qr_scanner_bottom_controls.dart
import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';

/// ============================================================================
/// COMPONENTE: QrScannerBottomControls
/// ============================================================================
/// QUÉ HACE:
/// Renderiza las instrucciones de lectura y las acciones de acceso alternativo
/// (selección de imagen en galería y modal de ayuda didáctica).
///
/// PARA QUÉ SIRVE:
/// Proporciona accesibilidad completa para trabajadores que necesitan escanear
/// un código recibido digitalmente o que requieren asistencia sobre el proceso.
///
/// PRINCIPIOS SOLID APLICADOS:
/// - S (Single Responsibility): Controla los botones de acción inferior.
/// ============================================================================
class QrScannerBottomControls extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onHelp;

  const QrScannerBottomControls({
    super.key,
    required this.onGallery,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Instrucción textual
        const Text(
          'Enfoca el código QR de ${AppConfig.companyName}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.systemGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Detección automática por Visión de Cámara',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // 2. Botones de Galería y Ayuda
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ActionButton(
              icon: Icons.photo_library_rounded,
              label: 'Galería',
              onTap: onGallery,
            ),
            const SizedBox(width: 28),
            _ActionButton(
              icon: Icons.help_outline_rounded,
              label: 'Ayuda',
              onTap: onHelp,
            ),
          ],
        ),

        const SizedBox(height: 12),
      ],
    );
  }
}

/// Botón estilizado para acciones inferiores con icono y rótulo
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
