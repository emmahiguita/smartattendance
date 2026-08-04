// lib/features/profile/presentation/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/confirm_logout.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// Módulo Perfil — información real del empleado + acciones de cuenta.
/// Embebible como tab del home o como pantalla independiente.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Primera letra del nombre para el avatar. Seguro ante usuario null.
  static String _initial(String? nombre) {
    final n = nombre ?? '';
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  /// Avatar con foto real si existe, o inicial si no se ha subido foto.
  static Widget _buildAvatar(UserEntity? user) {
    final fotoUrl = AppConfig.fullPhotoUrl(user?.fotoUrl);
    final child = fotoUrl.isNotEmpty
        ? null
        : Text(user != null ? _initial(user.nombre) : '?',
            style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.white));

    return CircleAvatar(
      radius: 44,
      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
      backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
      child: child,
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    await confirmLogout(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Avatar con iniciales (foto de perfil: fase futura)
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.gradientAttendance,
              boxShadow: [
                BoxShadow(
                  color: AppColors.systemBlue.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: _buildAvatar(user),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Empleado',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            user?.cargo ?? 'Empleado',
            style: TextStyle(fontSize: 14, color: context.cGray),
          ),
          const SizedBox(height: 32),

          // Datos reales del usuario
          Container(
            decoration: BoxDecoration(
              color: context.cSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                _InfoRow(
                    icon: Icons.badge,
                    label: 'Cédula',
                    value: user?.cedula ?? '---'),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _InfoRow(
                  icon: Icons.alternate_email,
                  label: 'Correo',
                  value: (user == null || user.correo.isEmpty)
                      ? '---'
                      : user.correo,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _InfoRow(
                  icon: Icons.calendar_month,
                  label: 'Fecha de Nacimiento',
                  value: (user == null ||
                          user.fechaNacimiento == null ||
                          user.fechaNacimiento!.isEmpty)
                      ? 'Sin registrar'
                      : user.fechaNacimiento!,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _InfoRow(
                  icon: Icons.call,
                  label: 'Teléfono',
                  value: (user == null ||
                          user.telefono == null ||
                          user.telefono!.isEmpty)
                      ? 'Sin registrar'
                      : user.telefono!,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _InfoRow(
                  icon: Icons.location_on,
                  label: 'Dirección',
                  value: (user == null ||
                          user.direccion == null ||
                          user.direccion!.isEmpty)
                      ? 'Sin registrar'
                      : user.direccion!,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _InfoRow(
                    icon: Icons.label,
                    label: 'ID de empleado',
                    value: user?.id.toString() ?? '---'),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const _InfoRow(
                    icon: Icons.memory,
                    label: 'Plataforma',
                    value: 'CONTROL AI'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Acciones
          _ActionTile(
            icon: Icons.edit,
            label: 'Editar Perfil',
            onTap: () => context.push(AppRoutes.profileEdit),
          ),
          _ActionTile(
            icon: Icons.settings,
            label: 'Configuración',
            onTap: () => context.push(AppRoutes.settings),
          ),
          _ActionTile(
            icon: Icons.logout,
            label: 'Cerrar Sesión',
            destructive: true,
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.systemBlue),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 14, color: context.cGray)),
            const Spacer(),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.cTextPrimary)),
            ),
          ],
        ),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.systemRed : AppColors.systemBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label,
            style: TextStyle(
                color: destructive ? AppColors.systemRed : context.cTextPrimary,
                fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right, color: context.cGray, size: 20),
        onTap: onTap,
      ),
    );
  }
}
