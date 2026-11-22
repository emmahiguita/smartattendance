// ============================================================================
// ARCHIVO: map_geofence_widgets.dart
// QUÉ HACE: Subcomponentes atómicos de alto contraste para `MapGeofenceCard`:
//           píldoras de acción (`Sedes`, `Editar`) e indicadores de tráfico.
// CÓMO FUNCIONA: Aplica contraste WCAG AA en modo claro y oscuro + háptica iOS.
// POR QUÉ: Mantiene `MapGeofenceCard` bajo 200 líneas cumpliendo SRP (< 95 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// QUÉ HACE: Píldora compacta interactiva de metadatos (Sedes / Editar).
// CÓMO: Detecta toque con `HapticFeedback.selectionClick` y colores adaptativos.
// POR QUÉ: Evita botones sobrecargados en el HUD flotante del mapa.
class MapMetaPill extends StatelessWidget {
  const MapMetaPill({
    super.key,
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : const Color(0xFF0A2540);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11.5, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// QUÉ HACE: Indicador puntual de leyenda de tráfico vehicular (Fluido/Lento/Trancón).
// CÓMO: Combina punto de color vivo con texto de contraste WCAG AA verificado.
// POR QUÉ: Garantiza lectura clara en fondos claros sin amarillo lavado.
class MapTrafficDot extends StatelessWidget {
  const MapTrafficDot({
    super.key,
    required this.dotColor,
    required this.textColor,
    required this.text,
  });

  final Color dotColor;
  final Color textColor;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      );
}
