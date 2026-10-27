// ============================================================================
// ARCHIVO: biometric_viewfinder.dart
// QUÉ HACE: Renderiza el visor de cámara frontal en tiempo real con retícula
//           biométrica elíptica estilo Face ID y estados reactivos de
//           verificación ML Kit.
// CÓMO FUNCIONA: Integra `CameraPreview` nativo (sin simulación fotográfica),
//                superpone el óvalo guía y muestra el badge de estado inferior.
// POR QUÉ: Cumple SRP (< 190 líneas) y garantiza validación facial real.
// ============================================================================

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class BiometricViewfinder extends StatelessWidget {
  const BiometricViewfinder({
    super.key,
    this.cameraController,
    this.imagePath,
    this.busy = false,
    this.verified = false,
    this.hasError = false,
    this.isInitializingCamera = false,
    this.onTap,
  });

  final CameraController? cameraController;
  final String? imagePath;
  final bool busy;
  final bool verified;
  final bool hasError;
  final bool isInitializingCamera;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = imagePath != null;
    final isCameraReady =
        cameraController != null && cameraController!.value.isInitialized;

    final borderColor = hasError
        ? AppColors.systemRed
        : (verified ? AppColors.systemGreen : AppColors.primary);

    final badgeText = hasError
        ? 'Verificación no superada · Reintentar'
        : (verified
            ? 'Rostro verificado con éxito'
            : (busy
                ? 'Validando identidad biométrica…'
                : (isCameraReady
                    ? 'Ubica tu rostro dentro del óvalo'
                    : 'Iniciando cámara frontal…')));

    return IosGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 18,
      onTap: busy ? null : onTap,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto)
                Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  cacheWidth: 1080,
                )
              else if (isCameraReady)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: cameraController!.value.previewSize?.height ?? 1,
                    height: cameraController!.value.previewSize?.width ?? 1,
                    child: CameraPreview(cameraController!),
                  ),
                )
              else
                Container(
                  color:
                      isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  child: Center(
                    child: isInitializingCamera
                        ? const CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.primary,
                          )
                        : Icon(
                            Icons.face_retouching_natural_rounded,
                            size: 48,
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                  ),
                ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.95,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 196,
                  height: 256,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(105),
                    border: Border.all(
                      color: borderColor.withValues(alpha: 0.85),
                      width: verified || hasError ? 2.6 : 1.8,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF1C1C1E) : Colors.white)
                        .withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: borderColor.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasError
                            ? Icons.error_outline_rounded
                            : (verified
                                ? Icons.verified_rounded
                                : Icons.face_rounded),
                        size: 15,
                        color: borderColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.cTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (busy)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
