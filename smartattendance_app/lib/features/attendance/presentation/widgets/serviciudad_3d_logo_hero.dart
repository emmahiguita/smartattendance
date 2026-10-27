// ============================================================================
// ARCHIVO: serviciudad_3d_logo_hero.dart
// QUÉ HACE: Logo 3D Oficial flotante interactivo (SIN CARD NI CONTENEDOR),
//           con rotación 360° (Yaw), perspectiva cónica, inercia cinética,
//           inclinación giroscópica (Pitch) y transición Hero/Flip 3D.
// CÓMO FUNCIONA: Flota libremente sobre el fondo de la pantalla usando Transform
//                con Matrix4 (setEntry 3,2) y Ticker con amortiguamiento inercial.
// POR QUÉ: Atiende la directiva: "NO DEBE IR EN UNA CARD EL LOGO, debe ser grande
//          en la parte superior con estilo 3D profesional y rotación Y-Axis".
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class Serviciudad3DLogoHero extends StatefulWidget {
  final double height;
  final VoidCallback? onTap;

  const Serviciudad3DLogoHero({super.key, this.height = 136.0, this.onTap});

  @override
  State<Serviciudad3DLogoHero> createState() => _Serviciudad3DLogoHeroState();
}

class _Serviciudad3DLogoHeroState extends State<Serviciudad3DLogoHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  double _yaw = 0.0;
  double _pitch = 0.0;
  double _velocity = 0.004;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController.unbounded(vsync: this)..addListener(_onTick);
    _ticker.repeat(min: 0, max: 1, period: const Duration(seconds: 1));
  }

  void _onTick() {
    if (!mounted) return;
    if (!_isDragging) {
      if (_velocity.abs() > 0.0001) {
        _yaw += _velocity;
        _velocity *= 0.95; // Amortiguamiento exponencial inercial
      } else {
        _yaw += 0.003; // Rotación idílica continua de exhibición 360°
      }
      _pitch += (0.0 - _pitch) * 0.08; // Retorno elástico de inclinación
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails _) {
    _isDragging = true;
    _velocity = 0.0;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _yaw += d.delta.dx * 0.014;
      _pitch = (_pitch - d.delta.dy * 0.008).clamp(-0.35, 0.35);
      _velocity = d.delta.dx * 0.012;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    _isDragging = false;
    final px = d.velocity.pixelsPerSecond.dx;
    if (px.abs() > 80) _velocity = (px / 1000.0) * 0.04;
  }

  void _onFlipTap() {
    setState(() => _velocity = (_velocity.abs() < 0.05) ? 0.16 : _velocity * 2.2);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isBack = math.cos(_yaw) < 0;

    return Semantics(
      label: 'Logo 3D Oficial Flotante de Serviciudad E.S.P.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTap: _onFlipTap,
        child: SizedBox(
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Sombra elíptica 3D flotante reactiva al giro (sin card)
              Positioned(
                bottom: 12,
                child: Container(
                  width: (120 * math.cos(_yaw).abs()).clamp(24.0, 120.0),
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.18),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Transformación 3D pura con perspectiva e inercia cinemática
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateX(_pitch)
                  ..rotateY(_yaw),
                child: Hero(
                  tag: 'serviciudad_3d_logo_hero',
                  child: isBack ? _buildBackSide(isDark) : _buildFrontSide(),
                ),
              ),
              // Micro-indicador flotante sutil de interactividad 360°
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.threed_rotation_rounded, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        '360° Interactivo',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontSide() => Image.asset(
        AppAssets.logoOficialReal,
        height: 108,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Image.asset(
          AppAssets.logoOficial,
          height: 108,
          fit: BoxFit.contain,
        ),
      );

  Widget _buildBackSide(bool isDark) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateY(math.pi),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded, size: 28, color: AppColors.primary),
            const SizedBox(height: 2),
            const Text(
              'SERVICIUDAD E.S.P.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Agua • Aseo • Alcantarillado',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Text(
              'Empresa de Todos • Dosquebradas',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      );
}
