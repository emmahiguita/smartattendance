// lib/features/attendance/presentation/widgets/corporate_app_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/journey_reminders.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/control_ai_logo.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../photo_attendance/presentation/local_day_history.dart';
import '../../domain/entities/attendance_entity.dart';
import 'notifications_sheet.dart';

/// ============================================================================
/// COMPONENTE: CorporateAppBar (Estilo Apple iOS Glass)
/// ============================================================================
/// QUÉ HACE:
/// Barra superior institucional con efecto Frosted Glass (cristal esmerilado):
/// logotipo oficial, subtítulo de sección, campana de notificaciones real y avatar.
///
/// CÓMO FUNCIONA:
/// Difumina el contenido con [ImageFilter.blur] en [flexibleSpace].
/// Conecta la campana de notificaciones al modal reactivo [showJourneyNotificationsSheet].
///
/// POR QUÉ:
/// Cumple con las directrices Apple HIG y el principio de Responsabilidad Única (SRP):
/// estética sobria, notificaciones reales y menos de 200 líneas de código.
/// ============================================================================
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
    String computeInitials() {
      if (user == null) return 'U';
      if (user is UserEntity) return (user as UserEntity).initials;
      try {
        final val = user.initials;
        if (val is String && val.isNotEmpty) return val;
      } catch (_) {}
      try {
        final n = (user.nombre as String? ?? '').trim();
        if (n.isNotEmpty) return n[0].toUpperCase();
      } catch (_) {}
      return 'U';
    }
    final initials = computeInitials();

    final sectionTitle = switch (currentNavIndex) {
      1 => 'Historial Operativo',
      2 => 'Gestión RRHH',
      3 => 'Perfil del Colaborador',
      _ => 'Panel de Asistencia',
    };

    final records = ref.watch(localDayHistoryProvider).valueOrNull ?? const <AttendanceEntity>[];
    final hasPendingReminders = computeJourneyReminders(records).isNotEmpty;

    return AppBar(
      backgroundColor: isDark ? const Color(0x99000000) : const Color(0xB3FFFFFF),
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Row(
        children: [
          const ControlAiLogo(size: 32, iconOnly: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SmartAttendance',
                  style: TextStyle(
                    color: context.cTextPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sectionTitle,
                  style: TextStyle(
                    color: context.cTextSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notificaciones de jornada',
          icon: Badge(
            isLabelVisible: hasPendingReminders,
            smallSize: 8,
            backgroundColor: AppColors.systemOrange,
            child: Icon(
              Icons.notifications_none_rounded,
              size: 22,
              color: context.cTextPrimary,
            ),
          ),
          onPressed: () => showJourneyNotificationsSheet(context, ref),
        ),
        const SizedBox(width: 2),
        GestureDetector(
          onTap: onProfileTap,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDesignTokens.mobileHorizontalPadding),
      ],
    );
  }
}
