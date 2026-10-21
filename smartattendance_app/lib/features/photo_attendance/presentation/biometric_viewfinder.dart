// lib/features/photo_attendance/presentation/biometric_viewfinder.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/design_system/ios_glass_card.dart';

/// ============================================================================
/// COMPONENTE: BiometricViewfinder (Visor de Reconocimiento Facial en Vivo)
/// ============================================================================
/// QUÉ HACE:
/// Muestra el flujo de video en vivo de la cámara frontal con retícula biométrica
/// de alta precisión estilo Apple Face ID, o la captura congelada tras verificar.
///
/// TECNOLOGÍA REAL:
/// 1. Sensor frontal embebido directo en la UI con CameraPreview nativo.
/// 2. Retícula elíptica activa con guías de encuadre.
/// 3. Estados visuales reactivos: live-preview, validación en curso, verificado o error.
/// ============================================================================
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
    final isCameraReady = cameraController != null && cameraController!.value.isInitialized;

    final borderColor = hasError
        ? AppColors.systemRed
        : (verified
            ? AppColors.systemGreen
            : (busy ? AppColors.primary : AppColors.primary.withValues(alpha: 0.6)));

    final badgeColor = hasError
        ? AppColors.systemRed
        : (verified
            ? AppColors.systemGreen
            : (busy ? AppColors.primary : (isDark ? Colors.white : const Color(0xFF1C1C1E))));

    final badgeText = hasError
        ? 'Verificación no superada · Reintentar'
        : (verified
            ? 'Rostro verificado con éxito'
            : (busy
                ? 'Validando identidad biométrica…'
                : (hasPhoto
                    ? 'Procesando captura…'
                    : (isCameraReady
                        ? 'Ubica tu rostro dentro del marco'
                        : 'Iniciando sensor de cámara frontal…'))));

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
              // 1. Live Camera Preview o Foto Capturada o Estado Inicial
              if (hasPhoto)
                Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  cacheWidth: 1080,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('Error al cargar la foto capturada.'),
                  ),
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
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isInitializingCamera) ...[
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Iniciando cámara frontal…',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.cTextSecondary,
                            ),
                          ),
                        ] else ...[
                          Icon(Icons.face_retouching_natural_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.7)),
                          const SizedBox(height: 10),
                          Text(
                            'Sensor biométrico listo',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.cTextPrimary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // 2. Viñeta estética para contraste fotográfico
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

              // 3. Retícula biométrica elíptica Face ID de alta precisión
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 200,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(105),
                    border: Border.all(
                      color: borderColor.withValues(alpha: verified ? 0.9 : 0.75),
                      width: verified || hasError ? 2.5 : 1.8,
                    ),
                    boxShadow: verified
                        ? [
                            BoxShadow(
                              color: AppColors.systemGreen.withValues(alpha: 0.35),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // Esquinas decorativas de precisión biométrica
                      Positioned(
                        top: 24,
                        left: 20,
                        child: Container(width: 12, height: 2, color: borderColor),
                      ),
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Container(width: 2, height: 12, color: borderColor),
                      ),
                      Positioned(
                        top: 24,
                        right: 20,
                        child: Container(width: 12, height: 2, color: borderColor),
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(width: 2, height: 12, color: borderColor),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 20,
                        child: Container(width: 12, height: 2, color: borderColor),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Container(width: 2, height: 12, color: borderColor),
                      ),
                      Positioned(
                        bottom: 24,
                        right: 20,
                        child: Container(width: 12, height: 2, color: borderColor),
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Container(width: 2, height: 12, color: borderColor),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Pastilla inferior con estado biométrico
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF1C1C1E) : Colors.white).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.35), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasError
                            ? Icons.error_outline_rounded
                            : (verified
                                ? Icons.verified_rounded
                                : (busy
                                    ? Icons.hourglass_top_rounded
                                    : Icons.face_rounded)),
                        size: 15,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Overlay durante validación / proceso
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
