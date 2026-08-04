// lib/features/profile/presentation/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:intl/intl.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validators/input_validators.dart';
import '../../../../shared/widgets/professional_date_picker.dart';
import '../viewmodels/edit_profile_viewmodel.dart';

/// Editar perfil — persiste los cambios vía PUT /users/me (real).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _direccionCtrl;

  DateTime? _fechaNacimiento;
  String _cedula = '---';
  String _cargo = '---';
  String? _fotoUrl;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;
    _nombreCtrl = TextEditingController(text: user?.nombre ?? '');
    _apellidoCtrl = TextEditingController(text: user?.apellido ?? '');
    _correoCtrl = TextEditingController(text: user?.correo ?? '');
    _telefonoCtrl = TextEditingController(text: user?.telefono ?? '');
    _direccionCtrl = TextEditingController(text: user?.direccion ?? '');

    if (user?.fechaNacimiento != null && user!.fechaNacimiento!.isNotEmpty) {
      try {
        _fechaNacimiento = DateTime.parse(user.fechaNacimiento!);
      } catch (_) {}
    }

    _cedula = user?.cedula ?? '---';
    _cargo = user?.cargo ?? 'Empleado';
    _fotoUrl = AppConfig.fullPhotoUrl(user?.fotoUrl);
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    final user = await ref
        .read(editProfileViewModelProvider.notifier)
        .uploadPhoto(picked.path);
    if (!mounted) return;

    if (user != null) {
      await ref
          .read(sessionControllerProvider.notifier)
          .authenticate(user, remember: true);
      setState(() {
        _fotoUrl = AppConfig.fullPhotoUrl(user.fotoUrl);
        _uploadingPhoto = false;
      });
    } else {
      setState(() => _uploadingPhoto = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.lightImpact();

    final birthdateStr = _fechaNacimiento != null
        ? DateFormat('yyyy-MM-dd').format(_fechaNacimiento!)
        : null;

    final viewModel = ref.read(editProfileViewModelProvider.notifier);
    final user = await viewModel.save(
      nombre: _nombreCtrl.text,
      apellido: _apellidoCtrl.text,
      correo: _correoCtrl.text,
      fechaNacimiento: birthdateStr,
      telefono: _telefonoCtrl.text,
      direccion: _direccionCtrl.text,
    );

    if (!mounted) return;
    if (user != null) {
      await ref.read(sessionControllerProvider.notifier).authenticate(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Perfil actualizado correctamente en CONTROL AI'),
              ],
            ),
            backgroundColor: AppColors.systemGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      context.pop();
    } else {
      final state = ref.read(editProfileViewModelProvider);
      if (state is EditProfileError && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.systemRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
      }
      ref.read(editProfileViewModelProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileViewModelProvider);
    final saving = state is EditProfileSaving;

    final initialChar =
        _nombreCtrl.text.isNotEmpty ? _nombreCtrl.text[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppBar(
        backgroundColor: context.cSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Editar Perfil',
          style: TextStyle(
            color: context.cTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.41,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar con foto/incial y badge de edición ──
                GestureDetector(
                  onTap: _pickAndUploadPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        backgroundImage:
                            _fotoUrl != null && _fotoUrl!.isNotEmpty
                                ? NetworkImage(_fotoUrl!)
                                : null,
                        child: _fotoUrl == null || _fotoUrl!.isEmpty
                            ? Text(initialChar,
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: _uploadingPhoto
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.edit,
                                  size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Chip Corporativo read-only ──
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'CONTROL AI · $_cargo · C.C. $_cedula',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Form fields ──
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: _inputDecoration('Nombre', Icons.person),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apellidoCtrl,
                  decoration: _inputDecoration('Apellido', Icons.badge),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El apellido es obligatorio'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      _inputDecoration('Correo Electrónico', Icons.mail),
                  validator: (v) => InputValidators.validateEmail(v),
                ),
                const SizedBox(height: 16),

                // ── Fecha de Nacimiento (Calendario Profesional) ──
                ProfessionalDatePicker(
                  label: 'Fecha de Nacimiento',
                  initialDate: _fechaNacimiento,
                  onChanged: (d) => setState(() => _fechaNacimiento = d),
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration:
                      _inputDecoration('Teléfono / Celular', Icons.call),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: _inputDecoration(
                      'Dirección de Residencia', Icons.location_on),
                ),

                const SizedBox(height: 32),

                // ── Botón Guardar ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'GUARDAR CAMBIOS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: context.cSurface,
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
