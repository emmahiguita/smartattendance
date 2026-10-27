// ============================================================================
// ARCHIVO: profile_screen.dart
// QUÉ HACE: Pantalla de Perfil Corporativo estilo Apple iOS Inset Grouped con
//           avatar circular limpio, información de expediente (Cédula, Correo,
//           Teléfono, Dirección) y acciones de cuenta.
// CÓMO FUNCIONA: Lee el usuario autenticado desde `sessionControllerProvider`
//                y presenta dos secciones agrupadas estilo Ajustes de iOS.
// POR QUÉ: Sustituye gradientes y sombras de neón por estilo iOS puro (< 170 líneas).
// ============================================================================

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/confirm_logout.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static ImageProvider? _resolveImageProvider(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('/') || raw.startsWith('file://')) {
      final file = File(raw.replaceFirst('file://', ''));
      return file.existsSync() ? FileImage(file) : null;
    }
    final fullUrl = AppConfig.fullPhotoUrl(raw);
    return fullUrl.isNotEmpty ? NetworkImage(fullUrl) : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;
    final img = _resolveImageProvider(user?.fotoUrl);
    final initial = (user?.nombre ?? '').isEmpty ? '?' : user!.nombre[0].toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(color: context.cSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.cBorder, width: 0.5)),
          child: Column(children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withValues(alpha: 0.14),
              backgroundImage: img,
              child: img == null ? Text(initial, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)) : null,
            ),
            const SizedBox(height: 10),
            Text(user?.fullName ?? 'Colaborador', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.cTextPrimary, letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(user?.cargo ?? 'Colaborador Operativo', style: TextStyle(fontSize: 12.5, color: context.cTextSecondary)),
          ]),
        ),
        const SizedBox(height: 16),
        IosFormGroup(
          header: 'INFORMACIÓN DE EXPEDIENTE',
          children: [
            _InfoRow(CupertinoIcons.person_crop_rectangle, 'Cédula', user?.cedula ?? '---'),
            _InfoRow(CupertinoIcons.mail, 'Correo', (user == null || user.correo.isEmpty) ? '---' : user.correo),
            _InfoRow(CupertinoIcons.phone, 'Teléfono', (user?.telefono?.isNotEmpty ?? false) ? user!.telefono! : 'Sin registrar'),
            _InfoRow(CupertinoIcons.location, 'Dirección', (user?.direccion?.isNotEmpty ?? false) ? user!.direccion! : 'Sin registrar'),
          ],
        ),
        const SizedBox(height: 16),
        IosFormGroup(
          header: 'AJUSTES Y CUENTA',
          children: [
            _ActionRow(icon: CupertinoIcons.pencil, label: 'Editar Perfil', onTap: () => context.push(AppRoutes.profileEdit)),
            _ActionRow(icon: CupertinoIcons.person_badge_plus, label: 'Registrar nuevo usuario', onTap: () => context.push(AppRoutes.register)),
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
          Flexible(
            child: Text(value, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.cTextPrimary)),
          ),
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
