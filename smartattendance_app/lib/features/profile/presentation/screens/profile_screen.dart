// ============================================================================
// ARCHIVO: profile_screen.dart
// QUÉ HACE: Muestra identidad, expediente y opciones de la cuenta estilo iOS.
// CÓMO FUNCIONA: Organiza el contenido en secciones planas con divisores finos
//                de 0.5px y márgenes compactos sin tarjetas decorativas.
// POR QUÉ: Aprovecha la pantalla sin separaciones exageradas (< 105 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/confirm_logout.dart';
import '../../../../core/utils/employee_avatar_service.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/worker_dialog.dart';
import '../widgets/profile_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _cleanCargo(String? raw) {
    final value = (raw ?? '').trim();
    if (value == 'super_admin') return 'Administrador general';
    return value.isEmpty ? 'Sin cargo registrado' : value;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;
    final isAdmin = ref.watch(localActorProvider).isAdmin;
    final avatarFile =
        EmployeeAvatarService.resolveFile(user?.fotoUrl, user?.cedula);
    final initial =
        (user?.nombre ?? '').isEmpty ? '?' : user!.nombre[0].toUpperCase();

    final bottomClearance = MediaQuery.paddingOf(context).bottom + 94;

    return ColoredBox(
      color: context.isDark ? Colors.black : context.cBackground,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 14, 16, bottomClearance),
            children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: 'Actualizar foto de perfil',
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () =>
                      EmployeeAvatarService.pickAndSavePhoto(context, ref, user),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: context.cSurface,
                    foregroundColor: context.cTextPrimary,
                    backgroundImage:
                        avatarFile != null ? FileImage(avatarFile) : null,
                    child: avatarFile == null
                        ? Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Cuenta',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: context.cTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _cleanCargo(user?.cargo),
                      style: TextStyle(
                        fontSize: 13.5,
                        color: context.cTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: context.cTextPrimary,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () =>
                    EmployeeAvatarService.pickAndSavePhoto(context, ref, user),
                icon: const Icon(CupertinoIcons.camera, size: 16),
                label: const Text(
                  'Foto',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ProfileSection(
            header: 'EXPEDIENTE',
            children: [
              ProfileInfoRow(
                CupertinoIcons.person_crop_rectangle,
                'Documento',
                user?.cedula ?? 'Sin registrar',
              ),
              ProfileInfoRow(
                CupertinoIcons.briefcase,
                'Cargo',
                _cleanCargo(user?.cargo),
              ),
            ],
          ),
          ProfileSection(
            header: 'CUENTA',
            children: [
              ProfileActionRow(
                icon: CupertinoIcons.pencil,
                label: 'Editar perfil',
                onTap: () => context.push(AppRoutes.profileEdit),
              ),
              if (isAdmin)
                ProfileActionRow(
                  icon: CupertinoIcons.person_badge_plus,
                  label: 'Registrar nuevo colaborador',
                  onTap: () => WorkerDialog.open(context),
                ),
              ProfileActionRow(
                icon: CupertinoIcons.slider_horizontal_3,
                label: 'Configuración',
                onTap: () => context.push(AppRoutes.settings),
              ),
              ProfileActionRow(
                icon: CupertinoIcons.square_arrow_right,
                label: 'Cerrar sesión',
                onTap: () => confirmLogout(context, ref),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }
}
