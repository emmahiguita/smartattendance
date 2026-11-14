// ============================================================================
// ARCHIVO: worker_dialog_fields.dart
// QUÉ HACE: Formulario plano sin cards para alta de personal operativo o mandos:
//           - Secciones directas con divisores finos (0.5px) y ritmo compacto.
//           - Colores neutros de alta legibilidad (sin textos ni bordes azules).
//           - Identificación personal, nivel de acceso RBAC, jornada y cuadrilla.
// CÓMO FUNCIONA: Elimina cajas/cards y presenta filas directas y fluidas.
// POR QUÉ: Cumple la directiva estricta de modularización (< 195 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/location_address_map_picker.dart';
import '../domain/shift_template.dart';
import 'worker_password_fields.dart';

class WorkerDialogFields extends StatelessWidget {
  const WorkerDialogFields({
    super.key,
    required this.nameCtrl,
    required this.docCtrl,
    required this.jobCtrl,
    required this.addressCtrl,
    required this.passwordCtrl,
    required this.confirmPasswordCtrl,
    required this.selectedTemplate,
    required this.toleranceMode,
    required this.crewName,
    required this.gpsLat,
    required this.gpsLng,
    required this.isStrictAdmin,
    required this.onPickRole,
    required this.onPickSchedule,
    required this.onPickTolerance,
    required this.onPickCrew,
    required this.onLocationChanged,
  });

  final TextEditingController nameCtrl, docCtrl, jobCtrl, addressCtrl;
  final TextEditingController passwordCtrl, confirmPasswordCtrl;
  final ShiftTemplate? selectedTemplate;
  final String toleranceMode;
  final String? crewName;
  final double? gpsLat, gpsLng;
  final bool isStrictAdmin;
  final VoidCallback onPickRole, onPickSchedule, onPickTolerance, onPickCrew;
  final void Function(LatLng pt, String addr) onLocationChanged;

  Widget _div(BuildContext context, {double indent = 38}) => Divider(
      height: 1,
      thickness: 0.5,
      indent: indent,
      color: context.cBorder.withValues(alpha: 0.45));

  Widget _hdr(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 5),
        child: Text(title,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: context.isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B))),
      );

  Widget _iconBox(BuildContext context, IconData icon) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            color: context.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(7)),
        child: Icon(icon,
            size: 14,
            color: context.isDark
                ? const Color(0xFFCBD5E1)
                : const Color(0xFF475569)),
      );

  Widget _fieldRow(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController ctrl,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization cap = TextCapitalization.none,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          _iconBox(context, icon),
          const SizedBox(width: 10),
          SizedBox(
              width: 90,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.cTextSecondary))),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboard,
              textCapitalization: cap,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: context.cTextPrimary),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: TextStyle(
                    fontSize: 12,
                    color: context.cTextSecondary.withValues(alpha: 0.65)),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
              ),
            ),
          ),
        ]),
      );

  Widget _selectRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            _iconBox(context, icon),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.cTextSecondary)),
            const Spacer(),
            Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.cTextPrimary))),
            const SizedBox(width: 4),
            Icon(CupertinoIcons.chevron_right,
                size: 13, color: context.cTextSecondary),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final initialPt =
        (gpsLat != null && gpsLng != null) ? LatLng(gpsLat!, gpsLng!) : null;
    final tmplLabel = selectedTemplate != null
        ? '${selectedTemplate!.name} · ${selectedTemplate!.timeFormattedDual}'
        : 'Seleccionar turno';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _hdr(context, 'DATOS PERSONALES Y ACCESO'),
      _div(context, indent: 0),
      _fieldRow(context,
          label: 'Nombre completo',
          hint: 'Nombres y apellidos',
          ctrl: nameCtrl,
          icon: CupertinoIcons.person_fill,
          cap: TextCapitalization.words),
      _div(context),
      _fieldRow(context,
          label: 'Cédula',
          hint: 'De 6 a 13 dígitos',
          ctrl: docCtrl,
          icon: CupertinoIcons.number,
          keyboard: TextInputType.number),
      _div(context),
      _selectRow(context,
          label: 'Rol / Nivel de acceso',
          value: jobCtrl.text.isEmpty ? 'Colaborador' : jobCtrl.text,
          icon: CupertinoIcons.shield_fill,
          onTap: onPickRole),
      WorkerPasswordFields(
          password: passwordCtrl, confirmation: confirmPasswordCtrl),
      _div(context, indent: 0),
      const SizedBox(height: 14),
      _hdr(context, 'JORNADA LABORAL Y HORARIOS'),
      _div(context, indent: 0),
      _selectRow(context,
          label: 'Turno asignado',
          value: tmplLabel,
          icon: CupertinoIcons.clock_fill,
          onTap: onPickSchedule),
      _div(context),
      _selectRow(context,
          label: 'Rango de marcación',
          value: toleranceMode,
          icon: CupertinoIcons.timer_fill,
          onTap: onPickTolerance),
      _div(context, indent: 0),
      const SizedBox(height: 14),
      _hdr(context, 'ASIGNACIÓN DE EQUIPO'),
      _div(context, indent: 0),
      _selectRow(context,
          label: isStrictAdmin ? 'Cuadrilla' : 'Mi cuadrilla asignada',
          value: crewName ?? 'Sin cuadrilla',
          icon: CupertinoIcons.person_2_fill,
          onTap: onPickCrew),
      _div(context, indent: 0),
      const SizedBox(height: 14),
      _hdr(context, 'NUEVO SITIO PARA TODO EL EQUIPO'),
      const SizedBox(height: 6),
      LocationAddressMapPicker(
          addressCtrl: addressCtrl,
          initialPoint: initialPt,
          mapHeight: 155,
          onLocationChanged: onLocationChanged),
    ]);
  }
}
