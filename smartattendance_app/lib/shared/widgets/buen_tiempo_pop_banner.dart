// lib/shared/widgets/buen_tiempo_pop_banner.dart
import 'package:flutter/material.dart';
import '../../core/theme/buen_tiempo_colors.dart';
import 'buen_tiempo_logo.dart';

/// ============================================================================
/// COMPONENTE: BuenTiempoPopBanner (Material POP Publicitario e Institucional)
/// ============================================================================
/// QUÉ HACE:
/// Despliega el banner publicitario oficial de "BuenTiempo":
/// - Slogan: "Tu equipo, siempre a tiempo"
/// - Subtítulo: "Asistencia clara. Jornadas organizadas."
/// - Ícono de la app estilo iOS Squircle con el imagotipo oficial.
/// - 3 cápsulas con garantías reales del sistema (Biometría, Sin Lags, Offline).
///
/// CÓMO FUNCIONA:
/// Diseñado con maquetación elástica protegida contra desbordamientos (evita
/// las molestas franjas amarillas y negras de overflow en pantallas angostas).
///
/// POR QUÉ:
/// Provee material corporativo de alto impacto visual para la pantalla de inicio,
/// módulo de bienvenida y presentaciones a directivos o auditorías laborales.
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Presentación del mensaje corporativo y propuesta de valor.
/// ============================================================================
class BuenTiempoPopBanner extends StatelessWidget {
  final VoidCallback? onTapAction;

  const BuenTiempoPopBanner({super.key, this.onTapAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BuenTiempoColors.popCream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BuenTiempoColors.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: BuenTiempoColors.navyShadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Fila de Encabezado: Ícono iOS + Logotipo
          const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BuenTiempoLogo(
                size: 32,
                iconOnly: true,
                iosSquircle: true,
              ),
              SizedBox(width: 14),
              Expanded(
                child: BuenTiempoLogo(
                  size: 26,
                  isHorizontal: true,
                  showSubtitle: true,
                  subtitleText: 'TECNOLOGÍA DE PUNTUALIDAD LABORAL',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Slogan Principal (Tipografía editorial ejecutiva)
          const Text(
            'Tu equipo, siempre a tiempo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: BuenTiempoColors.navy,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),

          // 3. Subtítulo explicativo
          Text(
            'Asistencia clara. Jornadas organizadas.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: BuenTiempoColors.navy.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Cápsulas de valor (Sin simulaciones - capacidades reales del sistema)
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeatureBadge(
                icon: Icons.fingerprint_rounded,
                label: 'Biometría Facial Real',
                color: BuenTiempoColors.teal,
              ),
              _FeatureBadge(
                icon: Icons.wifi_off_rounded,
                label: '100% Offline SQLite',
                color: BuenTiempoColors.navy,
              ),
              _FeatureBadge(
                icon: Icons.speed_rounded,
                label: 'Cero Latencia / 120 FPS',
                color: BuenTiempoColors.sunAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cápsula compacta informativa para características del sistema
class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
