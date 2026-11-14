// ============================================================================
// ARCHIVO: corporate_app_bar.dart
// QUÉ HACE: Barra superior institucional con tipografía Editorial Profesional,
//           fondo negro puro OLED (#000000) en modo oscuro, campana de
//           recordatorios y miniatura fotográfica real sin bordes azules.
// CÓMO FUNCIONA: Observa `sessionControllerProvider` y `localDayHistoryProvider`
//                y aplica `BackdropFilter` gaussiano real de 24px con divisor 0.5px.
// POR QUÉ: Unifica el color de cabecera con el cuerpo negro absoluto iOS (< 175 líneas).
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
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final session = ref.watch(sessionControllerProvider);
    final authUser = session is SessionAuthenticated ? session.user : null;
    final records = ref.watch(localDayHistoryProvider).valueOrNull ??
        const <AttendanceEntity>[];
    final hasPendingReminders = computeJourneyReminders(records).isNotEmpty;
    final avatarFile = EmployeeAvatarService.resolveFile(authUser?.fotoUrl);

    return AppBar(
      toolbarHeight: 50,
      backgroundColor: isDark
          ? Colors.black.withValues(alpha: 0.90)
          : Colors.white.withValues(alpha: 0.92),
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(color: Colors.transparent),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          color: context.cBorder,
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFF0F172A).withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.cBorder,
                width: 0.5,
              ),
            ),
            child: Icon(
              CupertinoIcons.building_2_fill,
              size: 13.5,
              color: context.cTextPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SERVICIUDAD E.S.P.',
                style: TextStyle(
                  fontFamilyFallback: AppTheme.editorialFallbacks,
                  fontFeatures: AppTheme.editorialFeatures,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: context.cTextPrimary,
                ),
              ),
              Text(
                'Dosquebradas · Risaralda',
                style: TextStyle(
                  fontFamilyFallback: AppTheme.editorialFallbacks,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
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
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : context.cSurface,
              shape: BoxShape.circle,
              border: Border.all(color: context.cBorder, width: 0.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  CupertinoIcons.bell,
                  size: 17,
                  color: context.cTextPrimary,
                ),
                if (hasPendingReminders)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      width: 6.5,
                      height: 6.5,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : context.cSurface,
              shape: BoxShape.circle,
              border: Border.all(color: context.cBorder, width: 0.5),
              image: avatarFile != null
                  ? DecorationImage(
                      image: FileImage(avatarFile),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarFile == null
                ? Icon(
                    CupertinoIcons.person_fill,
                    size: 17,
                    color: context.cTextSecondary,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
