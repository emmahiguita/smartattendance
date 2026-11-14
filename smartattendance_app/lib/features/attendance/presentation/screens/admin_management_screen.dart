// ============================================================================
// ARCHIVO: admin_management_screen.dart
// QUÉ HACE: Muestra las operaciones administrativas (Equipos, Personal,
//           Horarios, Extras) según permisos RBAC del actor autenticado.
// CÓMO FUNCIONA: Navega mediante `CupertinoSlidingSegmentedControl` con divisor
//                fino de 0.5px, respuesta háptica y transición fluida iOS.
// POR QUÉ: Aprovecha el ancho y alto del teléfono con estética iOS (< 155 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/presentation/admin_unlock_button.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../widgets/hr_overtime_tab.dart';
import '../widgets/hr_reports_tab.dart';
import '../widgets/hr_schedules_tab.dart';
import '../widgets/hr_staff_tab.dart';

class AdminManagementScreen extends ConsumerStatefulWidget {
  const AdminManagementScreen({super.key});
  @override
  ConsumerState<AdminManagementScreen> createState() =>
      _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen> {
  int _selectedTab = 0;
  String? _staffFilter;

  // QUÉ HACE: Renderiza la etiqueta de cada segmento con transición de peso tipográfico.
  // CÓMO: Usa AnimatedDefaultTextStyle con curva easeOutCubic.
  // POR QUÉ: Evita saltos bruscos al deslizar el selector segmentado iOS.
  Widget _tab(int index, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                _selectedTab == index ? FontWeight.w700 : FontWeight.w500,
            color: context.cTextPrimary,
          ),
          child: Text(label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(localActorProvider);
    final disableAnim = MediaQuery.disableAnimationsOf(context);
    if (!actor.isAdmin) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.lock_shield,
                size: 38,
                color: context.cTextSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Acceso de administración',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: context.cTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Necesitas permisos de gestión para configurar equipos, personal y horarios.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: context.cTextSecondary),
              ),
              const SizedBox(height: 14),
              const AdminUnlockButton(),
            ],
          ),
        ),
      );
    }

    return ColoredBox(
      color: context.isDark ? Colors.black : context.cBackground,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CupertinoSlidingSegmentedControl<int>(
              groupValue: _selectedTab,
              backgroundColor: context.isDark
                  ? const Color(0xFF121214)
                  : const Color(0xFFF2F2F7),
              thumbColor:
                  context.isDark ? const Color(0xFF2C2C2E) : Colors.white,
              children: {
                0: _tab(0, 'Equipos'),
                1: _tab(1, 'Personal'),
                2: _tab(2, 'Horarios'),
                3: _tab(3, 'Extras'),
              },
              onValueChanged: (value) {
                if (value != null && value != _selectedTab) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTab = value);
                }
              },
            ),
            const SizedBox(height: 10),
            Divider(height: 1, thickness: 0.5, color: context.cBorder),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: disableAnim
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.015, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: switch (_selectedTab) {
                0 => const HrReportsTab(key: ValueKey('reports')),
                1 => HrStaffTab(
                    key: const ValueKey('staff'),
                    selectedFilter: _staffFilter,
                    onFilterChanged: (filter) =>
                        setState(() => _staffFilter = filter),
                  ),
                2 => const HrSchedulesTab(key: ValueKey('schedules')),
                _ => const HrOvertimeTab(key: ValueKey('overtime')),
              },
            ),
          ],
        ),
      ),
    );
  }
}
