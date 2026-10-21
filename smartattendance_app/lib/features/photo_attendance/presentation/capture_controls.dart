// lib/features/photo_attendance/presentation/capture_controls.dart
import 'package:flutter/material.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/attendance_type.dart';
import '../domain/photo_record.dart';

/// ============================================================================
/// COMPONENTE: CaptureControls (Formulario Real de Registro de Asistencia)
/// ============================================================================
/// QUÉ HACE:
/// Presenta los controles y credencial de la marcación en curso:
/// 1. Credencial del colaborador (Nombre, Cédula, Cargo).
/// 2. Tipo de marcación (Entrada, Almuerzo, Regreso, Salida) y sensor GPS.
/// 3. Estados de progreso y retroalimentación de error.
/// 4. Botón de captura / confirmación con diseño Apple HIG.
/// ============================================================================
class CaptureControls extends StatelessWidget {
  const CaptureControls({
    super.key,
    required this.worker,
    required this.type,
    required this.busy,
    this.stage,
    this.error,
    this.coords,
    this.recovered = false,
    this.onRetry,
    this.onConfigureWorker,
    this.onConfigureZones,
  });

  final LocalWorker worker;
  final String type;
  final bool busy;
  final String? stage;
  final String? error;
  final String? coords;
  final bool recovered;
  final VoidCallback? onRetry;
  final VoidCallback? onConfigureWorker;
  final VoidCallback? onConfigureZones;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = attendanceTypeInfo(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Encabezado de Identidad del Colaborador
        IosGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: info.color.withValues(alpha: 0.15),
                child: Text(
                  worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                  style: TextStyle(fontWeight: FontWeight.w700, color: info.color, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${worker.job.isEmpty ? 'Colaborador' : worker.job} · C.C. ${worker.document}',
                      style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onConfigureWorker != null)
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  tooltip: 'Configuración administrativa',
                  onPressed: onConfigureWorker,
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Tarjeta del Tipo de Asistencia y Sensor GPS
        IosGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(info.icon, size: 16, color: info.color),
                      const SizedBox(width: 7),
                      Text(
                        info.label,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: info.color),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.systemGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.systemGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Ubicación GPS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.systemGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (coords != null && coords!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  coords!,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Estado de Operación en Curso
        if (stage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      stage!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 4. Mensaje de Error
        if (error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.systemRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.systemRed.withValues(alpha: 0.3), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 17, color: AppColors.systemRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(fontSize: 12, color: AppColors.systemRed, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

        // 5. Botón de Acción Principal
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: info.color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: busy ? null : onRetry,
            icon: Icon(
              busy
                  ? Icons.hourglass_top_rounded
                  : (recovered
                      ? Icons.check_circle_rounded
                      : (error != null ? Icons.refresh_rounded : Icons.face_retouching_natural_rounded)),
              size: 18,
            ),
            label: Text(
              busy
                  ? 'Validando identidad…'
                  : (recovered
                      ? 'Confirmar marcación'
                      : (error != null ? 'Reintentar captura' : 'Verificar y registrar asistencia')),
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, letterSpacing: -0.2),
            ),
          ),
        ),
      ],
    );
  }
}
