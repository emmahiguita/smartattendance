// ============================================================================
// ARCHIVO: corporate_app_bar.dart
// QUÉ HACE: Barra superior institucional con tipografía Editorial Profesional,
//           efecto 100% iOS Liquid Glass Transparente Profesional en Modo
//           Oscuro, campana de recordatorios y miniatura fotográfica real.
// CÓMO FUNCIONA: Observa `sessionControllerProvider` y `localDayHistoryProvider`
//                y aplica `BackdropFilter` gaussiano real de 24px.
// POR QUÉ: Cumple la directiva de modo oscuro 100% iOS transparente profesional
//          y miniatura real del empleado (< 165 líneas).
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
    final isDark = context.isDark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final session = ref.watch(sessionControllerProvider);
    final authUser = session is SessionAuthenticated ? session.user : null;
    final records = ref.watch(localDayHistoryProvider).valueOrNull ?? const <AttendanceEntity>[];
    final hasPendingReminders = computeJourneyReminders(records).isNotEmpty;
    final avatarFile = EmployeeAvatarService.resolveFile(authUser?.fotoUrl);

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF060E1C).withValues(alpha: 0.52) : context.cBackground.withValues(alpha: 0.90),
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(color: Colors.transparent),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.8),
        child: Container(
          height: 0.8,
          color: isDark ? Colors.white.withValues(alpha: 0.15) : context.cBorder.withValues(alpha: 0.75),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5.5),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
              shape: BoxShape.circle,
              border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.18), width: 0.7) : null,
            ),
            child: Icon(CupertinoIcons.building_2_fill, size: 14, color: primaryColor),
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
              color: isDark ? Colors.white.withValues(alpha: 0.08) : context.cSurface.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.20) : context.cBorder.withValues(alpha: 0.6), width: 0.8),
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
              color: isDark ? Colors.white.withValues(alpha: 0.10) : context.cTextSecondary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withValues(alpha: 0.55), width: 1.1),
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
