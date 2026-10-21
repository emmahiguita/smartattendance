import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Una sola acción principal, con el mismo fondo oscuro y acento azul aprobado.
/// El texto puede crecer: no se fuerza una altura ni se repite otro botón igual.
class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
      color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF315C81),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined,
                        color: Colors.white)),
                const SizedBox(width: 14),
                const Expanded(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Registrar asistencia',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.3,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Con foto · Sin conexión',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3)),
                    ])),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ]))));
}
