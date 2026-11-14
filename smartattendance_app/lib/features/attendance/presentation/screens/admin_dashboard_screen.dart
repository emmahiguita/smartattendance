// ============================================================================
// ARCHIVO: admin_dashboard_screen.dart
// QUÉ HACE: Pantalla principal del panel administrativo. Orquesta las vistas
//           de Dashboard, Asistencias y Exportación según la navegación.
// CÓMO FUNCIONA: Detecta el ancho de pantalla (desktop/tablet/mobile) y adapta
//                el layout: sidebar fijo en desktop, drawer en mobile. Delega
//                cada sección visual a widgets hijos especializados.
// POR QUÉ: Cumple SRP — solo coordina navegación y estado. Cada sección
//           (sidebar, header, export, vistas) vive en su propio archivo (< 200 lín).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/confirm_logout.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/premium_animations.dart';
import '../../../qr/presentation/widgets/generate_qr_dialog.dart';
import '../../../users/presentation/widgets/register_user_dialog.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';
import '../viewmodels/export_preview_viewmodel.dart';
import '../widgets/export_preview_sheet.dart';
import '../widgets/premium_area_sections.dart';
import '../widgets/premium_kpi_card.dart';
import '../widgets/premium_attendance_table.dart';
import '../widgets/enterprise_side_panel.dart';
import '../../data/models/attendance_model.dart';
import 'admin_dashboard_sidebar.dart';
import 'admin_dashboard_header.dart';
import 'admin_dashboard_export.dart';

