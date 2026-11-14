// ============================================================================
// ARCHIVO: serviciudad_hero_card.dart
// QUÉ HACE: Presenta las cuatro acciones de asistencia en filas iOS compactas.
// CÓMO FUNCIONA: Permite registrar cualquier marca que no haya sido ya registrada
//                hoy, sin importar el orden. Las marcas ya registradas se muestran
//                con check y hora. Las pendientes se pueden tocar libremente.
// POR QUÉ: El administrador necesita poder registrar pruebas sin restricciones
//          de secuencia. La unicidad (no repetir la misma etapa) se sigue respetando.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      ('entrada', 'Inicio', Icons.login_outlined),
      ('salida_almuerzo', 'Salida a almuerzo', Icons.restaurant_outlined),
      (
        'regreso_almuerzo',
        'Regreso de almuerzo',
        Icons.free_breakfast_outlined
      ),
      ('salida', 'Salida', Icons.logout_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            'Registrar asistencia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: context.cTextPrimary,
            ),
          ),
        ),
        for (var i = 0; i < actions.length; i++) ...[
          _action(context, actions[i], today),
          if (i < actions.length - 1)
            Divider(
                height: 1, thickness: 0.5, indent: 34, color: context.cBorder),
        ],
      ],
    );
  }

  // QUÉ HACE: Renderiza cada fila de marcación con altura compacta y táctil.
  // CÓMO: Usa Padding vertical de 8px en lugar de ListTile inflado.
  // POR QUÉ: Mantiene los divisores juntos y elegantes al estilo iOS Ajustes.
  Widget _action(
    BuildContext context,
    (String, String, IconData) action,
    List<AttendanceEntity> marks,
  ) {
    final mark = marks.where((r) => r.tipo == action.$1).firstOrNull;
    // QUÉ HACE: Habilita la acción si la marca NO ha sido registrada aún hoy.
    // CÓMO: Verifica únicamente que `mark == null`, sin importar el orden de secuencia.
    // POR QUÉ: Permite registrar pruebas en cualquier orden sin restricciones de continuidad.
    final enabled = mark == null;
    final subtitle = mark != null
        ? '${ColombiaClock.hour(mark.hora)} · Registrado'
        : 'Toca para registrar';

    return InkWell(
      onTap: () {
        if (enabled) {
          onTap(action.$1);
          return;
        }
        final message = 'Esta marca ya está registrada hoy: ${ColombiaClock.hour(mark.hora)}';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              action.$3,
              size: 20,
              color: enabled ? context.cTextPrimary : context.cTextSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action.$2,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: enabled ? FontWeight.w600 : FontWeight.w500,
                      color: context.cTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.cTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              mark != null
                  ? CupertinoIcons.check_mark
                  : enabled
                      ? CupertinoIcons.chevron_forward
                      : CupertinoIcons.lock,
              size: 16,
              color: context.cTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
