// ============================================================================
// ARCHIVO: professional_date_picker.dart
// QUÉ HACE: Selector de fecha de nacimiento estilo Apple iOS con divisor fino
//           de 0.5px, cálculo automático de edad y alto contraste en modo oscuro.
// CÓMO FUNCIONA: Muestra fila compacta con icono de calendario, fecha formateada
//                `dd/MM/yyyy` y chip de edad sin desbordamientos.
// POR QUÉ: Unifica la estética iOS con el resto del formulario (< 195 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class ProfessionalDatePicker extends StatefulWidget {
  final String label;
  final DateTime? initialDate;
  final ValueChanged<DateTime?> onChanged;
  final String? Function(DateTime?)? validator;
  final bool enabled;

  const ProfessionalDatePicker({
    super.key,
    this.label = 'Fecha de Nacimiento',
    this.initialDate,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  State<ProfessionalDatePicker> createState() => _ProfessionalDatePickerState();
}

class _ProfessionalDatePickerState extends State<ProfessionalDatePicker> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  void didUpdateWidget(covariant ProfessionalDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _selectedDate = widget.initialDate;
    }
  }

  int? get _calculateAge {
    if (_selectedDate == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    if (now.month < _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  Future<void> _pickDate() async {
    if (!widget.enabled) return;

    final now = DateTime.now();
    final firstDate = DateTime(1940, 1, 1);
    final lastDate = DateTime(now.year - 14, now.month, now.day);
    final defaultInitial = _selectedDate ?? DateTime(now.year - 25, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: defaultInitial.isBefore(firstDate)
          ? firstDate
          : (defaultInitial.isAfter(lastDate) ? lastDate : defaultInitial),
      firstDate: firstDate,
      lastDate: now,
      helpText: 'SELECCIONAR FECHA DE NACIMIENTO',
      cancelText: 'CANCELAR',
      confirmText: 'SELECCIONAR',
      fieldLabelText: 'Fecha',
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      widget.onChanged(picked);
    }
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final age = _calculateAge;
    final formattedDate = _selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
        : null;

    return FormField<DateTime>(
      initialValue: _selectedDate,
      validator: (_) => widget.validator?.call(_selectedDate),
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: widget.enabled ? _pickDate : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        CupertinoIcons.calendar,
                        size: 15,
                        color: context.cTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: context.cTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formattedDate ?? 'Seleccionar en calendario',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: formattedDate != null
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: formattedDate != null
                                  ? context.cTextPrimary
                                  : context.cTextSecondary
                                      .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (age != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.cBorder, width: 0.5),
                        ),
                        child: Text(
                          '$age años',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: context.cTextPrimary,
                          ),
                        ),
                      ),
                    if (_selectedDate != null && widget.enabled)
                      GestureDetector(
                        onTap: _clearDate,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            CupertinoIcons.clear_circled_solid,
                            size: 16,
                            color: context.cTextSecondary,
                          ),
                        ),
                      )
                    else
                      Icon(
                        CupertinoIcons.chevron_forward,
                        size: 14,
                        color: context.cTextSecondary,
                      ),
                  ],
                ),
              ),
            ),
            if (state.hasError && state.errorText != null)
              Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 4),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.systemRed,
                  ),
                ),
              ),
            Divider(height: 1, thickness: 0.5, color: context.cBorder),
          ],
        );
      },
    );
  }
}
