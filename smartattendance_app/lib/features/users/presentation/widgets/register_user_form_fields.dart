// ============================================================================
// ARCHIVO: register_user_form_fields.dart
// QUÉ HACE: Campos del formulario de registro de empleado para CONTROL AI:
//           - Cédula, Categoría/Rol restringido según permisos (Admin vs Supervisor).
//           - Nombres, Apellidos, Correo institucional.
//           - Selector de Fecha de Nacimiento profesional.
//           - Teléfono y Ubicación/Dirección con mapa Google Maps interactivo.
// CÓMO FUNCIONA: Desacopla los inputs del diálogo principal y delega la ubicación
//                al componente satelital `LocationAddressMapPicker`.
// POR QUÉ: Respeta la regla de modularización estricta (< 200 líneas) y Clean Architecture.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/roles.dart';
import '../../../../core/validators/input_validators.dart';
import '../../../../shared/widgets/location_address_map_picker.dart';
import '../../../../shared/widgets/professional_date_picker.dart';

class RegisterUserFormFields extends StatelessWidget {
  final TextEditingController cedulaCtrl;
  final TextEditingController nombreCtrl;
  final TextEditingController apellidoCtrl;
  final TextEditingController correoCtrl;
  final TextEditingController cargoCtrl;
  final TextEditingController telefonoCtrl;
  final TextEditingController direccionCtrl;
  final String selectedCategoria;
  final ValueChanged<String> onCategoriaChanged;
  final DateTime? fechaNacimiento;
  final ValueChanged<DateTime?> onFechaChanged;
  final bool isStrictAdmin;
  final void Function(LatLng point, String address)? onLocationChanged;

  const RegisterUserFormFields({
    super.key,
    required this.cedulaCtrl,
    required this.nombreCtrl,
    required this.apellidoCtrl,
    required this.correoCtrl,
    required this.cargoCtrl,
    required this.telefonoCtrl,
    required this.direccionCtrl,
    required this.selectedCategoria,
    required this.onCategoriaChanged,
    required this.fechaNacimiento,
    required this.onFechaChanged,
    this.isStrictAdmin = true,
    this.onLocationChanged,
  });

  bool get _isOtraCategoria => selectedCategoria == '+ Otra categoría...';

  List<String> get _categorias => AppRoles.allowedAssignableRoles(isStrictAdminUser: isStrictAdmin);

  InputDecoration _inputDeco(BuildContext context, String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: context.cSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.cGray4.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    final categorias = _categorias;
    final currentCat = categorias.contains(selectedCategoria) ? selectedCategoria : categorias.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: cedulaCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDeco(context, 'Cédula', Icons.badge),
                validator: (v) => InputValidators.validateCedula(v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: DropdownButtonFormField<String>(
                initialValue: currentCat,
                decoration: _inputDeco(context, 'Categoría / Rol', Icons.work),
                items: categorias.map((cat) {
                  final isAdd = cat.startsWith('+');
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isAdd ? FontWeight.w700 : FontWeight.w500,
                        color: isAdd ? AppColors.primary : null,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onCategoriaChanged(val);
                },
              ),
            ),
          ],
        ),

        if (_isOtraCategoria) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: cargoCtrl,
            decoration: _inputDeco(context, 'Escribe el nuevo cargo o categoría', Icons.add_circle_outline),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del nuevo cargo' : null,
          ),
        ],

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: nombreCtrl,
                decoration: _inputDeco(context, 'Nombre', Icons.person),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: apellidoCtrl,
                decoration: _inputDeco(context, 'Apellido', Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: correoCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDeco(context, 'Correo Electrónico', Icons.mail),
          validator: (v) => InputValidators.validateEmail(v),
        ),

        const SizedBox(height: 14),

        ProfessionalDatePicker(
          label: 'Fecha de Nacimiento',
          initialDate: fechaNacimiento,
          onChanged: onFechaChanged,
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: telefonoCtrl,
          keyboardType: TextInputType.phone,
          decoration: _inputDeco(context, 'Teléfono / Celular', Icons.call),
        ),

        const SizedBox(height: 14),

        // Selector con buscador de dirección y mapa interactivo
        LocationAddressMapPicker(
          addressCtrl: direccionCtrl,
          onLocationChanged: onLocationChanged,
          mapHeight: 145,
        ),
      ],
    );
  }
}
