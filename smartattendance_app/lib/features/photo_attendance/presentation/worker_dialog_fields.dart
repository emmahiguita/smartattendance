// ============================================================================
// ARCHIVO: worker_dialog_fields.dart
// QUÉ HACE: Grupos de campos Inset Grouped para el alta de colaborador:
//           identificación, turno pactado, rango de marcación y captura GPS.
// CÓMO FUNCIONA: Componentes desacoplados que renderizan los selectores y el
//                botón de fijar GPS real del móvil del supervisor.
// POR QUÉ: Mantiene la modularidad y cumple el límite estricto de < 200 líneas.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/shift_template.dart';

class WorkerDialogFields extends StatelessWidget {
  const WorkerDialogFields({
    super.key,
    required this.nameCtrl,
    required this.docCtrl,
    required this.jobCtrl,
    required this.selectedTemplate,
    required this.toleranceMode,
    required this.crewName,
    required this.gpsLat,
    required this.gpsLng,
    required this.locating,
    required this.onPickSchedule,
    required this.onPickTolerance,
    required this.onPickCrew,
    required this.onCaptureGps,
  });

  final TextEditingController nameCtrl, docCtrl, jobCtrl;
  final ShiftTemplate? selectedTemplate;
  final String toleranceMode;
  final String? crewName;
  final double? gpsLat, gpsLng;
  final bool locating;
  final VoidCallback onPickSchedule, onPickTolerance, onPickCrew, onCaptureGps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IosFormGroup(
          header: 'DATOS PERSONALES',
          children: [
            IosFormFieldRow(label: 'Nombre', placeholder: 'Nombre y apellidos', controller: nameCtrl, textCapitalization: TextCapitalization.words),
            IosFormFieldRow(label: 'Cédula', placeholder: 'Número de documento', controller: docCtrl, keyboardType: TextInputType.number),
            IosFormFieldRow(label: 'Cargo', placeholder: 'Puesto u ocupación', controller: jobCtrl),
          ],
        ),
        const SizedBox(height: 12),
        IosFormGroup(
          header: 'HORARIO Y REGLAS DE MARCACIÓN',
          children: [
            WorkerSelectorRow(
              label: 'Turno',
              value: selectedTemplate != null
                  ? (selectedTemplate!.name.contains('(')
                      ? selectedTemplate!.name
                      : '${selectedTemplate!.name} (${selectedTemplate!.timeFormatted})')
                  : 'Seleccionar',
              onTap: onPickSchedule,
            ),
            WorkerSelectorRow(label: 'Rango de marcación', value: toleranceMode, onTap: onPickTolerance),
          ],
        ),
        const SizedBox(height: 12),
        IosFormGroup(
          header: 'ZONA Y UBICACIÓN REAL DEL MÓVIL',
          children: [
            WorkerSelectorRow(label: 'Cuadrilla', value: crewName ?? 'Sin cuadrilla', onTap: onPickCrew),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      gpsLat != null ? 'GPS real: ${gpsLat!.toStringAsFixed(4)}, ${gpsLng!.toStringAsFixed(4)} (100m)' : 'Sin coordenadas vinculadas',
                      style: TextStyle(fontSize: 12, color: gpsLat != null ? AppColors.success : context.cTextSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: AppColors.primary,
                    minimumSize: const Size(0, 32),
                    borderRadius: BorderRadius.circular(8),
                    onPressed: locating ? null : onCaptureGps,
                    child: locating
                        ? const CupertinoActivityIndicator(radius: 7, color: Colors.white)
                        : const Text('Fijar GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class WorkerSelectorRow extends StatelessWidget {
  const WorkerSelectorRow({super.key, required this.label, required this.value, required this.onTap});
  final String label, value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: context.cTextPrimary)),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(CupertinoIcons.chevron_right, size: 13, color: context.cTextSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}