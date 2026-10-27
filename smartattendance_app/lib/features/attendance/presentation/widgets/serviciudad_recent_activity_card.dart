// ============================================================================
// ARCHIVO: serviciudad_recent_activity_card.dart
// QUÉ HACE: Lista limpia y compacta de las marcaciones realizadas hoy.
// CÓMO FUNCIONA: Muestra las marcas del día real ordenadas cronológicamente,
//                con hora exacta y tipo oficial (Entrada, Almuerzo, Salida).
// POR QUÉ: Atiende la directiva: "eliminar componentes zombies que hacen lo mismo,
//          hacerlo limpio y con datos reales" (< 140 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/attendance_entity.dart';

class ServiciudadRecentActivityCard extends StatelessWidget {
  const ServiciudadRecentActivityCard({
    super.key,
    required this.records,
    this.zoneName,
    this.onViewAll,
  });

  final List<AttendanceEntity> records;
  final String? zoneName;
  final VoidCallback? onViewAll;

  static String _formatTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'entrada':
        return 'Entrada';
      case 'salida_almuerzo':
        return 'Salida a almuerzo';
      case 'regreso_almuerzo':
        return 'Regreso de almuerzo';
      case 'salida':
        return 'Salida de jornada';
      default:
        return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = records.where((r) {
      final l = r.fecha.toLocal();
      return l.year == now.year && l.month == now.month && l.day == now.day;
    }).toList();
    today.sort((a, b) => b.hora.compareTo(a.hora)); // más reciente primero

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Marcaciones de hoy',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.cTextPrimary,
              ),
            ),
            if (onViewAll != null)
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  'Historial',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.cSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.cBorder.withValues(alpha: 0.6),
              width: 0.8,
            ),
          ),
          child: today.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.info_circle, size: 14, color: context.cTextSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Sin marcaciones registradas hoy',
                        style: TextStyle(fontSize: 12, color: context.cTextSecondary),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: List.generate(today.length, (i) {
                    final r = today[i];
                    final horaStr = DateFormat('h:mm a').format(r.hora.toLocal());
                    final isLast = i == today.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _formatTipo(r.tipo),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: context.cTextPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                horaStr,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: context.cTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Container(
                            height: 0.5,
                            color: context.cBorder.withValues(alpha: 0.4),
                          ),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }
}
