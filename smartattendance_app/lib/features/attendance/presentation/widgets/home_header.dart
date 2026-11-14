// ============================================================================
// ARCHIVO: home_header.dart
// QUÉ HACE: Identifica al usuario/administrador autenticado con avatar, cargo y fecha.
// CÓMO FUNCIONA: Presenta una cabecera horizontal compacta estilo iOS sin tarjetas
//                ni contenedores decorativos para dar paso a las acciones principales.
// POR QUÉ: Aprovecha el espacio superior y mantiene legibilidad total (< 90 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/employee_avatar_service.dart';
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
    final file = EmployeeAvatarService.resolveFile(actual?.fotoUrl);
    final now = ColombiaClock.wall(DateTime.now());
    String date;
    try {
      date = DateFormat("EEEE, d 'de' MMMM", 'es_CO').format(now);
    } catch (_) {
      date = '${now.day}/${now.month}/${now.year}';
    }
    final role = actual?.cargo ?? 'Colaborador';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            button: true,
            label: 'Actualizar foto de perfil',
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () =>
                  EmployeeAvatarService.pickAndSavePhoto(context, ref, actual),
              child: CircleAvatar(
                radius: 21,
                backgroundColor: context.cSurface,
                foregroundColor: context.cTextPrimary,
                backgroundImage: file == null ? null : FileImage(file),
                child: file == null
                    ? Text(
                        name.isEmpty ? 'C' : name[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SERVICIUDAD E.S.P.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                    color: context.cTextSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Hola, ${name.split(' ').first}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: context.cTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$role · $date',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.cTextSecondary,
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