// QUÉ HACE: Widget raíz del dashboard admin con estado de navegación y búsqueda.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  // QUÉ HACE: Controla qué vista se muestra (Dashboard o Asistencias).
  String _selectedNavItem = 'Dashboard';

  // QUÉ HACE: Rango de fechas para la exportación Excel.
  DateTime? _exportFrom;
  DateTime? _exportTo;

  // QUÉ HACE: Controlador del campo de búsqueda global.
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // QUÉ HACE: Área seleccionada para filtrar en la vista Asistencias.
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

  // QUÉ HACE: Filtra registros por nombre, cédula o tipo (entrada/salida).
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

  // QUÉ HACE: Abre el sheet de exportación con preview de datos y formato.
  Future<void> _exportExcel() async {
    final path = await showIosFloatingGlassSheet<String>(
      context: context,
      title: 'Exportar Asistencias',
      subtitle: 'Histórico consolidado de colaboradores',
      maxHeightFactor: 0.85,
      child: ExportPreviewSheet(
        fechaDesde: _exportFrom,
        fechaHasta: _exportTo,
      ),
    );
    if (path != null && mounted) {
      ref.read(exportPreviewViewModelProvider.notifier).reset();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Reporte exportado correctamente:\n$path'),
          backgroundColor: AppColors.systemGreen,
          duration: const Duration(seconds: 4),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardProvider);
    final session = ref.watch(sessionControllerProvider);

    // QUÉ HACE: Obtiene el nombre del admin autenticado para el header.
    String adminName = 'Admin';
    if (session is SessionAuthenticated) adminName = session.user.nombre;

    // QUÉ HACE: Detecta tipo de pantalla para layout responsivo.
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1000;
    final isTablet = screenWidth > 700 && screenWidth <= 1000;

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: isDesktop ? null : _buildAppBar(),
      drawer: isDesktop ? null : Drawer(
        backgroundColor: const Color(0xFF1E293B),
        child: SafeArea(
          child: AdminDashboardSidebar(
            selectedNavItem: _selectedNavItem,
            onNavItemSelected: (v) => setState(() => _selectedNavItem = v),
            onLogout: () => confirmLogout(context, ref),
          ),
        ),
      ),
      body: Row(
        children: [
          // QUÉ HACE: Sidebar fijo solo visible en pantallas anchas (desktop).
          if (isDesktop)
            AdminDashboardSidebar(
              selectedNavItem: _selectedNavItem,
              onNavItemSelected: (v) => setState(() => _selectedNavItem = v),
              onLogout: () => confirmLogout(context, ref),
            ),
          // QUÉ HACE: Contenido principal con header + vista activa.
          Expanded(
            child: Column(
              children: [
                if (isDesktop)
                  AdminDashboardHeader(
                    adminName: adminName,
                    state: state,
                    searchController: _searchController,
                    onSearchChanged: (v) => setState(() => _searchQuery = v),
                    onRefresh: () =>
                        ref.read(adminDashboardProvider.notifier).refresh(),
                  ),
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

  // QUÉ HACE: AppBar compacta para tablet/mobile con botón de refresh.
  AppBar _buildAppBar() => AppBar(
        title: Text(_selectedNavItem,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
      );

  // QUÉ HACE: Vista principal del Dashboard con KPIs, tabla y panel lateral.
  Widget _buildDashboard(
      AdminDashboardState state, bool isDesktop, bool isTablet) {
    // Estado de carga → skeletons animados.
    if (state.isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(children: [
          CardSkeleton(),
          SizedBox(height: 24),
          TableRowSkeleton(),
          TableRowSkeleton(),
          TableRowSkeleton(),
        ]),
      ).animate().fadeIn(duration: 300.ms);
    }

    // Estado de error → widget de reintento.
    if (state.error != null) {
      return EmptyStateWidget(
        title: 'Error al cargar datos',
        message: state.error!,
        icon: Icons.error,
        actionLabel: 'Reintentar',
        onActionPressed: () =>
            ref.read(adminDashboardProvider.notifier).refresh(),
      );
    }

    final records = _filtered(state.attendances);
    final kpis = _buildKpis(state);

    // QUÉ HACE: Layout de escritorio → 70/30 con panel lateral.
    if (isDesktop) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KpiRow(kpis: kpis, wide: true),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PremiumAttendanceTable(attendances: records),
                      const SizedBox(height: 24),
                      AdminExportSection(
                        exportFrom: _exportFrom,
                        exportTo: _exportTo,
                        onFromChanged: (d) => setState(() => _exportFrom = d),
                        onToChanged: (d) => setState(() => _exportTo = d),
                        onExportExcel: _exportExcel,
                        onRegisterUser: () =>
                            showRegisterUserDialog(context, ref),
                        onGenerateQr: () => showGenerateQrDialog(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: EnterpriseSidePanel(
                    weeklyData: state.weeklyAttendanceChart,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // QUÉ HACE: Layout tablet/mobile → columna vertical apilada.
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 20 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KpiRow(kpis: kpis, wide: isTablet),
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

  // QUÉ HACE: Vista de asistencias agrupadas por área con filtro.
  Widget _buildAsistenciasView(AdminDashboardState state) {
    if (state.isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(children: [
          TableRowSkeleton(),
          SizedBox(height: 12),
          TableRowSkeleton(),
        ]),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Registro de Asistencias',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.cTextPrimary)),
          const SizedBox(height: 4),
          Text('Organizado por áreas (cargo del empleado)',
              style: TextStyle(fontSize: 13, color: context.cTextSecondary)),
          const SizedBox(height: 20),
          AreaGroupedAttendanceList(
            attendances: _filtered(state.attendances),
            selectedArea: _selectedArea,
            onAreaSelected: (area) => setState(() => _selectedArea = area),
          ),
        ],
      ),
    );
  }

  // QUÉ HACE: Genera los 4 datos KPI del dashboard.
  List<KpiData> _buildKpis(AdminDashboardState s) => [
        KpiData('Empleados', s.totalEmpleados, Icons.group, AppColors.primary),
        KpiData('Entradas Hoy', s.totalEntradasHoy, Icons.how_to_reg,
            AppColors.systemGreen),
        KpiData('Salidas Hoy', s.totalSalidasHoy, Icons.logout,
            AppColors.systemRed),
        KpiData('Ausentes Hoy', s.totalAusentesHoy, Icons.person_remove,
            AppColors.systemOrange),
      ];
}

// QUÉ HACE: Fila de tarjetas KPI adaptativa (row en desktop, wrap en mobile).
class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.kpis, required this.wide});
  final List<KpiData> kpis;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Row(
        children: kpis
            .map((k) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: EnterpriseKpiCard(
                      title: k.title,
                      value: k.value,
                      icon: k.icon,
                      trendColor: k.color,
                    ),
                  ),
                ))
            .toList(),
      );
    }
    final cardW = ((MediaQuery.of(context).size.width - 48) / 2)
        .clamp(130.0, 400.0);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kpis
          .map((k) => SizedBox(
                width: cardW,
                child: EnterpriseKpiCard(
                  title: k.title,
                  value: k.value,
                  icon: k.icon,
                  trendColor: k.color,
                ),
              ))
          .toList(),
    );
  }
}
