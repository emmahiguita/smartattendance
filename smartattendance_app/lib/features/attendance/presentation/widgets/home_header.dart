// ============================================================================
// ARCHIVO: home_header.dart
// QUÉ HACE: Encabezado institucional con miniatura fotográfica real del
//           empleado (interactiva para agregar/cambiar foto desde Cámara o
//           Galería) e información textual organizada SIN CORTARSE:
//           1. Sello `SERVICIUDAD E.S.P.` arriba.
//           2. Saludo editorial (`¡Hola, Emmanuel!`).
//           3. Debajo, en su propia línea completa y con `softWrap: true`, el
//              cargo completo (`Encargado local / Administrador` o `Supervisor`)
//              para que jamás se corte con `...`.
//           4. Fecha oficial del día.
// CÓMO FUNCIONA: Resuelve la foto real mediante `EmployeeAvatarService` y
//                permite actualizarla tocando la miniatura.
// POR QUÉ: Garantiza que "/ Administrador" o "Supervisor" aparezca siempre
//          completo sin cortarse (< 175 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/employee_avatar_service.dart';
import '../../../auth/domain/entities/user_entity.dart';

class HomeHeader extends ConsumerWidget {
  final dynamic user;
  final VoidCallback? onOpenDirectory;

  const HomeHeader({
    super.key,
    required this.user,
    this.onOpenDirectory,
  });

  String _formatDate() {
    final now = DateTime.now();
    try {
      final df = DateFormat("EEEE, d 'de' MMMM", 'es_ES');
      final formatted = df.format(now);
      return formatted[0].toUpperCase() + formatted.substring(1);
    } catch (_) {
      return '${now.day}/${now.month}/${now.year}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final session = ref.watch(sessionControllerProvider);
    final authUser = session is SessionAuthenticated ? session.user : (user is UserEntity ? user as UserEntity : null);

    final fullName = authUser?.fullName ?? (user?.fullName as String? ?? 'Colaborador');
    final firstName = fullName.split(' ').first;
    final rawCargo = (authUser?.cargo ?? (user?.cargo as String? ?? 'Colaborador')).trim();
    final cargo = rawCargo.isEmpty ? 'Colaborador Operativo' : rawCargo;
    final dateStr = _formatDate();
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'C';
    final avatarFile = EmployeeAvatarService.resolveFile(authUser?.fotoUrl);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => EmployeeAvatarService.pickAndSavePhoto(context, ref, authUser),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.45), width: 1.6),
                  color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                  image: avatarFile != null
                      ? DecorationImage(image: FileImage(avatarFile), fit: BoxFit.cover)
                      : null,
                ),
                alignment: Alignment.center,
                child: avatarFile == null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          fontFamily: AppTheme.editorialSerif,
                          fontFamilyFallback: AppTheme.editorialFallbacks,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.cBackground, width: 1.8),
                  ),
                  child: const Icon(CupertinoIcons.camera_fill, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.09),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'SERVICIUDAD E.S.P.',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '¡Hola, $firstName!',
                style: TextStyle(
                  fontFamily: AppTheme.editorialSerif,
                  fontFamilyFallback: AppTheme.editorialFallbacks,
                  fontFeatures: AppTheme.editorialFeatures,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.35,
                  color: context.cTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cargo,
                softWrap: true,
                style: TextStyle(
                  fontFamily: AppTheme.editorialSerif,
                  fontFamilyFallback: AppTheme.editorialFallbacks,
                  fontStyle: FontStyle.italic,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w600,
                  color: context.cTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11.2,
                  color: context.cTextSecondary,
                  fontWeight: FontWeight.w500,
                  fontFeatures: AppTheme.editorialFeatures,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
