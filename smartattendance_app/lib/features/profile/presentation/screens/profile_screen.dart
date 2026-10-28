// ============================================================================
// ARCHIVO: profile_screen.dart
// QUÉ HACE: Pantalla de Perfil Corporativo estilo Apple iOS Inset Grouped con
//           fotografía real interactiva del empleado, información de expediente
//           y acciones según rol.
// CÓMO FUNCIONA: Lee el usuario autenticado desde `sessionControllerProvider`,
//                permite tomar o seleccionar su foto real con `EmployeeAvatarService`
//                y verifica `localActorProvider.isAdmin`.
// POR QUÉ: Permite agregar la foto real del empleado y mantiene < 145 líneas.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/confirm_logout.dart';
import '../../../../core/utils/employee_avatar_service.dart';
import '../../../photo_attendance/presentation/local_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _cleanCargo(String? raw) {
    final v = (raw ?? '').trim();
    if (v.toLowerCase().contains('administrador')) return 'Administrador';
    if (v.toLowerCase().contains('supervisor')) return 'Supervisor Operativo';
    return v.isEmpty ? 'Colaborador Operativo' : v;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;
    final isAdmin = ref.watch(localActorProvider).isAdmin;
    final avatarFile = EmployeeAvatarService.resolveFile(user?.fotoUrl);
    final initial = (user?.nombre ?? '').isEmpty ? '?' : user!.nombre[0].toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(color: context.cSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.cBorder, width: 0.5)),
          child: Column(children: [
            GestureDetector(
              onTap: () => EmployeeAvatarService.pickAndSavePhoto(context, ref, user),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                    backgroundImage: avatarFile != null ? FileImage(avatarFile) : null,
                    child: avatarFile == null ? Text(initial, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)) : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: context.cSurface, width: 2)),
                      child: const Icon(CupertinoIcons.camera_fill, size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(user?.fullName ?? 'Colaborador', style: TextStyle(fontFamily: AppTheme.editorialSerif, fontFamilyFallback: AppTheme.editorialFallbacks, fontSize: 18, fontWeight: FontWeight.w700, color: context.cTextPrimary, letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(_cleanCargo(user?.cargo), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => EmployeeAvatarService.pickAndSavePhoto(context, ref, user),
              child: const Text('Toca la foto para agregar o cambiar imagen real', style: TextStyle(fontSize: 11, color: AppColors.primary)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        IosFormGroup(
          header: 'INFORMACIÓN DE EXPEDIENTE',
          children: [
            _InfoRow(CupertinoIcons.person_crop_rectangle, 'Cédula', user?.cedula ?? '---'),
            _InfoRow(CupertinoIcons.briefcase, 'Cargo Oficial', _cleanCargo(user?.cargo)),
            _InfoRow(CupertinoIcons.mail, 'Correo', (user == null || user.correo.isEmpty) ? '---' : user.correo),
            _InfoRow(CupertinoIcons.phone, 'Teléfono', (user?.telefono?.isNotEmpty ?? false) ? user!.telefono! : 'Sin registrar'),
          ],
        ),
        const SizedBox(height: 16),
        IosFormGroup(
          header: 'AJUSTES Y CUENTA',
          children: [
            _ActionRow(icon: CupertinoIcons.camera, label: 'Agregar / Cambiar Foto Real del Empleado', onTap: () => EmployeeAvatarService.pickAndSavePhoto(context, ref, user)),
            _ActionRow(icon: CupertinoIcons.pencil, label: 'Editar Perfil', onTap: () => context.push(AppRoutes.profileEdit)),
            if (isAdmin) _ActionRow(icon: CupertinoIcons.person_badge_plus, label: 'Registrar nuevo usuario', onTap: () => context.push(AppRoutes.register)),
            _ActionRow(icon: CupertinoIcons.slider_horizontal_3, label: 'Configuración de Aplicación', onTap: () => context.push(AppRoutes.settings)),
            _ActionRow(icon: CupertinoIcons.square_arrow_right, label: 'Cerrar Sesión', destructive: true, onTap: () => confirmLogout(context, ref)),
          ],
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13.5, color: context.cTextSecondary)),
          const Spacer(),
          Flexible(child: Text(value, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.cTextPrimary))),
        ]),
      );
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const _ActionRow({required this.icon, required this.label, required this.onTap, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.systemRed : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: destructive ? AppColors.systemRed : context.cTextPrimary, fontWeight: FontWeight.w600, fontSize: 13.5))),
          Icon(CupertinoIcons.chevron_forward, color: context.cTextSecondary, size: 14),
        ]),
      ),
    );
  }
}
