// lib/features/qr/presentation/widgets/qr_camera_error_view.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// ============================================================================
/// COMPONENTE: QrCameraErrorView
/// ============================================================================
/// QUÉ HACE:
/// Muestra un panel informativo elegante cuando los permisos de cámara no han
/// sido concedidos por el sistema operativo Android o iOS.
///
/// PARA QUÉ SIRVE:
/// Guía al empleado para abrir la pantalla de ajustes del dispositivo y otorgar
/// el permiso requerido sin frustración ni cierres inesperados (crashes).
///
/// PRINCIPIOS SOLID APLICADOS:
/// - S (Single Responsibility): Gestiona la vista de error de permisos de cámara.
/// ============================================================================
class QrCameraErrorView extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const QrCameraErrorView({super.key, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded, color: AppColors.systemRed, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Permiso de cámara necesario',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Para registrar asistencia mediante código QR, concede acceso a la cámara.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text('Abrir Ajustes'),
            ),
          ],
        ),
      ),
    );
  }
}
