import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/premium_animations.dart';

class EnterpriseKpiCard extends StatelessWidget {
  final String title;
  final int value;
  final String? trend;
  final String? variation;
  final IconData icon;
  final Color? trendColor;

  const EnterpriseKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.trend,
    this.variation,
    required this.icon,
    this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = trendColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conteo animado real (0 → valor final) con estilo consistente.
          CountAnimation(
            target: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
