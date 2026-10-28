// ============================================================================
// ARCHIVO: home_header.dart
// QUÉ HACE: Encabezado institucional con miniatura fotográfica real del
//           empleado e información textual organizada SIN CORTARSE:
//           1. Sello `SERVICIUDAD E.S.P.` con color adaptativo luminoso en oscuro.
//           2. Saludo editorial (`¡Hola, Emmanuel!`).
//           3. Debajo, en línea completa (`softWrap: true`), el cargo completo
//              (`Encargado local / Administrador` o `Supervisor`) sin cortarse.
//           4. Fecha oficial del día.
// CÓMO FUNCIONA: Resuelve la foto real mediante `EmployeeAvatarService` y usa
//                `context.cPrimary` para contraste perfecto en Modo Oscuro iOS.
// POR QUÉ: Garantiza legibilidad en Modo Oscuro y cero texto cortado (< 175 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/session_controller.dart';
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
    final primaryColor = context.cPrimary;
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
                  border: Border.all(color: primaryColor.withValues(alpha: 0.55), width: 1.6),
                  color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  image: avatarFile != null
                      ? DecorationImage(image: FileImage(avatarFile), fit: BoxFit.cover)
                      : null,
                ),
                alignment: Alignment.center,
                child: avatarFile == null
                    ? Text(
                        initial,
                        style: TextStyle(
                          fontFamily: AppTheme.editorialSerif,
                          fontFamilyFallback: AppTheme.editorialFallbacks,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
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
                    color: primaryColor,
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
                  color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.09),
                  borderRadius: BorderRadius.circular(5),
                  border: isDark ? Border.all(color: primaryColor.withValues(alpha: 0.35), width: 0.6) : null,
                ),
                child: Text(
                  'SERVICIUDAD E.S.P.',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: primaryColor,
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
