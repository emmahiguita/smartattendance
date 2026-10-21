// lib/features/history/presentation/widgets/ios_calendar_records_list.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../../../core/utils/time_format.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import 'history_detail_sheet.dart';

/// ============================================================================
/// COMPONENTE: IosCalendarRecordsList (Lista de Registros y Filtros de Asistencia)
/// ============================================================================
/// QUÉ HACE:
/// Provee dos modalidades de visualización tipo lista:
/// 1. `buildDayRecords`: Lista agrupada para el día seleccionado en la vista de Mes.
/// 2. `buildContinuousList`: Lista cronológica con chips de filtro por tipo de marcación.
///
/// CÓMO FUNCIONA:
/// Diseñado con estética iOS Inset Grouped: tarjetas redondeadas con bordes sutiles,
/// iconos circulares temáticos y chevrons de navegación hacia [HistoryDetailSheet].
///
/// POR QUÉ:
/// Principio de Responsabilidad Única (SRP):
/// Desacopla la lógica de listado y filtrado de la cuadrícula mensual y el timeline.
/// ============================================================================
class IosCalendarRecordsList extends StatelessWidget {
  final DateTime selectedDate;
  final List<AttendanceEntity> dayRecords;
  final List<AttendanceEntity> allRecords;
  final String? filterType;
  final ValueChanged<String?> onFilterChanged;
  final bool isDayOnly;

  const IosCalendarRecordsList({
    super.key,
    required this.selectedDate,
    required this.dayRecords,
    required this.allRecords,
    this.filterType,
    required this.onFilterChanged,
    this.isDayOnly = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isDayOnly) {
      return _buildDaySection(context);
    }
    return _buildContinuousSection(context);
  }

  Widget _buildDaySection(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'es').format(selectedDate);
    final capitalizedDate = dateStr[0].toUpperCase() + dateStr.substring(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  capitalizedDate,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.systemBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${dayRecords.length} ${dayRecords.length == 1 ? 'registro' : 'registros'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.systemBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (dayRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Sin marcaciones registradas para este día',
                  style: TextStyle(fontSize: 12.5, color: context.cTextSecondary),
                ),
              ),
            )
          else
            ...dayRecords.map((r) => _buildRecordTile(context, r)),
        ],
      ),
    );
  }

  Widget _buildContinuousSection(BuildContext context) {
    final filtered = filterType == null
        ? allRecords
        : allRecords.where((r) => r.tipo.toLowerCase().contains(filterType!.toLowerCase())).toList();

    return Column(
      children: [
        // Filtros horizontales
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildChip(null, 'Todas (${allRecords.length})'),
              _buildChip('entrada', 'Entradas'),
              _buildChip('almuerzo', 'Almuerzos'),
              _buildChip('salida', 'Salidas'),
            ],
          ),
        ),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text('No hay registros coincidentes', style: TextStyle(color: Colors.grey.shade600)),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.cSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.cBorder, width: 1.0),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: context.cBorder.withValues(alpha: 0.5)),
              itemBuilder: (context, idx) => _buildRecordTile(context, filtered[idx]),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(String? type, String label) {
    final isSelected = filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : null,
        ),
        selectedColor: AppColors.systemBlue,
        onSelected: (_) => onFilterChanged(type),
      ),
    );
  }

  Widget _buildRecordTile(BuildContext context, AttendanceEntity r) {
    final info = attendanceTypeInfo(r.tipo);
    final time = formatTimeOfDay(context, r.hora.toLocal());

    return ListTile(
      onTap: () => HistoryDetailSheet.show(context, r),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: info.color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_circle_rounded, color: info.color, size: 20),
      ),
      title: Text(info.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
      subtitle: Text(time, style: TextStyle(fontSize: 11.5, color: context.cTextSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
    );
  }
}
