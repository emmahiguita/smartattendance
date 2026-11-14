// ============================================================================
// ARCHIVO: edit_profile_screen.dart
// QUÉ HACE: Pantalla de edición de perfil estilo Apple iOS Profesional —
//           orquesta estado, carga de foto y guardado real vía PUT /users/me.
// CÓMO FUNCIONA: Pre-llena datos desde la sesión activa, maneja subida de avatar
//                a través de ImagePicker y delega la UI en ProfileAvatarSection
//                y ProfileFormFields sin desbordamientos.
// POR QUÉ: SRP y regla estricta de modularización < 200 líneas sin mocks.
// ============================================================================

import 'package:flutter/cupertino.dart';
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
import '../viewmodels/edit_profile_viewmodel.dart';
import '../widgets/profile_avatar_section.dart';
import '../widgets/profile_form_fields.dart';

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
  String? _resolvedPhotoUrl;
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
    _resolvedPhotoUrl = _resolvePhotoUrl(user?.fotoUrl);
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

  String? _resolvePhotoUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('/') || raw.startsWith('file://')) return raw;
    return AppConfig.fullPhotoUrl(raw);
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );
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
        _resolvedPhotoUrl = _resolvePhotoUrl(user.fotoUrl);
        _uploadingPhoto = false;
      });
    } else {
      setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.lightImpact();

    final birthdateStr = _fechaNacimiento != null
        ? DateFormat('yyyy-MM-dd').format(_fechaNacimiento!)
        : null;
    final notifier = ref.read(editProfileViewModelProvider.notifier);
    final user = await notifier.save(
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
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Flexible(
                  child: Text('Perfil actualizado correctamente'),
                ),
              ],
            ),
            backgroundColor: AppColors.systemGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
      }
      notifier.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileViewModelProvider);
    final saving = state is EditProfileSaving;
    final initialChar = _nombreCtrl.text.isNotEmpty
        ? _nombreCtrl.text[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppBar(
        backgroundColor: context.cBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Editar Perfil',
          style: TextStyle(
            color: context.cTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16.5,
            letterSpacing: -0.35,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.chevron_back,
            size: 20,
            color: context.cTextPrimary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: context.cBorder),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileAvatarSection(
                resolvedPhotoUrl: _resolvedPhotoUrl,
                initialChar: initialChar,
                cargo: _cargo,
                cedula: _cedula,
                uploadingPhoto: _uploadingPhoto,
                onTap: _pickAndUploadPhoto,
              ),
              const SizedBox(height: 16),
              ProfileFormFields(
                formKey: _formKey,
                nombreCtrl: _nombreCtrl,
                apellidoCtrl: _apellidoCtrl,
                correoCtrl: _correoCtrl,
                telefonoCtrl: _telefonoCtrl,
                direccionCtrl: _direccionCtrl,
                fechaNacimiento: _fechaNacimiento,
                onFechaChanged: (d) => setState(() => _fechaNacimiento = d),
                saving: saving,
                onSave: _save,
                onFieldChanged: () => setState(() {}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
