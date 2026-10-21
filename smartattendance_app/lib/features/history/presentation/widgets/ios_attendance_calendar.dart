// lib/features/history/presentation/widgets/ios_attendance_calendar.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../attendance/presentation/widgets/day_summary_card.dart';
import 'history_view_mode.dart';
import 'ios_calendar_month_grid.dart';
import 'ios_calendar_records_list.dart';
import 'ios_calendar_timeline_view.dart';

/// ============================================================================
/// COMPONENTE: IosAttendanceCalendar (Orquestador Principal de Historial y Agenda)
/// ============================================================================
/// QUÉ HACE:
/// Controla la navegación del historial laboral a través de un selector segmentado iOS:
/// 1. Vista Mes: Calendario interactivo con marcadores y resumen diario.
/// 2. Vista Agenda Meet: Línea de tiempo diaria estilo Google Calendar con Google Meet.
/// 3. Vista Lista: Listado continuo cronológico con filtros.
///
/// CÓMO FUNCIONA:
/// Mantiene el estado activo ([_focusedMonth], [_selectedDate], [_viewMode])
/// y delega la renderización a subcomponentes modulares de menos de 190 líneas.
///
/// POR QUÉ:
/// Principio de Responsabilidad Única (SRP - SOLID):
/// El orquestador no dibuja píxeles ni calcula geometría de matrices;
/// solo administra el estado de interacción, logrando 0 lag y código limpio.
/// ============================================================================
class IosAttendanceCalendar extends StatefulWidget {
  final List<AttendanceEntity> records;
  final VoidCallback onExport;
  final Future<void> Function() onRefresh;

  const IosAttendanceCalendar({
    super.key,
    required this.records,
    required this.onExport,
    required this.onRefresh,
  });

  @override
  State<IosAttendanceCalendar> createState() => _IosAttendanceCalendarState();
}

class _IosAttendanceCalendarState extends State<IosAttendanceCalendar> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  HistoryViewMode _viewMode = HistoryViewMode.calendar;
  String? _listFilterType;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _goToPreviousMonth() {
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1));
  }

  void _goToNextMonth() {
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1));
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    });
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayRecords = widget.records.where((r) => _isSameDay(r.fecha, _selectedDate)).toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 1. Selector Segmentado iOS Style
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<HistoryViewMode>(
                  groupValue: _viewMode,
                  thumbColor: Colors.white,
                  backgroundColor: AppColors.systemGray6,
                  children: const {
                    HistoryViewMode.calendar: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text('📅 Mes', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                    HistoryViewMode.timeline: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text('📹 Agenda Meet', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                    HistoryViewMode.list: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text('☰ Lista', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  },
                  onValueChanged: (mode) {
                    if (mode != null) setState(() => _viewMode = mode);
                  },
                ),
              ),
            ),

            // 2. Vista Activa
            if (_viewMode == HistoryViewMode.calendar) ...[
              IosCalendarMonthGrid(
                focusedMonth: _focusedMonth,
                selectedDate: _selectedDate,
                records: widget.records,
                onSelectDate: (date) => setState(() => _selectedDate = date),
                onPreviousMonth: _goToPreviousMonth,
                onNextMonth: _goToNextMonth,
                onToday: _goToToday,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DaySummaryCard(records: dayRecords),
              ),
              IosCalendarRecordsList(
                selectedDate: _selectedDate,
                dayRecords: dayRecords,
                allRecords: widget.records,
                onFilterChanged: (_) {},
                isDayOnly: true,
              ),
            ] else if (_viewMode == HistoryViewMode.timeline) ...[
              IosCalendarTimelineView(
                selectedDate: _selectedDate,
                dayRecords: dayRecords,
                onPreviousDay: _goToPreviousDay,
                onNextDay: _goToNextDay,
              ),
            ] else ...[
              IosCalendarRecordsList(
                selectedDate: _selectedDate,
                dayRecords: dayRecords,
                allRecords: widget.records,
                filterType: _listFilterType,
                onFilterChanged: (t) => setState(() => _listFilterType = t),
                isDayOnly: false,
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
