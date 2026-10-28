// ============================================================================
// ARCHIVO: admin_management_screen.dart
// QUÉ HACE: Módulo ejecutivo de Gestión RRHH 100% estilo Apple iOS con selector
//           nativo `CupertinoSlidingSegmentedControl` para Reportes, Personal,
//           Horarios y Extras, protegido por control de acceso RBAC + PIN.
// CÓMO FUNCIONA: Verifica `localActorProvider.isAdmin`. Si el usuario es un
//                colaborador sin rol administrativo, bloquea el módulo y ofrece
//                `AdminUnlockButton` (PIN cifrado en `FlutterSecureStorage`).
// POR QUÉ: Impide que empleados modifiquen turnos, geocercas o aprueben extras (< 165 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
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

  Widget _segChild(int index, String label, {int badge = 0}) {
    final sel = _selectedTab == index;
    final fg = sel ? const Color(0xFFFFFFFF) : context.cTextPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
              color: fg,
            ),
          ),
          if (badge > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0x38FFFFFF)
                    : AppColors.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$badge',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: sel ? const Color(0xFFFFFFFF) : AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(localActorProvider);
    if (!actor.isAdmin) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: IosGlassCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.lock_shield_fill,
                  size: 44,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Módulo Exclusivo de Administración',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'La configuración de turnos, ventanas de marcación, geocercas GPS, aprobación de horas extras y reportes ejecutivos requiere permisos de Administrador o desbloqueo con PIN.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.cTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                const AdminUnlockButton(),
              ],
            ),
          ),
        ),
      );
    }

    final overtimeDays = ref.watch(allOvertimeDaysProvider).value ?? [];
    final pending = overtimeDays
        .where((d) =>
            d.approvedSeconds == null &&
            (d.totals.additional?.inSeconds ?? 0) > 0)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoSlidingSegmentedControl<int>(
            groupValue: _selectedTab,
            backgroundColor: context.cSurface,
            thumbColor: AppColors.primary,
            children: {
              0: _segChild(0, 'Reportes'),
              1: _segChild(1, 'Personal'),
              2: _segChild(2, 'Horarios'),
              3: _segChild(3, 'Extras', badge: pending),
            },
            onValueChanged: (v) {
              if (v != null) setState(() => _selectedTab = v);
            },
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: switch (_selectedTab) {
              0 => const HrReportsTab(key: ValueKey('reports')),
              1 => HrStaffTab(
                  key: const ValueKey('staff'),
                  selectedFilter: _staffFilter,
                  onFilterChanged: (f) => setState(() => _staffFilter = f),
                ),
              2 => const HrSchedulesTab(key: ValueKey('schedules')),
              _ => const HrOvertimeTab(key: ValueKey('overtime')),
            },
          ),
        ],
      ),
    );
  }
}
