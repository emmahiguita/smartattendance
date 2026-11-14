// ============================================================================
// ARCHIVO: consolidated_table_row.dart
// CAPA: Presentation / Consolidated / Widgets
// QUÉ HACE: Construye una fila interactiva `DataRow` para la tabla consolidada.
// CÓMO FUNCIONA: Mapea cada celda permitiendo editar al pulsar en ella o en el lápiz.
// POR QUÉ: Permite editar la información completa con un solo toque y alto contraste
//          en modo oscuro OLED (< 195 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../models/consolidated_record.dart';

class ConsolidatedTableRow {
  const ConsolidatedTableRow._();

  /// QUÉ HACE: Crea la fila `DataRow` con celdas legibles e interactivas.
  /// CÓMO: Asigna colores semánticos de alto contraste sobre `#000000` / `#111111`.
  /// POR QUÉ: Evita textos oscuros invisibles en modo oscuro y permite editar rápido.
  static DataRow build({
    required BuildContext context,
    required ConsolidatedRecord record,
    required bool isSelected,
    required bool isEven,
    required ValueChanged<String> onToggleSelect,
    required ValueChanged<ConsolidatedRecord> onEdit,
  }) {
    final isDark = context.isDark;
    final isClosed = record.estado == 'Cerrada';
    final isVoid = record.estado == 'Anulada';

    final statusColor = isVoid
        ? AppColors.systemRed
        : (isClosed ? AppColors.success : AppColors.warning);

    return DataRow(
      selected: isSelected,
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (isSelected) {
          return isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.06);
        }
        if (isEven) {
          return isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.015);
        }
        return Colors.transparent;
      }),
      onSelectChanged: (_) => onToggleSelect(record.journeyId),
      cells: [
        DataCell(
          SizedBox(
            width: 30,
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => onToggleSelect(record.journeyId),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
        DataCell(
          onTap: () => onEdit(record),
          SizedBox(
            width: 165,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.colaborador,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.cTextPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  record.cargo,
                  style: TextStyle(fontSize: 10, color: context.cTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        DataCell(
          onTap: () => onEdit(record),
          SizedBox(
            width: 110,
            child: Text(
              record.cedula,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: context.cTextPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        DataCell(
          onTap: () => onEdit(record),
          SizedBox(
            width: 175,
            child: Text(
              record.zona,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: context.cTextPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          onTap: () => onEdit(record),
          SizedBox(
            width: 90,
            child: Text(record.fechaFormatted, style: TextStyle(fontSize: 11, color: context.cTextPrimary)),
          ),
        ),
        DataCell(
          onTap: () => onEdit(record),
          SizedBox(
            width: 80,
            child: Text(
              record.entrada,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: record.entrada != '-' ? AppColors.success : context.cTextSecondary,
              ),
            ),
          ),
        ),
        DataCell(
          onTap: () => onEdit(record),
          SizedBox(
            width: 80,
            child: Text(
              record.salida,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: record.salida != '-' ? context.cTextPrimary : context.cTextSecondary,
              ),
            ),
          ),
        ),
        DataCell(
          onTap: () => onEdit(record),
          SizedBox(
            width: 75,
            child: Text(
              record.horas,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.cTextPrimary),
            ),
          ),
        ),
        DataCell(
          onTap: () => onEdit(record),
          SizedBox(
            width: 80,
            child: Text(
              record.extras,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: record.extras != '0h 00m' ? AppColors.warning : context.cTextSecondary,
              ),
            ),
          ),
        ),
        DataCell(
          onTap: () => onEdit(record),
          SizedBox(
            width: 85,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                record.estado,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 44,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(28, 28),
              onPressed: () => onEdit(record),
              child: Icon(
                CupertinoIcons.pencil_circle_fill,
                size: 22,
                color: context.cTextPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
