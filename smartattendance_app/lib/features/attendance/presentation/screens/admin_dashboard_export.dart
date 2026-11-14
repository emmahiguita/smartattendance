// ============================================================================
// ARCHIVO: admin_dashboard_export.dart
// QUÉ HACE: Sección de exportación de reportes Excel con selector de fechas
//           y botones de acción (Exportar, Registrar Empleado, Generar QR).
// CÓMO FUNCIONA: Usa DatePicker nativo de Material 3 para seleccionar rango.
//                Los botones lanzan diálogos modales específicos del padre.
// POR QUÉ: Extraído de admin_dashboard_screen.dart para cumplir SRP (< 200 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

// QUÉ HACE: Panel con selector de fechas y botones de acción del admin.
// CÓMO: Recibe las fechas y callbacks para cada acción (export, registro, QR).
// POR QUÉ: Widget puro sin estado propio; el padre maneja las fechas.
class AdminExportSection extends StatelessWidget {
  const AdminExportSection({
    super.key,
    required this.exportFrom,
    required this.exportTo,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onExportExcel,
    required this.onRegisterUser,
    required this.onGenerateQr,
  });

  /// Fecha de inicio del rango de exportación.
  final DateTime? exportFrom;

  /// Fecha de fin del rango de exportación.
  final DateTime? exportTo;

  /// Callback cuando cambia la fecha "Desde".
  final ValueChanged<DateTime> onFromChanged;

  /// Callback cuando cambia la fecha "Hasta".
  final ValueChanged<DateTime> onToChanged;

  /// Callback para exportar reporte Excel.
  final VoidCallback onExportExcel;

  /// Callback para abrir diálogo de registro de empleados.
  final VoidCallback onRegisterUser;

  /// Callback para abrir diálogo de generación QR.
  final VoidCallback onGenerateQr;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cSurface,
        border: Border.all(color: context.cBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección.
          Text(
            'Exportar Reporte',
            style: TextStyle(
              color: context.cTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // QUÉ HACE: Wrap adaptativo con los selectores de fecha y botones.
          // POR QUÉ: Wrap evita overflow en pantallas angostas.
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Desde',
                  style:
                      TextStyle(color: context.cTextSecondary, fontSize: 14)),
              _DateChip(
                label: exportFrom != null
                    ? dateFmt.format(exportFrom!)
                    : 'Seleccionar',
                onTap: () => _pickDate(context, exportFrom, onFromChanged),
              ),
              Text('Hasta',
                  style:
                      TextStyle(color: context.cTextSecondary, fontSize: 14)),
              _DateChip(
                label: exportTo != null
                    ? dateFmt.format(exportTo!)
                    : 'Seleccionar',
                onTap: () => _pickDate(context, exportTo, onToChanged),
              ),

              // Botones de acción del administrador.
              _ActionButton(
                icon: Icons.download,
                label: 'EXPORTAR EXCEL',
                color: AppColors.primary,
                onPressed: onExportExcel,
              ),
              _ActionButton(
                icon: Icons.person_add,
                label: 'REGISTRAR EMPLEADO',
                color: AppColors.primary,
                onPressed: onRegisterUser,
              ),
              _ActionButton(
                icon: Icons.qr_code,
                label: 'GENERAR QR',
                color: AppColors.systemGreen,
                onPressed: onGenerateQr,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // QUÉ HACE: Abre DatePicker nativo de Material 3 y notifica al padre.
  Future<void> _pickDate(
    BuildContext context,
    DateTime? initial,
    ValueChanged<DateTime> onPicked,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) onPicked(picked);
  }
}

// QUÉ HACE: Chip interactivo que muestra una fecha y abre DatePicker al tocar.
class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: context.cBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Icon(Icons.calendar_today,
                size: 16, color: context.cTextSecondary),
          ],
        ),
      ),
    );
  }
}

// QUÉ HACE: Botón Material 3 FilledButton con ícono para acciones del admin.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

/// Datos de una tarjeta KPI del dashboard (título, valor, ícono, color).
class KpiData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  const KpiData(this.title, this.value, this.icon, this.color);
}
