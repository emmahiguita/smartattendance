// lib/features/attendance/presentation/screens/admin_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/worker_dialog.dart';
import '../widgets/attendance_kpi_grid.dart';
import '../widgets/hr_overtime_tab.dart';
import '../widgets/hr_reports_tab.dart';
import '../widgets/hr_schedules_tab.dart';
import '../widgets/hr_staff_tab.dart';

/// ============================================================================
/// PANTALLA: AdminManagementScreen (Módulo Ejecutivo de Talento Humano)
/// ============================================================================
/// QUÉ HACE:
/// Centraliza y organiza las funciones reales de Talento Humano sin redundancias:
/// 1. Métricas operacionales en tiempo real (KPIs interactivos).
/// 2. Pestaña Personal: directorio unificado, buscador y ficha integral de empleado.
/// 3. Pestaña Jornadas & Turnos: plantillas reales, visualización y asignación en bloque.
/// 4. Pestaña Horas Extras: bandeja unificada de aprobación/rechazo auditado.
/// 5. Pestaña Reportes & Operación: exportación consolidada y geocercas/equipos.
///
/// PRINCIPIOS SOLID APLICADOS:
/// - Single Responsibility: Cada módulo reside en su propio subwidget especializado.
/// - Interface Segregation: Sin opciones repetidas ni acciones fantasma.
/// ============================================================================
class AdminManagementScreen extends ConsumerStatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  ConsumerState<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen> {
  int _selectedTab = 0; // 0: Personal, 1: Jornadas, 2: Horas Extras, 3: Reportes
  String? _staffFilter;

  void _showRegisterWorkerDialog() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const WorkerDialog(),
    ).then((created) {
      if (created == true && mounted) {
        ref.invalidate(localWorkersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colaborador registrado exitosamente.'),
            backgroundColor: AppColors.systemGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Widget _buildExecutiveHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        border: Border.all(color: context.cBorder, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Talento Humano',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Personal, turnos, horas extras y operaciones',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.cTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showRegisterWorkerDialog,
            icon: const Icon(Icons.person_add_rounded, size: 15),
            label: const Text('Nuevo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabBar(BuildContext context, int pendingOvertime) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cBorder, width: 0.8),
      ),
      child: Row(
        children: [
          _segmentItem(0, 'Personal', Icons.people_alt_rounded),
          _segmentItem(1, 'Jornadas', Icons.calendar_month_rounded),
          _segmentItem(2, 'Extras', Icons.more_time_rounded, badgeCount: pendingOvertime),
          _segmentItem(3, 'Reportes', Icons.assessment_rounded),
        ],
      ),
    );
  }

  Widget _segmentItem(int index, String label, IconData icon, {int badgeCount = 0}) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isSelected ? Colors.white : context.cTextSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : context.cTextSecondary,
                    ),
                  ),
                  if (badgeCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar jornadas con horas extras para badge en la pestaña
    final overtimeDays = ref.watch(allOvertimeDaysProvider).value ?? [];
    final pendingOvertimeCount = overtimeDays
        .where((d) => d.approvedSeconds == null && d.totals.additional != null)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDesignTokens.mobileHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExecutiveHeader(context),
          const SizedBox(height: 12),
          // KPIs en tiempo real (visibles y filtrables si estamos en Personal)
          AttendanceKpiGrid(
            selectedFilter: _selectedTab == 0 ? _staffFilter : null,
            onFilterTap: (f) {
              setState(() {
                _selectedTab = 0; // Cambiar a pestaña Personal al tocar un KPI
                _staffFilter = f;
              });
            },
          ),
          const SizedBox(height: 14),
          _buildSegmentedTabBar(context, pendingOvertimeCount),
          const SizedBox(height: 16),

          // Contenido de la pestaña activa
          IndexedStack(
            index: _selectedTab,
            children: [
              HrStaffTab(
                selectedFilter: _staffFilter,
                onFilterChanged: (f) => setState(() => _staffFilter = f),
              ),
              const HrSchedulesTab(),
              const HrOvertimeTab(),
              const HrReportsTab(),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
