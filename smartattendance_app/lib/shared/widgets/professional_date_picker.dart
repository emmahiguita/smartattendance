// lib/shared/widgets/professional_date_picker.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Control de formulario profesional para selección de Fecha de Nacimiento.
/// Incluye:
/// - Modal con selector interactivo de año y mes.
/// - Cálculo automático de la edad en años.
/// - Formato visual estandarizado `DD/MM/YYYY`.
/// - Rango de fechas restringido a edades laborales (1940 - fecha actual).
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
    final lastDate =
        DateTime(now.year - 14, now.month, now.day); // Edad mínima 14 años
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
      builder: (context, child) {
        // Hereda el brillo del tema activo (antes forzaba ColorScheme.light
        // siempre → el diálogo de fecha quedaba claro en dark mode).
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
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
    final age = _calculateAge;
    final formattedDate = _selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
        : null;

    return FormField<DateTime>(
      initialValue: _selectedDate,
      validator: (val) => widget.validator?.call(_selectedDate),
      builder: (state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: widget.enabled ? _pickDate : null,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: widget.label,
                  prefixIcon: const Icon(Icons.calendar_month,
                      color: AppColors.primary),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (age != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '$age años',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      if (_selectedDate != null && widget.enabled)
                        IconButton(
                          icon:
                              Icon(Icons.close, size: 18, color: context.cGray),
                          onPressed: _clearDate,
                          tooltip: 'Borrar fecha',
                        ),
                    ],
                  ),
                  filled: true,
                  fillColor: context.cSurface,
                  errorText: state.errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: hasError
                          ? AppColors.systemRed
                          : context.cGray4.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                child: Text(
                  formattedDate ?? 'DD/MM/AAAA (Seleccionar calendario)',
                  style: TextStyle(
                    fontSize: 15,
                    color: formattedDate != null
                        ? context.cTextPrimary
                        : context.cGray,
                    fontWeight: formattedDate != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
