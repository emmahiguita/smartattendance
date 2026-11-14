// ============================================================================
// ARCHIVO: capture_controls.dart
// QUÉ HACE: Panel limpio exclusivo para la marcación biométrica y GPS:
//           - Muestra únicamente la identidad del colaborador (nombre y cédula).
//           - Indicador del tipo de marcación (Entrada, Almuerzo, Salida).
//           - Botón de captura y verificación facial en vivo.
//           - Cero botones o paneles de configuración administrativa (rol, equipo,
//             horario, extras, soporte) en el flujo de cámara.
// CÓMO FUNCIONA: Desacoplado de la administración de turnos; enfocado 100% en marcar.
// POR QUÉ: Atiende la directiva: "el diseño donde uno le da inicio y se abre la cámara
//          para marcar no debería mostrar la información rol equipo horario extras soporte,
//          solo es para marcar" (< 140 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../domain/photo_record.dart';

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
  });

  final LocalWorker worker;
  final String type;
  final bool busy, recovered;
  final String? stage, error, coords;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final info = attendanceTypeInfo(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Identidad del colaborador
        IosGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.cBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.cBorder, width: 0.8),
                ),
                child: Text(
                  worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                  style: TextStyle(fontWeight: FontWeight.w700, color: context.cTextPrimary, fontSize: 13.5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.cTextPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'C.C. ${worker.document}',
                      style: TextStyle(fontSize: 11.5, color: context.cTextSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: context.cBackground,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.cBorder, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(info.icon, size: 13, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      info.label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.cTextPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (coords != null && coords!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.location_solid, size: 12, color: context.cTextSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    coords!,
                    style: TextStyle(fontSize: 11, color: context.cTextSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        if (stage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CupertinoActivityIndicator(radius: 8),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    stage!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.cTextSecondary),
                  ),
                ),
              ],
            ),
          ),

        if (error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.systemRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.systemRed.withValues(alpha: 0.3)),
            ),
            child: Text(
              error!,
              style: const TextStyle(fontSize: 12, color: AppColors.systemRed, fontWeight: FontWeight.w600),
            ),
          ),

        // Botón principal de marcación biométrica
        SizedBox(
          height: 46,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: busy ? null : onRetry,
            icon: Icon(
              busy ? CupertinoIcons.clock : (error != null ? CupertinoIcons.refresh : CupertinoIcons.viewfinder),
              size: 18,
            ),
            label: Text(
              busy ? 'Validando identidad…' : (error != null ? 'Reintentar captura' : 'Verificar rostro y registrar'),
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
