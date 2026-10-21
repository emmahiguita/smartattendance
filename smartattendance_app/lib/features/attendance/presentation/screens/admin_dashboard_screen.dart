import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/confirm_logout.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/premium_animations.dart';
import '../../../qr/presentation/widgets/generate_qr_dialog.dart';
import '../../../users/presentation/widgets/register_user_dialog.dart';
import '../../../../shared/widgets/control_ai_logo.dart';
import '../widgets/premium_area_sections.dart';
import '../widgets/premium_kpi_card.dart';
import '../widgets/premium_attendance_table.dart';
import '../widgets/enterprise_side_panel.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';
import '../viewmodels/export_preview_viewmodel.dart';
import '../widgets/export_preview_sheet.dart';
import '../../data/models/attendance_model.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _selectedNavItem = 'Dashboard';
  DateTime? _exportFrom;
  DateTime? _exportTo;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Área seleccionada en la vista de Asistencias (null = todas).
  String? _selectedArea;

  @override
  void initState() {
    super.initState();
    _exportFrom = DateTime.now().subtract(const Duration(days: 30));
    _exportTo = DateTime.now();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filtro real por nombre, cédula o tipo (entrada/salida).
  List<AttendanceModel> _filtered(List<AttendanceModel> all) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((a) =>
            a.fullName.toLowerCase().contains(q) ||
            (a.cedulaEmpleado ?? '').toLowerCase().contains(q) ||
            a.tipo.toLowerCase().contains(q))
        .toList();
  }

  /// Dialog: lista de empleados â†’ seleccionar â†’ genera QR (POST /qr/generate).
  Future<void> _showGenerateQrDialog() => showGenerateQrDialog(context, ref);

  /// Dialog: formulario de registro de nuevos empleados (POST /users/).
  Future<void> _showRegisterUserDialog() =>
      showRegisterUserDialog(context, ref);

  Future<void> _confirmLogout() async {
    await confirmLogout(context, ref);
  }

  /// Abre el preview de exportación con resumen, selector de formato y tabla.
  Future<void> _exportExcel() async {
    final path = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportPreviewSheet(
        fechaDesde: _exportFrom,
        fechaHasta: _exportTo,
      ),
    );

    if (path != null && mounted) {
      ref.read(exportPreviewViewModelProvider.notifier).reset();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Reporte exportado correctamente:\n$path'),
            backgroundColor: AppColors.systemGreen,
            duration: const Duration(seconds: 4),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardProvider);
    final session = ref.watch(sessionControllerProvider);

    String adminName = 'Admin';
    if (session is SessionAuthenticated) {
      adminName = session.user.nombre;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1000;
    final isTablet = screenWidth > 700 && screenWidth <= 1000;

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(
                _selectedNavItem,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              backgroundColor: context.cBackgroundSecondary,
              foregroundColor: context.cTextPrimary,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () =>
                      ref.read(adminDashboardProvider.notifier).refresh(),
                ),
              ],
            ),
      drawer: isDesktop ? null : _buildDrawer(),
      body: Row(
        children: [
          // Sidebar (desktop only)
          if (isDesktop) _buildSidebar(),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header (desktop only)
                if (isDesktop) _buildHeader(adminName, state),

                // Dashboard Content
                Expanded(
                  child: _selectedNavItem == 'Dashboard'
                      ? _buildDashboard(state, isDesktop, isTablet)
                      : _buildAsistenciasView(state),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SIDEBAR
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo CONTROL AI
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: ControlAiLogo(
              size: 32,
              textColor: Colors.white,
              showSubtitle: true,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),

          const SizedBox(height: 40),

          // Nav items
          Expanded(
            child: Column(
              children: [
                _buildNavItem(Icons.dashboard, 'Dashboard', delay: 100),
                _buildNavItem(Icons.fingerprint, 'Asistencias', delay: 150),
                _buildNavItem(Icons.forum_rounded, 'Mensajería', delay: 200),
                const Spacer(),
              ],
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildNavItem(Icons.logout, 'Cerrar Sesión',
                isDestructive: true, delay: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label,
      {bool isDestructive = false, int delay = 0}) {
    final isSelected = _selectedNavItem == label;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (label == 'Cerrar Sesión') {
            _confirmLogout();
          } else if (label == 'Mensajería') {
            context.push(AppRoutes.messages);
          } else {
            setState(() => _selectedNavItem = label);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive
                    ? AppColors.systemRed
                    : (isSelected ? Colors.white : Colors.white70),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isDestructive
                      ? AppColors.systemRed
                      : (isSelected ? Colors.white : Colors.white70),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
        .slideX(begin: -0.1, end: 0);
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1E293B),
      child: SafeArea(child: _buildSidebar()),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // HEADER
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildHeader(String adminName, AdminDashboardState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: context.cBackgroundSecondary,
        border: Border(bottom: BorderSide(color: context.cBorder, width: 1)),
      ),
      child: Row(
        children: [
          // Search â€” filtra la tabla en tiempo real
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: context.cSurface,
                border: Border.all(color: context.cBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(color: context.cTextPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar empleados, reportes...',
                  hintStyle:
                      TextStyle(color: context.cTextSecondary, fontSize: 14),
                  prefixIcon: Icon(Icons.search,
                      color: context.cTextSecondary, size: 20),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),

          // System Status â€” pulsea cuando hay error (PulseAlert real).
          PulseAlert(
            isActive: state.error != null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: state.error == null
                    ? AppColors.systemGreen.withValues(alpha: 0.1)
                    : AppColors.systemRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: state.error == null
                      ? AppColors.systemGreen.withValues(alpha: 0.3)
                      : AppColors.systemRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: state.error == null
                          ? AppColors.systemGreen
                          : AppColors.systemRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.error == null ? 'Sistema Online' : 'Error',
                    style: TextStyle(
                      color: state.error == null
                          ? AppColors.systemGreen
                          : AppColors.systemRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Sync time
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, color: context.cTextSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Sync: ${state.lastSyncLabel}',
                style: TextStyle(
                    color: context.cTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(width: 24),

          // Refresh button
          IconButton(
            onPressed: () =>
                ref.read(adminDashboardProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Actualizar datos',
          ),
          const SizedBox(width: 16),

          // Profile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accentIndigo]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(adminName,
                        style: TextStyle(
                            color: context.cTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text('Administrador',
                        style: TextStyle(
                            color: context.cTextSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DASHBOARD VIEW
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildDashboard(
      AdminDashboardState state, bool isDesktop, bool isTablet) {
    if (state.isLoading) {
      // Skeletons reales (premium_animations) en vez de un spinner genérico.
      return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CardSkeleton(),
            SizedBox(height: 24),
            TableRowSkeleton(),
            TableRowSkeleton(),
            TableRowSkeleton(),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    if (state.error != null) {
      return EmptyStateWidget(
        title: 'Error al cargar datos',
        message: state.error!,
        icon: Icons.error,
        actionLabel: 'Reintentar',
        onActionPressed: () =>
            ref.read(adminDashboardProvider.notifier).refresh(),
      )
          .animate()
          .fadeIn(duration: 300.ms)
          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
    }

    if (isDesktop) {
      final records = _filtered(state.attendances);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKpiRow(state, true),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column (70%)
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PremiumAttendanceTable(attendances: records)
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.05, end: 0),
                      const SizedBox(height: 24),
                      _buildExportSection()
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 400.ms)
                          .slideY(begin: 0.05, end: 0),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column (30%)
                Expanded(
                  flex: 3,
                  child: EnterpriseSidePanel(
                    weeklyData: state.weeklyAttendanceChart,
                  )
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 400.ms)
                      .slideX(begin: 0.05, end: 0),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Tablet / Mobile
    final records = _filtered(state.attendances);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 20 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiRow(state, isTablet),
          const SizedBox(height: 16),
          PremiumAttendanceTable(attendances: records),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: EnterpriseSidePanel(
              weeklyData: state.weeklyAttendanceChart,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ KPI Row â”€â”€
  Widget _buildKpiRow(AdminDashboardState state, bool wide) {
    final kpis = [
      _KpiData(
          'Empleados', state.totalEmpleados, Icons.group, AppColors.primary),
      _KpiData('Entradas Hoy', state.totalEntradasHoy, Icons.how_to_reg,
          AppColors.systemGreen),
      _KpiData('Salidas Hoy', state.totalSalidasHoy, Icons.logout,
          AppColors.systemRed),
      _KpiData('Ausentes Hoy', state.totalAusentesHoy, Icons.person_remove,
          AppColors.systemOrange),
    ];

    if (wide) {
      return Row(
        children: kpis.asMap().entries.map((entry) {
          final i = entry.key;
          final k = entry.value;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: EnterpriseKpiCard(
                title: k.title,
                value: k.value,
                icon: k.icon,
                trendColor: k.color,
              ),
            ),
          )
              .animate()
              .fadeIn(
                  delay: Duration(milliseconds: 50 + i * 80), duration: 400.ms)
              .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
        }).toList(),
      );
    }

    // Narrow: 2x2 grid
    final screenW = MediaQuery.of(context).size.width;
    final cardW = ((screenW - 48) / 2).clamp(130.0, 400.0);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kpis.map((k) {
        return SizedBox(
          width: cardW,
          child: EnterpriseKpiCard(
            title: k.title,
            value: k.value,
            icon: k.icon,
            trendColor: k.color,
          ),
        );
      }).toList(),
    );
  }

  // â”€â”€ Asistencias View (when sidebar selects Asistencias) â”€â”€
  Widget _buildAsistenciasView(AdminDashboardState state) {
    if (state.isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(children: [
          TableRowSkeleton(),
          SizedBox(height: 12),
          TableRowSkeleton(),
          SizedBox(height: 12),
          TableRowSkeleton(),
        ]),
      );
    }
    final records = _filtered(state.attendances);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registro de Asistencias',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.cTextPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Organizado por áreas (cargo del empleado)',
            style: TextStyle(fontSize: 13, color: context.cTextSecondary),
          ),
          const SizedBox(height: 20),
          // Registros agrupados por área con filtro por área.
          AreaGroupedAttendanceList(
            attendances: records,
            selectedArea: _selectedArea,
            onAreaSelected: (area) => setState(() => _selectedArea = area),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Export Section â”€â”€
  Widget _buildExportSection() {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cSurface,
        border: Border.all(color: context.cBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exportar Reporte',
            style: TextStyle(
                color: context.cTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Desde',
                  style:
                      TextStyle(color: context.cTextSecondary, fontSize: 14)),
              _DatePickerChip(
                label: _exportFrom != null
                    ? dateFmt.format(_exportFrom!)
                    : 'Seleccionar',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _exportFrom ??
                        DateTime.now().subtract(const Duration(days: 30)),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _exportFrom = picked);
                },
              ),
              Text('Hasta',
                  style:
                      TextStyle(color: context.cTextSecondary, fontSize: 14)),
              _DatePickerChip(
                label: _exportTo != null
                    ? dateFmt.format(_exportTo!)
                    : 'Seleccionar',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _exportTo ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _exportTo = picked);
                },
              ),
              FilledButton.icon(
                onPressed: _exportExcel,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('EXPORTAR EXCEL',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              FilledButton.icon(
                onPressed: _showRegisterUserDialog,
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('REGISTRAR EMPLEADO',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              FilledButton.icon(
                onPressed: _showGenerateQrDialog,
                icon: const Icon(Icons.qr_code, size: 16),
                label: const Text('GENERAR QR',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.systemGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Helper Widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DatePickerChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _DatePickerChip({required this.label, required this.onTap});

  @override
  State<_DatePickerChip> createState() => _DatePickerChipState();
}

class _DatePickerChipState extends State<_DatePickerChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hover
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            border: Border.all(color: context.cBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Icon(Icons.calendar_today,
                  size: 16, color: context.cTextSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  const _KpiData(this.title, this.value, this.icon, this.color);
}
