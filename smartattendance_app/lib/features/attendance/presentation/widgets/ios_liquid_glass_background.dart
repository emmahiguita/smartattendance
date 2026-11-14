// ============================================================================
// ARCHIVO: ios_liquid_glass_background.dart
// QUÉ HACE: Fondo atmosférico con el fondo de pantalla oficial (cielo y nubes)
//           y orbes de luz viva en movimiento suave y continuo (iOS Liquid Glass).
// CÓMO FUNCIONA: Muestra `AppAssets.fondoPantalla` como base, con velo adaptativo
//                según tema y 3 esferas radiales de gradiente en órbita continua.
// POR QUÉ: Permite que las tarjetas translúcidas refracten la luz y las nubes del
//          fondo manteniendo legibilidad y fidelidad visual (< 150 líneas).
// ============================================================================

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_theme.dart';

class IosLiquidGlassBackground extends StatefulWidget {
  const IosLiquidGlassBackground({super.key});

  @override
  State<IosLiquidGlassBackground> createState() =>
      _IosLiquidGlassBackgroundState();
}

class _IosLiquidGlassBackgroundState extends State<IosLiquidGlassBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _driftController;

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _driftController,
          builder: (context, _) {
            final t = _driftController.value * 2 * math.pi;
            final dx1 = math.sin(t) * 35;
            final dy1 = math.cos(t) * 25;
            final dx2 = math.cos(t * 0.8) * 40;
            final dy2 = math.sin(t * 0.8) * 30;

            return Stack(
              fit: StackFit.expand,
              children: [
                // ── FONDO DE PANTALLA OFICIAL (Cielo y Nubes Opaco para Liquid Glass) ──
                Positioned.fill(
                  child: Image.asset(
                    AppAssets.fondoPantalla,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                // Velo tonal glaseado — CLARO: 0.35 para dejar pasar el wallpaper
                // OSCURO: 0.85 para profundidad navy. Si el velo es muy alto en claro,
                // las tarjetas se ven grises aunque tengan BackdropFilter propio.
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF060E1C).withValues(alpha: 0.85)
                              : const Color(0xFFE2E8F0).withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ),
                // Orbe 1: Azul Real Superior (ilumina cabecera)
                Positioned(
                  top: -40 + dy1,
                  right: -30 + dx1,
                  child: Container(
                    width: 290,
                    height: 290,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isDark
                                  ? const Color(0xFF007AFF)
                                  : const Color(0xFF38BDF8))
                              .withValues(alpha: isDark ? 0.28 : 0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Orbe 2: Cyan Oceánico Intermedio
                Positioned(
                  top: 240 + dy2,
                  left: -50 + dx2,
                  child: Container(
                    width: 310,
                    height: 310,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isDark
                                  ? const Color(0xFF0EA5E9)
                                  : const Color(0xFF0284C7))
                              .withValues(alpha: isDark ? 0.22 : 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Orbe 3: Zafiro Profundo / Barra de navegación
                Positioned(
                  bottom: 40 - dy1,
                  right: -40 - dx2,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isDark
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF60A5FA))
                              .withValues(alpha: isDark ? 0.20 : 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
