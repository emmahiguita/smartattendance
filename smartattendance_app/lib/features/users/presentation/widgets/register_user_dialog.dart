// ============================================================================
// ARCHIVO: register_user_dialog.dart
// QUÉ HACE: Diálogo modal para registrar personal y sincronizar ubicación en mapa:
//           - Valida formulario e impide colisión con el Super Usuario Creador.
//           - Audita permisos: Administrador (todos los roles) vs Supervisor (solo operarios).
//           - Sincroniza ubicación GPS/geocerca real y persiste en el backend y SQLite local.
// CÓMO FUNCIONA: Delega inputs y mapa a `RegisterUserFormFields`, valida reglas RBAC
//                y persiste a través de `usersRepositoryProvider` y `LocalAdminStore`.
// POR QUÉ: Respeta la jerarquía operativa sin duplicidad ni escalamiento (< 250 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enterprise_colors.dart';
import '../../../../core/utils/roles.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../viewmodels/users_viewmodel.dart';
import 'register_user_form_fields.dart';

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
  final _cargoCtrl = TextEditingController(text: 'Operario');
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  String _selectedCategoria = 'Operario';
  DateTime? _fechaNacimiento;
  LatLng? _selectedLocation;
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

    final doc = _cedulaCtrl.text.trim();
    // Auditoría estricta de permisos RBAC
    final actor = widget.ref.read(localActorProvider);
    final targetRole = _cargoCtrl.text.trim();
    if (!actor.isStrictAdmin && (AppRoles.isStrictAdmin(targetRole) || AppRoles.isSupervisorOrManager(targetRole))) {
      setState(() {
        _loading = false;
        _errorMessage = 'Como supervisor o encargado solo puedes dar de alta personal operativo para tu equipo.';
      });
      return;
    }

    try {
      final repository = widget.ref.read(usersRepositoryProvider);
      final birthdateStr = _fechaNacimiento != null
          ? DateFormat('yyyy-MM-dd').format(_fechaNacimiento!)
          : null;

      await repository.createUser(
        cedula: doc,
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        cargo: targetRole,
        fechaNacimiento: birthdateStr,
        telefono: _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
      );

      // Sincronización de geocerca real en SQLite si se fijaron coordenadas
      if (_selectedLocation != null) {
        try {
          final store = widget.ref.read(localAdminStoreProvider);
          await store.saveZone({
            'name': 'Puesto ${_nombreCtrl.text.trim().split(' ').first} (${_cargoCtrl.text.trim()})',
            'address': _direccionCtrl.text.trim().isNotEmpty ? _direccionCtrl.text.trim() : 'Dosquebradas, Risaralda',
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
            'radius_m': 100.0,
          });
        } catch (_) {}
      }

      widget.ref.invalidate(usersViewModelProvider);
      widget.ref.invalidate(localWorkersProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = ErrorHandler.handle(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = widget.ref.watch(localActorProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person_add, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            actor.isStrictAdmin ? 'Registrar Personal / Rol' : 'Registrar Operario de Equipo',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.cTextPrimary, letterSpacing: -0.5),
                          ),
                          Text(
                            actor.isStrictAdmin ? 'Gestión Central · Serviciudad E.S.P.' : 'Líder de Cuadrilla · Serviciudad E.S.P.',
                            style: TextStyle(fontSize: 12, color: context.cGray),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: context.cGray),
                      onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.systemRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.systemRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: AppColors.systemRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_errorMessage!, style: const TextStyle(color: AppColors.systemRed, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                RegisterUserFormFields(
                  cedulaCtrl: _cedulaCtrl,
                  nombreCtrl: _nombreCtrl,
                  apellidoCtrl: _apellidoCtrl,
                  correoCtrl: _correoCtrl,
                  cargoCtrl: _cargoCtrl,
                  telefonoCtrl: _telefonoCtrl,
                  direccionCtrl: _direccionCtrl,
                  selectedCategoria: _selectedCategoria,
                  isStrictAdmin: actor.isStrictAdmin,
                  onCategoriaChanged: (val) {
                    setState(() {
                      _selectedCategoria = val;
                      if (val != '+ Otra categoría...') {
                        _cargoCtrl.text = val;
                      } else {
                        _cargoCtrl.clear();
                      }
                    });
                  },
                  fechaNacimiento: _fechaNacimiento,
                  onFechaChanged: (d) => setState(() => _fechaNacimiento = d),
                  onLocationChanged: (pt, addr) => _selectedLocation = pt,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: EnterpriseColors.accentBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              children: [
                                Icon(Icons.check, size: 17),
                                SizedBox(width: 6),
                                Text('GUARDAR Y VINCULAR', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
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
}
