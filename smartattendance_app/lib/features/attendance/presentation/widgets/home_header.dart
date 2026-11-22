// ============================================================================
// ARCHIVO: home_header.dart
// QUÉ HACE: Renderiza el bloque de saludo limpio y proporcionado sobre la ola
//           azul superior (icono de usuario translúcido sin bordes agresivos +
//           "Hola, <Nombre>" y "<Cargo> · <Fecha>" en blanco nítido).
// CÓMO FUNCIONA: Compacta alturas para dejar espacio equilibrado a las tarjetas
//                y al mapa miniatura en la misma pantalla.
// POR QUÉ: Tipografía limpia sin errores ni desorientación visual (< 105 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../photo_attendance/domain/work_schedule.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, required this.user, this.onOpenDirectory});
  final dynamic user;
  final VoidCallback? onOpenDirectory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final actual = session is SessionAuthenticated
        ? session.user
        : user is UserEntity
            ? user as UserEntity
            : null;
    final name = actual?.fullName ?? 'Colaborador';
    final now = ColombiaClock.wall(DateTime.now());
    String date;
    try {
      date = DateFormat("EEEE, d 'de' MMMM", 'es_CO').format(now);
    } catch (_) {
      date = '${now.day}/${now.month}/${now.year}';
    }
    final role = actual?.cargo ?? 'Colaborador';

    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, top: 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: onOpenDirectory,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                CupertinoIcons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hola, ${name.split(' ').first}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18.5,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$role · $date',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.0,
                    height: 1.12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
