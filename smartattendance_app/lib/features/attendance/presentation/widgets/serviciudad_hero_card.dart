// ============================================================================
// ARCHIVO: serviciudad_hero_card.dart
// QUÉ HACE: Presenta las 4 tarjetas de asistencia ("Inicio", "Salida a almuerzo",
//           "Regreso de almuerzo", "Salida") organizadas en fila limpia, con
//           tamaños proporcionados, sombras suaves y sin bordes que desorienten.
// CÓMO FUNCIONA: Renderiza 4 tarjetas compactas (`height: 96`) con fondo suave
//                `#F2F4FA`, textos oscuros legibles (`#0F172A` / `#334155`) e
//                iconografía semántica limpia.
// POR QUÉ: Deja espacio para los separadores y el mapa miniatura (< 145 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../domain/entities/attendance_entity.dart';

class ServiciudadHeroCard extends StatelessWidget {
  const ServiciudadHeroCard({
    super.key,
    required this.records,
    required this.onTap,
    this.assignedOvertimeMinutes = 0,
  });

  final List<AttendanceEntity> records;
  final ValueChanged<String> onTap;
  final int assignedOvertimeMinutes;

  @override
  Widget build(BuildContext context) {
    final today = records
        .where((r) =>
            ColombiaClock.day(r.fecha) == ColombiaClock.day(DateTime.now()))
        .toList()
      ..sort((a, b) => a.hora.compareTo(b.hora));

    const actions = [
      ('entrada', 'Inicio', Icons.login_rounded),
      ('salida_almuerzo', 'Salida a\nalmuerzo', Icons.restaurant_rounded),
      ('regreso_almuerzo', 'Regreso de\nalmuerzo', Icons.free_breakfast_outlined),
      ('salida', 'Salida', Icons.logout_rounded),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(child: _buildCard(context, actions[i], today)),
          if (i < actions.length - 1) const SizedBox(width: 7),
        ],
      ],
    );
  }

  Color _actionIconColor(String tipo, bool enabled) {
    final base = switch (tipo) {
      'entrada' => const Color(0xFFF59E0B),
      'salida_almuerzo' => const Color(0xFF16A34A),
      'regreso_almuerzo' => const Color(0xFF1E40AF),
      'salida' => const Color(0xFFDC2626),
      _ => const Color(0xFF0F172A),
    };
    return enabled ? base : base.withValues(alpha: 0.45);
  }

  Widget _buildCard(
    BuildContext context,
    (String, String, IconData) action,
    List<AttendanceEntity> marks,
  ) {
    final isDark = context.isDark;
    final mark = marks.where((r) => r.tipo == action.$1).firstOrNull;
    final enabled = mark == null;
    final subtitle = mark != null
        ? 'Registrado\n${ColombiaClock.hour(mark.hora)}'
        : 'Toca para\nregistrar';
    final iconColor = _actionIconColor(action.$1, enabled);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        if (enabled) {
          onTap(action.$1);
          return;
        }
        final message =
            'Esta marca ya está registrada hoy: ${ColombiaClock.hour(mark.hora)}';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      },
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141E30) : const Color(0xFFF2F4FA),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(action.$3, size: 23, color: iconColor),
            Text(
              action.$2,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.8,
                height: 1.06,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.0,
                height: 1.06,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
