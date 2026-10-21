// lib/features/history/presentation/widgets/ios_attendance_calendar.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../../../core/utils/time_format.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import 'history_detail_sheet.dart';

/// ============================================================================
/// COMPONENTE: IosAttendanceCalendar (Calendario Profesional Estilo Google / iOS)
/// ============================================================================
/// QUÉ HACE:
/// Calendario interactivo con 3 vistas fluidas:
/// 1. Vista Mes (Cuadrícula interactiva con puntos de estado).
/// 2. Vista Agenda Meet (Línea de tiempo estilo Google Calendar con franjas horarias,
///    bloques de turnos, marcas biométricas y llamadas Google Meet 100% gratis).
/// 3. Vista Lista (Listado completo con filtros de tipo y rango).
/// ============================================================================
enum HistoryViewMode { calendar, timeline, list }

class IosAttendanceCalendar extends StatefulWidget {
  const IosAttendanceCalendar({
    super.key,
    required this.records,
    required this.onExport,
    required this.onRefresh,
  });

  final List<AttendanceEntity> records;
  final VoidCallback onExport;
  final Future<void> Function() onRefresh;

  @override
  State<IosAttendanceCalendar> createState() => _IosAttendanceCalendarState();
}

class _IosAttendanceCalendarState extends State<IosAttendanceCalendar> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  HistoryViewMode _viewMode = HistoryViewMode.calendar;
  String? _listTypeFilter;

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
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
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

  Future<void> _openGoogleMeet([String? meetingCode]) async {
    final url = (meetingCode != null && meetingCode.trim().isNotEmpty)
        ? (meetingCode.startsWith('http')
            ? meetingCode.trim()
            : 'https://meet.google.com/${meetingCode.trim()}')
        : 'https://meet.google.com/new';
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir Google Meet: $e'),
            backgroundColor: AppColors.systemRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _promptJoinMeetDialog() {
    final codeCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.video_camera_front_rounded, color: Color(0xFF00897B), size: 22),
            SizedBox(width: 8),
            Text('Unirse a Google Meet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa el código o enlace de la reunión (100% gratis):',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ej. abc-defg-hij',
                prefixIcon: const Icon(Icons.link_rounded, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              final code = codeCtrl.text.trim();
              Navigator.pop(ctx);
              if (code.isNotEmpty) {
                _openGoogleMeet(code);
              }
            },
            icon: const Icon(Icons.videocam_rounded, size: 16),
            label: const Text('Unirse'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToGoogleCalendar({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
  }) async {
    final startStr = DateFormat("yyyyMMdd'T'HHmmss").format(start.toUtc());
    final endStr = DateFormat("yyyyMMdd'T'HHmmss").format(end.toUtc());
    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent(title)}'
      '&dates=${startStr}Z/${endStr}Z'
      '&details=${Uri.encodeComponent(description ?? 'Gestionado por SmartAttendance')}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir Google Calendar: $e'),
            backgroundColor: AppColors.systemRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Registros del día seleccionado
  List<AttendanceEntity> get _recordsForSelectedDate {
    return widget.records.where((r) {
      final d = r.fecha.toLocal();
      return _isSameDay(d, _selectedDate);
    }).toList();
  }

  /// Mapa de fechas con registros en el mes enfocado
  Map<int, List<AttendanceEntity>> get _recordsByDayInMonth {
    final map = <int, List<AttendanceEntity>>{};
    for (final r in widget.records) {
      final d = r.fecha.toLocal();
      if (d.year == _focusedMonth.year && d.month == _focusedMonth.month) {
        map.putIfAbsent(d.day, () => []).add(r);
      }
    }
    return map;
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatSelectedDateTitle(DateTime dt) {
    const weekdays = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$weekday, ${dt.day} de $month';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra ejecutiva de navegación y vista (Mes / Agenda Meet / Lista)
            _buildExecutiveHeader(context, isDark),
            const SizedBox(height: 12),

            if (_viewMode == HistoryViewMode.calendar) ...[
              // Tarjeta principal del Calendario Cuadrícula
              _buildCalendarCard(context, isDark),
              const SizedBox(height: 14),

              // Cabecera del día seleccionado con botón de exportar
              _buildSelectedDayHeader(context, isDark),
              const SizedBox(height: 10),

              // Lista agrupada estilo iOS de marcaciones del día
              _buildDayGroupedList(context, isDark),
            ] else if (_viewMode == HistoryViewMode.timeline) ...[
              // Modo Cronograma estilo Google Calendar con Google Meet
              _buildGoogleMeetTimelineView(context, isDark),
            ] else ...[
              // Modo de lista completa
              _buildFullListView(context, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveHeader(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final isCurrentMonth = _focusedMonth.year == now.year && _focusedMonth.month == now.month;

    return Row(
      children: [
        // Selector de vista: Mes vs Agenda Meet vs Lista
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: context.cSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.cBorder, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _viewToggleItem(
                mode: HistoryViewMode.calendar,
                icon: Icons.calendar_month_rounded,
                label: 'Mes',
              ),
              _viewToggleItem(
                mode: HistoryViewMode.timeline,
                icon: Icons.video_camera_front_rounded,
                label: 'Agenda Meet',
              ),
              _viewToggleItem(
                mode: HistoryViewMode.list,
                icon: Icons.format_list_bulleted_rounded,
                label: 'Lista',
              ),
            ],
          ),
        ),
        const Spacer(),
        // Botón "Hoy"
        if (!isCurrentMonth || !_isSameDay(_selectedDate, now))
          TextButton.icon(
            onPressed: _goToToday,
            icon: const Icon(Icons.today_rounded, size: 15),
            label: const Text('Hoy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        const SizedBox(width: 6),
        // Botón de exportar
        IconButton(
          onPressed: widget.onExport,
          icon: const Icon(Icons.ios_share_rounded, size: 18),
          color: AppColors.primary,
          tooltip: 'Exportar asistencia',
          style: IconButton.styleFrom(
            backgroundColor: context.cSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: context.cBorder, width: 0.8),
            ),
            padding: const EdgeInsets.all(7),
          ),
        ),
      ],
    );
  }

  Widget _viewToggleItem({
    required HistoryViewMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _viewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : context.cTextSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : context.cTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context, bool isDark) {
    final monthTitle = _formatMonthYear(_focusedMonth);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = _focusedMonth.weekday; // 1 = Lunes ... 7 = Domingo
    final leadingEmptyCount = firstWeekday - 1; // Espacios vacíos antes del día 1
    final totalCells = leadingEmptyCount + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    final now = DateTime.now();
    final recordsByDay = _recordsByDayInMonth;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de mes con flechas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                color: context.cTextPrimary,
                onPressed: _goToPreviousMonth,
                tooltip: 'Mes anterior',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Text(
                monthTitle,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: context.cTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                color: context.cTextPrimary,
                onPressed: _goToNextMonth,
                tooltip: 'Mes siguiente',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fila de días de la semana
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeekdayLabel('L'),
              _WeekdayLabel('M'),
              _WeekdayLabel('M'),
              _WeekdayLabel('J'),
              _WeekdayLabel('V'),
              _WeekdayLabel('S'),
              _WeekdayLabel('D'),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 8),

          // Grilla del mes
          Column(
            children: List.generate(rowCount, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (colIndex) {
                    final cellIndex = rowIndex * 7 + colIndex;
                    final dayNumber = cellIndex - leadingEmptyCount + 1;

                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox(width: 38, height: 44);
                    }

                    final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
                    final isToday = _isSameDay(cellDate, now);
                    final isSelected = _isSameDay(cellDate, _selectedDate);
                    final dayRecords = recordsByDay[dayNumber] ?? const [];

                    return _buildDayCell(
                      dayNumber: dayNumber,
                      cellDate: cellDate,
                      isToday: isToday,
                      isSelected: isSelected,
                      records: dayRecords,
                      isDark: isDark,
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell({
    required int dayNumber,
    required DateTime cellDate,
    required bool isToday,
    required bool isSelected,
    required List<AttendanceEntity> records,
    required bool isDark,
  }) {
    final hasRecords = records.isNotEmpty;
    final hasEntry = records.any((r) => r.tipo.toLowerCase().contains('entrada'));
    final hasExit = records.any((r) => r.tipo.toLowerCase().contains('salida'));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedDate = cellDate),
      child: Container(
        width: 38,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primary, width: 1.2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isToday ? AppColors.primary : context.cTextPrimary),
                fontFeatures: AppDesignTokens.tabularFigures,
              ),
            ),
            const SizedBox(height: 3),
            if (hasRecords)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : (hasEntry && hasExit
                              ? AppColors.systemGreen
                              : (hasEntry ? AppColors.systemOrange : AppColors.primary)),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayHeader(BuildContext context, bool isDark) {
    final records = _recordsForSelectedDate;
    final count = records.length;
    final title = _formatSelectedDateTitle(_selectedDate);

    return Row(
      children: [
        const Icon(
          Icons.calendar_today_rounded,
          size: 15,
          color: AppColors.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: context.cTextPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: count > 0
                ? AppColors.systemGreen.withValues(alpha: 0.12)
                : context.cBorder.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count == 1 ? '1 marca' : '$count marcas',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: count > 0 ? AppColors.systemGreen : context.cTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayGroupedList(BuildContext context, bool isDark) {
    final records = _recordsForSelectedDate;

    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cBorder, width: 0.8),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 34,
              color: context.cTextSecondary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 8),
            Text(
              'Sin marcaciones en este día',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.cTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Selecciona otro día en el calendario o toca "Agenda Meet" para ver el cronograma horario.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: context.cTextSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(records.length, (index) {
          final r = records[index];
          final isLast = index == records.length - 1;
          return Column(
            children: [
              _buildDayRecordItem(context, r, isDark),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 58,
                  color: context.cBorder,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDayRecordItem(BuildContext context, AttendanceEntity record, bool isDark) {
    final info = attendanceTypeInfo(record.tipo);
    final timeStr = formatTimeOfDay(context, record.hora.toLocal());
    final hasAddress = record.direccion != null && record.direccion!.trim().isNotEmpty;

    return InkWell(
      onTap: () => HistoryDetailSheet.show(context, record),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Icono redondeado pastel
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(info.icon, color: info.color, size: 19),
            ),
            const SizedBox(width: 12),
            // Detalles de la marca
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        info.label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: context.cTextPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: info.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          record.tipo.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: info.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (hasAddress)
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 11, color: context.cTextSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            record.direccion!,
                            style: TextStyle(fontSize: 11, color: context.cTextSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Registro verificado en SQLite',
                      style: TextStyle(fontSize: 11, color: context.cTextSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Hora y chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                    fontFeatures: AppDesignTokens.tabularFigures,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: context.cTextSecondary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // VISTA CRONOGRAMA ESTILO GOOGLE CALENDAR & GOOGLE MEET (100% GRATIS)
  // ===========================================================================
  Widget _buildGoogleMeetTimelineView(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final isToday = _isSameDay(_selectedDate, now);
    final records = _recordsForSelectedDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Tarjeta de Google Meet (Llamadas & Salas 100% Gratis) ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0D322B), const Color(0xFF142724)]
                  : [const Color(0xFFE0F2F1), const Color(0xFFF1F8F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00897B).withValues(alpha: isDark ? 0.4 : 0.25),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.video_camera_front_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Google Meet Corporativo',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: context.cTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00897B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'GRATIS',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00897B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Salas de supervisión, comités y turnos en vivo',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: context.cTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openGoogleMeet(),
                      icon: const Icon(Icons.videocam_rounded, size: 16),
                      label: const Text('Iniciar Sala Meet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _promptJoinMeetDialog,
                    icon: const Icon(Icons.add_link_rounded, size: 16),
                    label: const Text('Unirse', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00897B),
                      side: const BorderSide(color: Color(0xFF00897B), width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      _addToGoogleCalendar(
                        title: 'Jornada Laboral SmartAttendance',
                        start: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 8, 0),
                        end: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 17, 0),
                        description: 'Turno registrado en SmartAttendance con validación biométrica.',
                      );
                    },
                    icon: const Icon(Icons.event_available_rounded, size: 18),
                    color: const Color(0xFF00897B),
                    tooltip: 'Sincronizar con Google Calendar (Gratis)',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: isDark ? 0.1 : 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Selector de Fecha del Cronograma ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: context.cSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cBorder, width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed: _goToPreviousDay,
                tooltip: 'Día anterior',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Text(
                _formatSelectedDateTitle(_selectedDate),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: context.cTextPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: _goToNextDay,
                tooltip: 'Día siguiente',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Línea de Tiempo Horaria Tipo Google Calendar ──
        Container(
          padding: const EdgeInsets.fromLTRB(8, 14, 12, 14),
          decoration: BoxDecoration(
            color: context.cSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cBorder, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leyenda de eventos
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _timelineLegendItem(color: const Color(0xFF1A73E8), label: 'Turno programado'),
                    _timelineLegendItem(color: const Color(0xFF1E8E3E), label: 'Marcaje verificado'),
                    _timelineLegendItem(color: const Color(0xFF00897B), label: 'Google Meet'),
                  ],
                ),
              ),

              // Bloque destacado de Google Meet programado para el día
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 12, right: 4),
                child: _buildGoogleCalendarMeetEvent(context, isDark),
              ),

              // Horas de 06:00 a 20:00
              ...List.generate(15, (index) {
                final hour = 6 + index;
                final hourStr = '${hour.toString().padLeft(2, '0')}:00';
                final isCurrentHour = isToday && now.hour == hour;

                // Marcas que ocurrieron en esta hora
                final marksInHour = records.where((r) => r.hora.toLocal().hour == hour).toList();

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Columna de hora
                          SizedBox(
                            width: 44,
                            child: Text(
                              hourStr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.cTextSecondary.withValues(alpha: 0.8),
                                fontFeatures: AppDesignTokens.tabularFigures,
                              ),
                            ),
                          ),
                          // Línea divisoria de hora
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(top: 7),
                              height: 0.7,
                              color: context.cBorder.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Si hay marcas reales en esta hora, renderizar tarjetas de evento estilo Google Calendar
                    if (marksInHour.isNotEmpty)
                      Positioned(
                        left: 48,
                        right: 4,
                        top: 2,
                        child: Column(
                          children: marksInHour.map((m) {
                            return _buildTimelineEventCard(context, m, isDark);
                          }).toList(),
                        ),
                      ),

                    // Línea roja indicadora de hora actual si es hoy y coincide la hora
                    if (isCurrentHour)
                      Positioned(
                        left: 36,
                        right: 0,
                        top: 14 + (now.minute / 60) * 28,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEA4335), // Rojo Google Calendar
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: const Color(0xFFEA4335),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: context.cTextSecondary),
        ),
      ],
    );
  }

  Widget _buildGoogleCalendarMeetEvent(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF00897B).withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: Color(0xFF00897B), width: 3.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.video_call_rounded, color: Color(0xFF00897B), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reunión de Sincronización Operativa',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                  ),
                ),
                Text(
                  '10:00 - 10:45 AM · Google Meet (Enlace Corporativo)',
                  style: TextStyle(fontSize: 11, color: context.cTextSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _openGoogleMeet(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(60, 28),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Unirse', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEventCard(BuildContext context, AttendanceEntity record, bool isDark) {
    final info = attendanceTypeInfo(record.tipo);
    final timeStr = formatTimeOfDay(context, record.hora.toLocal());

    return GestureDetector(
      onTap: () => HistoryDetailSheet.show(context, record),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: info.color.withValues(alpha: isDark ? 0.22 : 0.1),
          borderRadius: BorderRadius.circular(9),
          border: Border(
            left: BorderSide(color: info.color, width: 3.5),
          ),
        ),
        child: Row(
          children: [
            Icon(info.icon, size: 16, color: info.color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${info.label} ($timeStr)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.cTextPrimary,
                    ),
                  ),
                  if (record.direccion != null && record.direccion!.isNotEmpty)
                    Text(
                      record.direccion!,
                      style: TextStyle(fontSize: 10.5, color: context.cTextSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'Biometría y GPS validados en SQLite',
                      style: TextStyle(fontSize: 10.5, color: context.cTextSecondary),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: context.cTextSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildFullListView(BuildContext context, bool isDark) {
    var filtered = widget.records;
    if (_listTypeFilter != null) {
      filtered = filtered.where((r) => r.tipo == _listTypeFilter).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtros de tipo de marca
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _typeFilterChip(label: 'Todas', type: null),
              ...attendanceTypes.map((t) {
                return _typeFilterChip(label: attendanceTypeInfo(t).label, type: t);
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.cSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.cBorder, width: 0.8),
            ),
            child: Text(
              'No hay registros con el filtro seleccionado.',
              style: TextStyle(fontSize: 12.5, color: context.cTextSecondary),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: context.cSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.cBorder, width: 0.8),
            ),
            child: Column(
              children: List.generate(filtered.length, (index) {
                final r = filtered[index];
                final isLast = index == filtered.length - 1;
                final dateStr = DateFormat('dd/MM/yyyy').format(r.fecha.toLocal());

                return Column(
                  children: [
                    InkWell(
                      onTap: () => HistoryDetailSheet.show(context, r),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: attendanceTypeInfo(r.tipo).color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                attendanceTypeInfo(r.tipo).icon,
                                color: attendanceTypeInfo(r.tipo).color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    attendanceTypeInfo(r.tipo).label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: context.cTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.cTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatTimeOfDay(context, r.hora.toLocal()),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.cTextPrimary,
                                fontFeatures: AppDesignTokens.tabularFigures,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: context.cTextSecondary.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(height: 1, thickness: 0.5, indent: 56, color: context.cBorder),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _typeFilterChip({required String label, required String? type}) {
    final isSelected = _listTypeFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _listTypeFilter = type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : context.cSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : context.cBorder,
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : context.cTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.cTextSecondary.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
