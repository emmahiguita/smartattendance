// lib/features/qr/presentation/widgets/qr_scanner_top_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';

/// ============================================================================
/// COMPONENTE: QrScannerTopBar
/// ============================================================================
/// QUÉ HACE:
/// Proporciona la barra superior flotante para el escáner de códigos QR.
/// Incluye controles de hardware (linterna, cambio de cámara) y botón de retorno.
///
/// PARA QUÉ SIRVE:
/// Permite al empleado manipular la iluminación y cámara en entornos oscuros
/// o de difícil acceso, además de brindar identidad de marca verificada.
///
/// PRINCIPIOS SOLID APLICADOS:
/// - S (Single Responsibility): Controla únicamente las acciones de cabecera.
/// ============================================================================
class QrScannerTopBar extends StatefulWidget {
  final MobileScannerController cameraCtrl;

  const QrScannerTopBar({super.key, required this.cameraCtrl});

  @override
  State<QrScannerTopBar> createState() => _QrScannerTopBarState();
}

class _QrScannerTopBarState extends State<QrScannerTopBar> {
  bool _torchOn = false;
  bool _frontCamera = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 1. Botón de retroceso
          _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: () => context.pop(),
          ),

          const Spacer(),

          // 2. Título de la pantalla e indicador de seguridad
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded, size: 12, color: AppColors.systemGreen),
                    SizedBox(width: 4),
                    Text(
                      '${AppConfig.companyName} · VERIFICADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Escanear QR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const Spacer(),

          // 3. Conmutador de cámara (frontal / trasera)
          _CircleIconButton(
            icon: Icons.cameraswitch_rounded,
            active: _frontCamera,
            onPressed: () {
              widget.cameraCtrl.switchCamera();
              setState(() => _frontCamera = !_frontCamera);
            },
          ),
          const SizedBox(width: 8),

          // 4. Linterna / Flash
          _CircleIconButton(
            icon: _torchOn ? Icons.flashlight_off_rounded : Icons.flashlight_on_rounded,
            active: _torchOn,
            onPressed: () {
              widget.cameraCtrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
    );
  }
}

/// Botón circular translúcido con microinteracción visual activa
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool active;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? AppColors.primary.withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.14),
          border: Border.all(
            color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
