// ============================================================================
// ARCHIVO: admin_dashboard_sidebar.dart
// QUÉ HACE: Construye el sidebar de navegación lateral del panel administrativo,
//           con ítems animados (Dashboard, Asistencias, Mensajería, Cerrar Sesión).
// CÓMO FUNCIONA: Usa flutter_animate para entrada con fadeIn + slideX. Al tocar
//                un ítem, notifica al padre vía callback para cambiar de vista.
// POR QUÉ: Extraído de admin_dashboard_screen.dart para cumplir SRP (< 200 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/control_ai_logo.dart';

// QUÉ HACE: Widget del sidebar para navegación lateral en modo escritorio.
// CÓMO: Recibe el ítem seleccionado y callbacks para navegar o cerrar sesión.
// POR QUÉ: Separado del screen principal para mantener SRP y < 200 líneas.
class AdminDashboardSidebar extends StatelessWidget {
  const AdminDashboardSidebar({
    super.key,
    required this.selectedNavItem,
    required this.onNavItemSelected,
    required this.onLogout,
  });

  /// Nombre del ítem activo ('Dashboard', 'Asistencias', etc.)
  final String selectedNavItem;

  /// Callback cuando el usuario toca un ítem de navegación.
  final ValueChanged<String> onNavItemSelected;

  /// Callback para cerrar sesión.
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      // QUÉ HACE: Fondo oscuro sólido para contraste con el contenido principal.
      decoration: const BoxDecoration(color: Color(0xFF1E293B)),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Logo corporativo CONTROL AI animado al entrar.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: ControlAiLogo(
              size: 32,
              textColor: Colors.white,
              showSubtitle: true,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),

          const SizedBox(height: 40),

          // Ítems de navegación principales.
          Expanded(
            child: Column(
              children: [
                _NavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: selectedNavItem == 'Dashboard',
                  delay: 100,
                  onTap: () => onNavItemSelected('Dashboard'),
                ),
                _NavItem(
                  icon: Icons.fingerprint,
                  label: 'Asistencias',
                  isSelected: selectedNavItem == 'Asistencias',
                  delay: 150,
                  onTap: () => onNavItemSelected('Asistencias'),
                ),
                _NavItem(
                  icon: Icons.forum_rounded,
                  label: 'Mensajería',
                  isSelected: selectedNavItem == 'Mensajería',
                  delay: 200,
                  onTap: () => context.push(AppRoutes.messages),
                ),
                const Spacer(),
              ],
            ),
          ),

          // Botón destructivo de cierre de sesión.
          Padding(
            padding: const EdgeInsets.all(24),
            child: _NavItem(
              icon: Icons.logout,
              label: 'Cerrar Sesión',
              isDestructive: true,
              delay: 300,
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

// QUÉ HACE: Ítem individual del sidebar con animación de entrada y hover.
// CÓMO: AnimatedContainer con color que cambia según selección. Se anima con
//       fadeIn + slideX escalonado (delay) para efecto cascada visual.
// POR QUÉ: Encapsula la lógica visual de cada botón de navegación (SRP).
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.isDestructive = false,
    this.delay = 0,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDestructive;
  final int delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // QUÉ HACE: Determina el color del texto/ícono según estado.
    final color = isDestructive
        ? AppColors.systemRed
        : (isSelected ? Colors.white : Colors.white70);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // QUÉ HACE: Resalta con azul primario si está seleccionado.
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
        .slideX(begin: -0.1, end: 0);
  }
}
