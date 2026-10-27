// ============================================================================
// ARCHIVO: capture_controls.dart
// QUÉ HACE: Panel de controles e identidad del colaborador durante la captura
//           biométrica y validación GPS en vivo estilo iOS.
// CÓMO FUNCIONA: Muestra nombre, cédula, cargo, hito de jornada (`Entrada`,
//                `Almuerzo`, `Regreso`, `Salida`), coordenadas GPS reales y el
//                botón primario de confirmación en `AppColors.primary`.
// POR QUÉ: Elimina avatares y botones amarillo/naranja/rojo saturados ("vibe
//          coding") manteniendo sobriedad iOS y SRP (< 150 líneas).
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
    this.onConfigureWorker,
    this.onConfigureZones,
  });

  final LocalWorker worker;
  final String type;
  final bool busy, recovered;
  final String? stage, error, coords;
  final VoidCallback? onRetry, onConfigureWorker, onConfigureZones;

  @override
  Widget build(BuildContext context) {
    final info = attendanceTypeInfo(type);
    final rolePart = worker.job.trim().isEmpty ? 'Colaborador' : worker.job.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        IosGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(children: [
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(worker.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.cTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 1),
                Text('$rolePart · C.C. ${worker.document}', style: TextStyle(fontSize: 11.5, color: context.cTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            if (onConfigureWorker != null)
              IconButton(
                icon: Icon(CupertinoIcons.slider_horizontal_3, size: 17, color: context.cTextSecondary),
                tooltip: 'Configuración administrativa',
                onPressed: onConfigureWorker,
              ),
          ]),
        ),
        const SizedBox(height: 10),
        IosGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(info.icon, size: 15, color: AppColors.primary),
                const SizedBox(width: 7),
                Text(info.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.cTextPrimary)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.cBackground,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.cBorder, width: 0.8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.systemGreen, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('Biometría + GPS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: context.cTextPrimary)),
                ]),
              ),
            ]),
            if (coords != null && coords!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(coords!, style: TextStyle(fontSize: 11, color: context.cTextSecondary)),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        if (stage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CupertinoActivityIndicator(radius: 8),
              const SizedBox(width: 8),
              Flexible(child: Text(stage!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.cTextSecondary))),
            ]),
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
            child: Text(error!, style: const TextStyle(fontSize: 12, color: AppColors.systemRed, fontWeight: FontWeight.w600)),
          ),
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: busy ? null : onRetry,
            icon: Icon(busy ? CupertinoIcons.clock : (error != null ? CupertinoIcons.refresh : CupertinoIcons.viewfinder), size: 17),
            label: Text(
              busy ? 'Validando identidad…' : (error != null ? 'Reintentar captura' : 'Verificar rostro y registrar'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
