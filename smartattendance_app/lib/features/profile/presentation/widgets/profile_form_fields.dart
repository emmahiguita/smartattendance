// ============================================================================
// ARCHIVO: profile_form_fields.dart
// QUÉ HACE: Campos del formulario de edición de perfil estilo Apple iOS
//           con divisores finos de 0.5px, alto contraste y cero overflows.
// CÓMO FUNCIONA: Renderiza filas compactas con icono en contenedor neutro,
//                etiqueta clara y TextFormField sin bordes pesados.
// POR QUÉ: Reemplaza cajas Material con divisores iOS y corrige el overflow
//          del botón Guardar Cambios (< 195 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validators/input_validators.dart';
import '../../../../shared/widgets/professional_date_picker.dart';

class ProfileFormFields extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreCtrl;
  final TextEditingController apellidoCtrl;
  final TextEditingController correoCtrl;
  final TextEditingController telefonoCtrl;
  final TextEditingController direccionCtrl;
  final DateTime? fechaNacimiento;
  final ValueChanged<DateTime?> onFechaChanged;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onFieldChanged;

  const ProfileFormFields({
    super.key,
    required this.formKey,
    required this.nombreCtrl,
    required this.apellidoCtrl,
    required this.correoCtrl,
    required this.telefonoCtrl,
    required this.direccionCtrl,
    required this.fechaNacimiento,
    required this.onFechaChanged,
    required this.saving,
    required this.onSave,
    required this.onFieldChanged,
  });

  // QUÉ HACE: Construye una fila de formulario estilo iOS con divisor de 0.5px.
  // CÓMO: Combina contenedor de icono 28x28, etiqueta y TextFormField limpio.
  // POR QUÉ: Garantiza legibilidad total en modo oscuro (#000000) y compacto.
  Widget _iosFieldRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    final isDark = context.isDark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                child: Icon(icon, size: 15, color: context.cTextPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.cTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    TextFormField(
                      controller: controller,
                      keyboardType: keyboardType,
                      onChanged: onChanged,
                      validator: validator,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: context.cTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: context.cTextSecondary.withValues(alpha: 0.55),
                        ),
                        isDense: true,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 2),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorStyle: const TextStyle(fontSize: 11, height: 1.1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 0.5, color: context.cBorder),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, thickness: 0.5, color: context.cBorder),
          _iosFieldRow(
            context,
            icon: CupertinoIcons.person_fill,
            label: 'Nombre',
            hint: 'Ingresa tu nombre',
            controller: nombreCtrl,
            onChanged: (_) => onFieldChanged(),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'El nombre es obligatorio'
                : null,
          ),
          _iosFieldRow(
            context,
            icon: CupertinoIcons.person_crop_rectangle_fill,
            label: 'Apellido',
            hint: 'Ingresa tu apellido',
            controller: apellidoCtrl,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'El apellido es obligatorio'
                : null,
          ),
          _iosFieldRow(
            context,
            icon: CupertinoIcons.mail_solid,
            label: 'Correo Electrónico',
            hint: 'correo@serviciudad.gov.co',
            controller: correoCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => InputValidators.validateEmail(v),
          ),
          ProfessionalDatePicker(
            label: 'Fecha de Nacimiento',
            initialDate: fechaNacimiento,
            onChanged: onFechaChanged,
          ),
          _iosFieldRow(
            context,
            icon: CupertinoIcons.phone_fill,
            label: 'Teléfono / Celular',
            hint: 'Ej: 300 123 4567',
            controller: telefonoCtrl,
            keyboardType: TextInputType.phone,
          ),
          _iosFieldRow(
            context,
            icon: CupertinoIcons.location_solid,
            label: 'Dirección de Residencia',
            hint: 'Ej: Calle 25 # 20-30, Dosquebradas',
            controller: direccionCtrl,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed:
                        saving ? null : () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.cTextPrimary,
                      side: BorderSide(color: context.cBorder, width: 0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text(
                      'Cancelar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: saving ? null : onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: isDark ? Colors.black : Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.checkmark_alt, size: 16),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Guardar cambios',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
