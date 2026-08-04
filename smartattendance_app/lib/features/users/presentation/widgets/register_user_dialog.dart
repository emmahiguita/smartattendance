// lib/features/users/presentation/widgets/register_user_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enterprise_colors.dart';
import '../../../../core/validators/input_validators.dart';
import '../../../../shared/widgets/professional_date_picker.dart';
import '../viewmodels/users_viewmodel.dart';

/// Modal dialog para Registrar Nuevo Empleado en CONTROL AI.
/// Incluye todos los campos requeridos:
/// - Cédula, Nombre, Apellido, Correo, Cargo
/// - Fecha de Nacimiento (con calendario profesional)
/// - Teléfono
/// - Dirección de Residencia
Future<bool?> showRegisterUserDialog(BuildContext context, WidgetRef ref) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _RegisterUserDialog(ref: ref),
  );
}

class _RegisterUserDialog extends StatefulWidget {
  final WidgetRef ref;
  const _RegisterUserDialog({required this.ref});

  @override
  State<_RegisterUserDialog> createState() => _RegisterUserDialogState();
}

class _RegisterUserDialogState extends State<_RegisterUserDialog> {
  final _formKey = GlobalKey<FormState>();

  final _cedulaCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _cargoCtrl = TextEditingController(text: 'Empleado');
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  DateTime? _fechaNacimiento;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _correoCtrl.dispose();
    _cargoCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final repository = widget.ref.read(usersRepositoryProvider);

      final birthdateStr = _fechaNacimiento != null
          ? DateFormat('yyyy-MM-dd').format(_fechaNacimiento!)
          : null;

      await repository.createUser(
        cedula: _cedulaCtrl.text.trim(),
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        cargo: _cargoCtrl.text.trim(),
        fechaNacimiento: birthdateStr,
        telefono: _telefonoCtrl.text.trim().isEmpty
            ? null
            : _telefonoCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim().isEmpty
            ? null
            : _direccionCtrl.text.trim(),
      );

      // Refresh list of users
      widget.ref.invalidate(usersViewModelProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // Mensaje normalizado vía ErrorHandler (400/409/network → texto claro).
        _errorMessage = ErrorHandler.handle(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person_add,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registrar Empleado',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: context.cTextPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Complete el formulario de registro para CONTROL AI',
                            style:
                                TextStyle(fontSize: 13, color: context.cGray),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: context.cGray),
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.systemRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.systemRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error,
                            color: AppColors.systemRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: AppColors.systemRed, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Cédula & Cargo
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cedulaCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: _inputDeco('Cédula', Icons.badge),
                        validator: (v) => InputValidators.validateCedula(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cargoCtrl,
                        decoration: _inputDeco('Cargo', Icons.work),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Nombre & Apellido
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nombreCtrl,
                        decoration: _inputDeco('Nombre', Icons.person),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _apellidoCtrl,
                        decoration:
                            _inputDeco('Apellido', Icons.person_outline),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Correo Electrónico
                TextFormField(
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDeco('Correo Electrónico', Icons.mail),
                  validator: (v) => InputValidators.validateEmail(v),
                ),

                const SizedBox(height: 14),

                // Fecha de Nacimiento (Calendario Profesional)
                ProfessionalDatePicker(
                  label: 'Fecha de Nacimiento',
                  initialDate: _fechaNacimiento,
                  onChanged: (d) => setState(() => _fechaNacimiento = d),
                ),

                const SizedBox(height: 14),

                // Teléfono & Dirección
                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDeco('Teléfono / Celular', Icons.call),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _direccionCtrl,
                  decoration:
                      _inputDeco('Dirección de Residencia', Icons.location_on),
                ),

                const SizedBox(height: 28),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: EnterpriseColors.accentBlue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              children: [
                                Icon(Icons.check, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'REGISTRAR EMPLEADO',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: context.cSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.cGray4.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      );
}
