// ============================================================================
// ARCHIVO: home_navigation_bar.dart
// QUÉ HACE: Barra de navegación inferior Liquid Glass profesional con
//           BackdropFilter 20px, borde superior 0.6px y háptica iOS.
// CÓMO FUNCIONA: ClipRect + BackdropFilter envuelven la barra; divisor
//                superior semitransparente reemplaza la línea sólida.
//                AnimatedScale + AnimatedDefaultTextStyle suavizan la selección.
// POR QUÉ: Estética iOS Apple sin cambiar íconos, rutas ni lógica de negocio.
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

class HomeNavigationBar extends StatelessWidget {
  const HomeNavigationBar({
    super.key,
    required this.currentNav,
    required this.isAdmin,
    required this.onNavChanged,
  });

  final int currentNav;
  final bool isAdmin;
  final ValueChanged<int> onNavChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    // QUÉ HACE: Envuelve la barra con BackdropFilter para el efecto glass real.
    // CÓMO: ClipRect limita el blur al área de la barra; DecoratedBox aplica
    //       el tint translúcido y el borde superior ultra-fino 0.6px.
    // POR QUÉ: Sustituye el fondo sólido negro/blanco por vidrio iOS Liquid Glass.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF07101E).withValues(alpha: 0.78)
                : Colors.white.withValues(alpha: 0.82),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.60),
                width: 0.6,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                _item(context, 0, Icons.home_outlined, 'Inicio'),
                if (isAdmin)
                  _item(context, 1, Icons.people_outline, 'Equipos'),
                _item(context, 2, Icons.map_outlined, 'Mapa'),
                _item(context, 3, Icons.person_outline, 'Perfil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // QUÉ HACE: Ítem de navegación con animación de escala y texto estilo iOS.
  // CÓMO: HapticFeedback.selectionClick + AnimatedScale + AnimatedDefaultTextStyle.
  // POR QUÉ: Respuesta táctil nativa iOS sin alterar íconos ni etiquetas.
  Widget _item(BuildContext context, int index, IconData icon, String label) {
    final selected = currentNav == index;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () {
            if (!selected) HapticFeedback.selectionClick();
            onNavChanged(index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.04 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    icon,
                    size: 22,
                    color: selected
                        ? context.cTextPrimary
                        : context.cTextSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected
                        ? context.cTextPrimary
                        : context.cTextSecondary,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
