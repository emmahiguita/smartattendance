// ============================================================================
// ARCHIVO: login_role_toggle.dart
// QUÉ HACE: Selector segmentado Liquid Glass entre rol Administrador y Usuario.
// CÓMO FUNCIONA: Permite al usuario conmutar entre los perfiles de acceso
//                (Administrador Rango Superior / Desarrollador vs Colaborador).
// POR QUÉ: Cumple con la solicitud explícita de elegir visualmente el perfil de ingreso.
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum LoginRole { user, admin }

class LoginRoleToggle extends StatelessWidget {
  const LoginRoleToggle({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final LoginRole selectedRole;
  final ValueChanged<LoginRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryColor = context.cPrimary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFEAEFF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRoleButton(
              context: context,
              role: LoginRole.user,
              label: 'Usuario',
              subtitle: 'Colaborador',
              icon: Icons.person_rounded,
              isActive: selectedRole == LoginRole.user,
              primaryColor: primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildRoleButton(
              context: context,
              role: LoginRole.admin,
              label: 'Administrador',
              subtitle: 'Rango Superior',
              icon: Icons.shield_rounded,
              isActive: selectedRole == LoginRole.admin,
              primaryColor: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton({
    required BuildContext context,
    required LoginRole role,
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required Color primaryColor,
  }) {
    final isDark = context.isDark;

    return InkWell(
      onTap: () => onRoleChanged(role),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? primaryColor.withValues(alpha: 0.28) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(
                  color: primaryColor.withValues(alpha: isDark ? 0.6 : 0.4),
                  width: 1,
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: (isDark ? primaryColor : Colors.black).withValues(alpha: isDark ? 0.25 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? primaryColor : context.cTextSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? context.cTextPrimary : context.cTextSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: isActive ? primaryColor : context.cGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
