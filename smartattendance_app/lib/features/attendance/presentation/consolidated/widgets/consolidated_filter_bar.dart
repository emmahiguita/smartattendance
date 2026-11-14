// ============================================================================
// ARCHIVO: consolidated_filter_bar.dart
// CAPA: Presentation / Consolidated / Widgets
// QUÉ HACE: Barra de búsqueda reactiva, selector de sede, fechas y estado
//           estilo Apple iOS sin desbordamientos.
// CÓMO FUNCIONA: Usa `CupertinoSearchTextField` y filtros horizontales compactos.
// POR QUÉ: Permite filtrar el consolidado en tiempo real (< 195 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../controllers/consolidated_attendance_controller.dart';
import '../controllers/consolidated_attendance_state.dart';
import 'consolidated_filter_widgets.dart';

class ConsolidatedFilterBar extends StatefulWidget {
  const ConsolidatedFilterBar({
    super.key,
    required this.state,
    required this.controller,
  });

  final ConsolidatedAttendanceState state;
  final ConsolidatedAttendanceController controller;

  @override
  State<ConsolidatedFilterBar> createState() => _ConsolidatedFilterBarState();
}

class _ConsolidatedFilterBarState extends State<ConsolidatedFilterBar> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.state.searchQuery);
  }

  @override
  void didUpdateWidget(covariant ConsolidatedFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.searchQuery != widget.state.searchQuery &&
        _searchCtrl.text != widget.state.searchQuery) {
      _searchCtrl.text = widget.state.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: widget.state.startDate ?? now.subtract(const Duration(days: 30)),
      end: widget.state.endDate ?? now,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: now.add(const Duration(days: 30)),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      widget.controller.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoSearchTextField(
                  controller: _searchCtrl,
                  placeholder: 'Buscar colaborador, cédula o sede...',
                  style: TextStyle(fontSize: 13, color: context.cTextPrimary),
                  placeholderStyle: TextStyle(
                    fontSize: 12.5,
                    color: context.cTextSecondary,
                  ),
                  onChanged: (val) => widget.controller.setSearch(val),
                  onSuffixTap: () {
                    _searchCtrl.clear();
                    widget.controller.setSearch('');
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilterChipButton(
                icon: CupertinoIcons.calendar_badge_plus,
                label: state.startDate != null ? 'Fechas' : 'Rango',
                isActive: state.startDate != null || state.endDate != null,
                onTap: () => _pickDateRange(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<String?>(
                  initialValue: state.selectedZone,
                  onSelected: (val) => widget.controller.setZone(val),
                  itemBuilder: (context) => [
                    const PopupMenuItem<String?>(
                      value: null,
                      child: Text('Todas las sedes',
                          style: TextStyle(fontSize: 12.5)),
                    ),
                    ...state.availableZones.map(
                      (z) => PopupMenuItem<String?>(
                        value: z,
                        child: Text(z, style: const TextStyle(fontSize: 12.5)),
                      ),
                    ),
                  ],
                  child: FilterCapsule(
                    label: state.selectedZone ?? 'Todas las sedes',
                    isActive: state.selectedZone != null,
                    icon: CupertinoIcons.building_2_fill,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  initialValue: state.selectedStatus,
                  onSelected: (val) => widget.controller.setStatus(val),
                  itemBuilder: (context) => const [
                    PopupMenuItem<String?>(
                      value: null,
                      child: Text('Todos los estados',
                          style: TextStyle(fontSize: 12.5)),
                    ),
                    PopupMenuItem<String?>(
                      value: 'Cerrada',
                      child: Text('Cerrada', style: TextStyle(fontSize: 12.5)),
                    ),
                    PopupMenuItem<String?>(
                      value: 'Abierta',
                      child: Text('Abierta', style: TextStyle(fontSize: 12.5)),
                    ),
                    PopupMenuItem<String?>(
                      value: 'Anulada',
                      child: Text('Anulada', style: TextStyle(fontSize: 12.5)),
                    ),
                  ],
                  child: FilterCapsule(
                    label: state.selectedStatus ?? 'Estado',
                    isActive: state.selectedStatus != null,
                    icon: CupertinoIcons.check_mark_circled_solid,
                  ),
                ),
                if (state.hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    minimumSize: const Size(24, 24),
                    onPressed: () {
                      _searchCtrl.clear();
                      widget.controller.clearFilters();
                    },
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.systemRed,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  '${state.totalJornadas} ${state.totalJornadas == 1 ? 'resultado' : 'resultados'}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: context.cTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
