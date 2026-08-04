// lib/features/attendance/presentation/screens/employee_today_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../shared/widgets/app_appbar.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../../data/models/today_employee_status.dart';
import '../viewmodels/employee_today_viewmodel.dart';

class EmployeeTodayScreen extends ConsumerStatefulWidget {
  const EmployeeTodayScreen({super.key});
  @override
  ConsumerState<EmployeeTodayScreen> createState() =>
      _EmployeeTodayScreenState();
}

class _EmployeeTodayScreenState extends ConsumerState<EmployeeTodayScreen> {
  String? _areaFilter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(employeeTodayProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppAppBar(
        title: 'Asistencia de hoy',
        centerTitle: true,
        leadingWidget: AppButtons.iconStandard(
          icon: Icons.arrow_back_ios_new,
          color: AppColors.systemBlue,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _ErrorView(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(employeeTodayProvider.notifier).refresh())
              : _buildContent(state, now),
    );
  }

  Widget _buildContent(EmployeeTodayState state, DateTime now) {
    final areas = <String>{
      for (final e in state.employees) e.cargo ?? 'Sin área'
    }.toList()
      ..sort();
    final visible = _areaFilter == null
        ? state.employees
        : state.employees
            .where((e) => (e.cargo ?? 'Sin área') == _areaFilter)
            .toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(employeeTodayProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: context.cGray),
              const SizedBox(width: 8),
              Text(
                formatTimeOfDay(context, now),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.cTextPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  DateFormat('EEEE d \'de\' MMMM', 'es').format(now),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 13, color: context.cGray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _KpiCard(
                      label: 'Empleados',
                      value: state.total,
                      color: AppColors.primary,
                      icon: Icons.groups_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _KpiCard(
                      label: 'A tiempo',
                      value: state.aTiempo,
                      color: AppColors.systemGreen,
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _KpiCard(
                      label: 'Con retraso',
                      value: state.tarde,
                      color: const Color(0xFFF59E0B),
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _KpiCard(
                      label: 'Pendientes',
                      value: state.sinMarcar,
                      color: AppColors.systemGray,
                      icon: Icons.person_off_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _AreaChip(
                  label: 'Todas',
                  selected: _areaFilter == null,
                  onTap: () => setState(() => _areaFilter = null)),
              for (final a in areas)
                _AreaChip(
                    label: a,
                    selected: _areaFilter == a,
                    onTap: () => setState(() => _areaFilter = a)),
            ]),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                  child: Text('No hay empleados en esta área',
                      style: TextStyle(color: context.cTextSecondary))),
            )
          else
            ..._buildGroupList(visible),
        ],
      ),
    );
  }

  List<Widget> _buildGroupList(List<TodayEmployeeStatus> visible) {
    const groupOrder = ['tarde', 'sin_marcar', 'a_tiempo'];
    final widgets = <Widget>[];
    for (final g in groupOrder) {
      final group = visible.where((e) => e.estado == g).toList();
      if (group.isNotEmpty) {
        widgets.add(_SectionHeader(grupo: g));
        widgets.add(const SizedBox(height: 8));
        for (final e in group) {
          widgets.add(_EmployeeRow(employee: e));
        }
        widgets.add(const SizedBox(height: 16));
      }
    }
    return widgets;
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.cTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _AreaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AreaChip(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: selected ? AppColors.primary : context.cSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? AppColors.primary : context.cBorder)),
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : context.cTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String grupo;
  const _SectionHeader({required this.grupo});
  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (grupo) {
      'tarde' => (
          Icons.warning_amber,
          'Llegadas tarde',
          const Color(0xFFF59E0B)
        ),
      'sin_marcar' => (Icons.person_off, 'Pendientes', AppColors.systemGray),
      _ => (Icons.check_circle, 'A tiempo', AppColors.systemGreen),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.8)),
      ]),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  final TodayEmployeeStatus employee;
  const _EmployeeRow({required this.employee});
  @override
  Widget build(BuildContext context) {
    final fotoUrl = AppConfig.fullPhotoUrl(employee.fotoUrl);
    final estadoColor = switch (employee.estado) {
      'tarde' => const Color(0xFFF59E0B),
      'sin_marcar' => AppColors.systemGray,
      _ => AppColors.systemGreen,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cBorder)),
      child: Row(children: [
        CircleAvatar(
            radius: 22,
            backgroundColor: estadoColor.withValues(alpha: 0.15),
            backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
            child: fotoUrl.isEmpty
                ? Text(employee.initials.toUpperCase(),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: estadoColor))
                : null),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(employee.fullName,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.cTextPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(employee.cargo ?? 'Sin área',
              style: TextStyle(fontSize: 12, color: context.cTextSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (employee.horaEntrada != null) ...[
            Text(employee.horaEntrada!.substring(0, 5),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 2),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text(
                switch (employee.estado) {
                  'tarde' => '+${employee.minutosTarde} min',
                  'sin_marcar' => 'Pendiente',
                  _ => 'A tiempo'
                },
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: estadoColor)),
          ),
        ]),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.systemRed),
        const SizedBox(height: 12),
        Text(message, style: TextStyle(color: context.cTextSecondary)),
        const SizedBox(height: 16),
        TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar')),
      ]));
}
