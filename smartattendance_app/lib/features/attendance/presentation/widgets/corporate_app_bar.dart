// ============================================================================
// ARCHIVO: corporate_app_bar.dart
// QUÉ HACE: Barra superior institucional con tipografía Editorial Profesional,
//           campana de recordatorios reales y miniatura fotográfica real del
//           empleado autenticado.
// CÓMO FUNCIONA: Observa `sessionControllerProvider` y `localDayHistoryProvider`
//                para mostrar la foto real del empleado en el botón de perfil.
// POR QUÉ: Mantiene coherencia visual con la miniatura real del empleado (< 170 líneas).
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/notifications/journey_reminders.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/employee_avatar_service.dart';
import '../../../photo_attendance/presentation/local_day_history.dart';
import '../../domain/entities/attendance_entity.dart';
import 'notifications_sheet.dart';

class CorporateAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CorporateAppBar({
    super.key,
    required this.user,
    required this.currentNavIndex,
    required this.onProfileTap,
  });

  final dynamic user;
  final int currentNavIndex;
  final VoidCallback onProfileTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final authUser = session is SessionAuthenticated ? session.user : null;
    final records = ref.watch(localDayHistoryProvider).valueOrNull ?? const <AttendanceEntity>[];
    final hasPendingReminders = computeJourneyReminders(records).isNotEmpty;
    final avatarFile = EmployeeAvatarService.resolveFile(authUser?.fotoUrl);

    return AppBar(
      backgroundColor: context.cBackground.withValues(alpha: context.isDark ? 0.82 : 0.90),
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(color: Colors.transparent),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.8),
        child: Container(
          height: 0.8,
          color: context.cBorder.withValues(alpha: context.isDark ? 0.55 : 0.75),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5.5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: context.isDark ? 0.25 : 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.building_2_fill, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SERVICIUDAD E.S.P.',
                style: TextStyle(
                  fontFamily: AppTheme.editorialSerif,
                  fontFamilyFallback: AppTheme.editorialFallbacks,
                  fontFeatures: AppTheme.editorialFeatures,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: context.cTextPrimary,
                ),
              ),
              Text(
                'Dosquebradas · Risaralda',
                style: TextStyle(
                  fontFamily: AppTheme.editorialSerif,
                  fontFamilyFallback: AppTheme.editorialFallbacks,
                  fontStyle: FontStyle.italic,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.cTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => showJourneyNotificationsSheet(context, ref),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: context.cSurface.withValues(alpha: context.isDark ? 0.6 : 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: context.cBorder.withValues(alpha: 0.6), width: 0.8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_rounded, size: 18, color: context.cTextPrimary),
                if (hasPendingReminders)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.cTextSecondary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.45), width: 1.0),
              image: avatarFile != null ? DecorationImage(image: FileImage(avatarFile), fit: BoxFit.cover) : null,
            ),
            child: avatarFile == null
                ? Icon(CupertinoIcons.person_fill, size: 19, color: context.cTextSecondary)
                : null,
          ),
        ),
      ],
    );
  }
}
