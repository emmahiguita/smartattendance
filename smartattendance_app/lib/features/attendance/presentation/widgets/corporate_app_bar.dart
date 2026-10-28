// ============================================================================
// ARCHIVO: corporate_app_bar.dart
// QUÉ HACE: Barra superior institucional sobria con identidad tipográfica
//           monocromática, subtítulo contextual de sección, campana de
//           recordatorios reales de jornada y acceso al perfil.
// CÓMO FUNCIONA: Observa `localDayHistoryProvider` para mostrar un indicador
//                discreto si existen recordatorios pendientes y navega al
//                perfil al tocar el avatar de iniciales.
// POR QUÉ: Elimina colores "vibe coder" (texto bicolor cian/blanco e iconos
//          saturados) a favor de una cabecera ejecutiva limpia (< 160 líneas).
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/journey_reminders.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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
    final records = ref.watch(localDayHistoryProvider).valueOrNull ??
        const <AttendanceEntity>[];
    final hasPendingReminders = computeJourneyReminders(records).isNotEmpty;

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
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.cTextSecondary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: context.cBorder.withValues(alpha: 0.6), width: 0.8),
            ),
            child: Icon(
              CupertinoIcons.person_fill,
              size: 19,
              color: context.cTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
