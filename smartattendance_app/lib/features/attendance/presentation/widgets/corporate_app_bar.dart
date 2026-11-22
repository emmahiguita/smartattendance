// ============================================================================
// ARCHIVO: corporate_app_bar.dart
// QUÉ HACE: Barra superior flotante multiplataforma (iOS y Android) sobre la
//           onda azul real 3D:
//           1. Píldora blanca 3D con emblema y texto "BuenTiempo" legible.
//           2. Círculo blanco 3D (34x34) con reloj café y manecilla verde.
//           3. Círculo blanco 3D (34x34) con campana amarilla y punto rojo.
//           4. Foto miniatura circular 3D (34x34) con anillo blanco.
// CÓMO FUNCIONA: Usa `toolbarHeight: 48`, sombras 3D multicapa y `SystemUiOverlayStyle.light`
//                compatible con `UIViewControllerBasedStatusBarAppearance` en iOS.
// POR QUÉ: Acabado profesional 3D 100% idéntico en iOS y Android (< 190 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/notifications/journey_reminders.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/employee_avatar_service.dart';
import '../../../../shared/widgets/buen_tiempo_emblem_painter.dart';
import '../../../photo_attendance/presentation/local_day_history.dart';
import '../../../photo_attendance/presentation/photo_history_screen.dart';
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
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHome = currentNavIndex == 0;
    final isDark = context.isDark;
    final session = ref.watch(sessionControllerProvider);
    final authUser = session is SessionAuthenticated ? session.user : null;
    final records = ref.watch(localDayHistoryProvider).valueOrNull ??
        const <AttendanceEntity>[];
    final hasPending = computeJourneyReminders(records).isNotEmpty;
    final avatarFile = EmployeeAvatarService.resolveFile(
      authUser?.fotoUrl,
      authUser?.cedula,
    );
    final initial = (authUser?.nombre ?? '').trim().isNotEmpty
        ? authUser!.nombre.trim()[0].toUpperCase()
        : 'E';
    final screenW = MediaQuery.sizeOf(context).width;
    final sidePad = screenW >= 820
        ? ((screenW - 1060) / 2).clamp(24.0, 320.0)
        : 14.0;

    return AppBar(
      toolbarHeight: 48,
      centerTitle: false,
      titleSpacing: sidePad,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: isHome
          ? Colors.transparent
          : (isDark ? const Color(0xFF041E42) : const Color(0xFF003882)),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF001233).withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 3.5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomPaint(
              size: Size(22, 22),
              painter: BuenTiempoEmblemPainter(
                clockColor: Color(0xFF0F172A),
                checkColor: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 6),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                  height: 1.05,
                ),
                children: [
                  TextSpan(text: 'Buen', style: TextStyle(color: Color(0xFF0F172A))),
                  TextSpan(text: 'Tiempo', style: TextStyle(color: Color(0xFF16A34A))),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        _WhiteCircleButton(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(context,
                MaterialPageRoute<void>(builder: (_) => const PhotoHistoryScreen()));
          },
          child: const CustomPaint(
            size: Size(17.5, 17.5),
            painter: _BrownGreenClockPainter(
              clockColor: Color(0xFF4E342E),
              handColor: Color(0xFF16A34A),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _WhiteCircleButton(
              onTap: () {
                HapticFeedback.selectionClick();
                showJourneyNotificationsSheet(context, ref);
              },
              child: const Icon(CupertinoIcons.bell_fill,
                  size: 17.5, color: Color(0xFFF59E0B)),
            ),
            Positioned(
              top: -0.5,
              right: -0.5,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: hasPending ? const Color(0xFFDC2626) : const Color(0xFFE11D48),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Padding(
          padding: EdgeInsets.only(right: sidePad),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              if (currentNavIndex == 0 || currentNavIndex == 3) {
                EmployeeAvatarService.pickAndSavePhoto(context, ref, authUser);
              } else {
                onProfileTap();
              }
            },
            onLongPress: () =>
                EmployeeAvatarService.pickAndSavePhoto(context, ref, authUser),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.7),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF001233).withValues(alpha: 0.30),
                    blurRadius: 9,
                    offset: const Offset(0, 3.5),
                  ),
                ],
              ),
              child: ClipOval(
                child: avatarFile != null
                    ? Image.file(avatarFile, width: 31, height: 31, fit: BoxFit.cover)
                    : Text(initial,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WhiteCircleButton extends StatelessWidget {
  const _WhiteCircleButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF001233).withValues(alpha: 0.28),
                blurRadius: 9,
                offset: const Offset(0, 3.5),
              ),
            ],
          ),
          child: child,
        ),
      );
}

class _BrownGreenClockPainter extends CustomPainter {
  const _BrownGreenClockPainter({required this.clockColor, required this.handColor});
  final Color clockColor, handColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.44;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = clockColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.85
        ..isAntiAlias = true,
    );
    final hp = Paint()
      ..color = handColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.85
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawLine(c, Offset(c.dx, c.dy - r * 0.56), hp);
    canvas.drawLine(c, Offset(c.dx + r * 0.44, c.dy + r * 0.22), hp);
  }

  @override
  bool shouldRepaint(covariant _BrownGreenClockPainter oldDelegate) => false;
}
