// lib/features/history/presentation/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../shared/widgets/app_appbar.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../../../../shared/widgets/bouncing_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/fade_slide_transition.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../viewmodels/history_viewmodel.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';

// Enum de filtro: todos | los 4 tipos de marca de jornada
enum _HistoryFilter { all, entrada, salidaAlmuerzo, regresoAlmuerzo, salida }

/// Convierte el filtro al tipo de marca usado por el backend.
String _filterToTipo(_HistoryFilter f) => switch (f) {
      _HistoryFilter.entrada => 'entrada',
      _HistoryFilter.salidaAlmuerzo => 'salida_almuerzo',
      _HistoryFilter.regresoAlmuerzo => 'regreso_almuerzo',
      _HistoryFilter.salida => 'salida',
      _HistoryFilter.all => '',
    };

// Enum de rango temporal: hoy | semana | mes | todos
enum _HistoryRange { hoy, semana, mes, todos }

/// History screen — lista paginada de registros de asistencia con filtro.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;
  _HistoryRange _range = _HistoryRange.mes;

  /// Aplica filtro de tipo + rango temporal (client-side, datos reales).
  List<AttendanceEntity> _applyFilters(List<AttendanceEntity> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final DateTime? desde = switch (_range) {
      _HistoryRange.hoy => today,
      _HistoryRange.semana => today.subtract(const Duration(days: 7)),
      _HistoryRange.mes => DateTime(now.year, now.month, 1),
      _HistoryRange.todos => null,
    };

    final byType = _filter == _HistoryFilter.all
        ? records
        : records
            .where((r) => r.tipo.toLowerCase() == _filterToTipo(_filter))
            .toList();

    if (desde == null) return byType;
    return byType.where((r) {
      final d = DateTime(r.fecha.year, r.fecha.month, r.fecha.day);
      return !d.isBefore(desde);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyViewModelProvider);

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: _buildNavBar(context),
      body: SafeArea(
        child: Column(
          children: [
            // Chips de rango temporal (hoy / semana / mes / todos)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: _HistoryRange.values.map((r) {
                  final selected = _range == r;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _range = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.systemBlue
                              : context.cSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.systemBlue
                                : context.cGray4,
                          ),
                        ),
                        child: Text(
                          _rangeLabel(r),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : context.cGray,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: state.when(
                loading: () =>
                    const LoadingIndicator(message: 'Cargando historial...'),
                error: (error, stack) => EmptyStateWidget(
                  title: 'Error al cargar el historial',
                  message: error is AppException
                      ? error.message
                      : error.toString().replaceAll('Exception: ', ''),
                  icon: Icons.error,
                  actionLabel: 'Reintentar',
                  onActionPressed: () =>
                      ref.read(historyViewModelProvider.notifier).loadHistory(),
                ),
                data: (records) {
                  // Aplicar filtro de tipo + rango
                  final filtered = _applyFilters(records);

                  if (filtered.isEmpty) {
                    return EmptyStateWidget(
                      title: 'Sin registros',
                      message: _filter == _HistoryFilter.all
                          ? 'No hay registros de asistencia'
                          : 'No hay registros de tipo "${attendanceTypeInfo(_filterToTipo(_filter)).label}"',
                      icon: Icons.history,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(historyViewModelProvider.notifier)
                        .loadHistory(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => FadeSlideTransition(
                        delay:
                            Duration(milliseconds: 50 + (i * 50).clamp(0, 500)),
                        beginOffset: const Offset(0.0, 0.2),
                        child: _RecordTile(record: filtered[i]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildNavBar(BuildContext context) {
    return AppAppBar(
      title: 'Historial',
      centerTitle: true,
      leadingWidget: AppButtons.iconStandard(
        icon: Icons.arrow_back_ios_new,
        color: AppColors.systemBlue,
        onPressed: () => context.pop(),
      ),
      actions: [
        AppButtons.iconStandard(
          icon: Icons.filter_list,
          color: _filter != _HistoryFilter.all
              ? AppColors.systemBlue
              : AppColors.systemGray,
          onPressed: () => _showFilterSheet(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  String _rangeLabel(_HistoryRange r) => switch (r) {
        _HistoryRange.hoy => 'Hoy',
        _HistoryRange.semana => 'Semana',
        _HistoryRange.mes => 'Mes',
        _HistoryRange.todos => 'Todos',
      };

  void _showFilterSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Filtrar Historial'),
        message: const Text('Selecciona el tipo de registros a mostrar'),
        actions: [
          // Una opción por marca de jornada (4), con colores semánticos.
          for (final tipo in attendanceTypes)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                final filtro = _HistoryFilter.values.firstWhere(
                  (f) => _filterToTipo(f) == tipo,
                  orElse: () => _HistoryFilter.entrada,
                );
                setState(() => _filter = filtro);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle,
                      size: 10, color: attendanceTypeInfo(tipo).color),
                  const SizedBox(width: 8),
                  Text(attendanceTypeInfo(tipo).label),
                ],
              ),
            ),
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _filter = _HistoryFilter.all);
            },
            child: const Text('Todos'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }
} // fin _HistoryScreenState

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final AttendanceEntity record;

  @override
  Widget build(BuildContext context) {
    final info = attendanceTypeInfo(record.tipo);
    final color = info.color;
    final icon = info.icon;
    final bgColor = color.withValues(alpha: .1);

    return BouncingWidget(
      onTap: () => _showRecordDetails(context, record),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // Frase con género correcto por tipo de marca ("registrada"
                // para entrada/salida, "registrado" para almuerzo/regreso).
                switch (record.tipo) {
                  'entrada' => 'Entrada registrada',
                  'salida_almuerzo' => 'Inicio de almuerzo registrado',
                  'regreso_almuerzo' => 'Regreso de almuerzo registrado',
                  'salida' => 'Salida registrada',
                  _ => 'Marca registrada',
                },
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(record.fecha.toLocal())} · ${formatTimeOfDay(context, record.hora.toLocal())}',
                    style: TextStyle(fontSize: 13, color: context.cGray),
                  ),
                  if (record.direccion != null &&
                      record.direccion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: context.cGray),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            record.direccion!,
                            style:
                                TextStyle(fontSize: 12, color: context.cGray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(attendanceTypeShort(record.tipo).toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: .3)),
          ),
        ]),
      ),
    );
  }

  void _showRecordDetails(BuildContext context, AttendanceEntity record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalle de ${attendanceTypeInfo(record.tipo).label}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Fecha: ${DateFormat('dd/MM/yyyy').format(record.fecha.toLocal())}'),
            const SizedBox(height: 8),
            Text('Hora: ${formatTimeOfDay(context, record.hora.toLocal())}'),
            const SizedBox(height: 8),
            if (record.direccion != null) ...[
              const Text('Dirección:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(record.direccion!),
              const SizedBox(height: 8),
            ],
            Text('Latitud: ${record.latitud}'),
            Text('Longitud: ${record.longitud}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
