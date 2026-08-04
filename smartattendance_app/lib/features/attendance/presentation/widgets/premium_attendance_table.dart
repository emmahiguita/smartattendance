import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/attendance_type.dart';
import '../../../../core/utils/time_format.dart';
import '../../data/models/attendance_model.dart';

/// Enterprise Attendance Table — Main data table (70% of dashboard).
/// Shows real employee names, entry/exit badges, date and time.
class PremiumAttendanceTable extends StatelessWidget {
  final List<AttendanceModel> attendances;

  const PremiumAttendanceTable({super.key, required this.attendances});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cSurface,
        border: Border.all(color: context.cBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TableHeader(total: attendances.length),
          Divider(height: 1, color: context.cBorder),
          _ColumnHeaders(),
          Divider(height: 1, color: context.cBorder),
          if (attendances.isEmpty)
            const _EmptyState()
          else
            _TableRows(attendances: attendances),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TABLE HEADER (Title + Actions)
// ═══════════════════════════════════════════════════════════════════════
class _TableHeader extends StatelessWidget {
  final int total;
  const _TableHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Text(
            'Asistencias Recientes',
            style: TextStyle(
              color: context.cTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$total registros',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// COLUMN HEADERS
// ═══════════════════════════════════════════════════════════════════════
class _ColumnHeaders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: context.cBackground.withValues(alpha: 0.4),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _ColLabel('EMPLEADO')),
          Expanded(flex: 2, child: _ColLabel('TIPO')),
          Expanded(flex: 2, child: _ColLabel('FECHA')),
          Expanded(flex: 2, child: _ColLabel('HORA')),
        ],
      ),
    );
  }
}

class _ColLabel extends StatelessWidget {
  final String text;
  const _ColLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.cTextTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, color: context.cTextTertiary, size: 40),
            const SizedBox(height: 12),
            Text(
              'No hay registros de asistencia',
              style: TextStyle(
                  color: context.cTextSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Los registros aparecerán cuando los empleados marquen asistencia.',
              style: TextStyle(color: context.cTextTertiary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TABLE ROWS — Shows up to 15 sorted records
// ═══════════════════════════════════════════════════════════════════════
class _TableRows extends StatelessWidget {
  final List<AttendanceModel> attendances;
  const _TableRows({required this.attendances});

  @override
  Widget build(BuildContext context) {
    // Sort newest first
    final sorted = List<AttendanceModel>.from(attendances)
      ..sort((a, b) {
        final dateCompare = b.fecha.compareTo(a.fecha);
        if (dateCompare != 0) return dateCompare;
        return b.hora.compareTo(a.hora);
      });

    final display = sorted.take(15).toList();

    return Column(
      children: display.asMap().entries.map((entry) {
        final i = entry.key;
        final record = entry.value;
        return _AttendanceRowWidget(data: record)
            .animate()
            .fadeIn(delay: Duration(milliseconds: 30 * i), duration: 300.ms)
            .slideX(begin: 0.02, end: 0, curve: Curves.easeOutCubic);
      }).toList(),
    );
  }
}

class _AttendanceRowWidget extends StatefulWidget {
  final AttendanceModel data;
  const _AttendanceRowWidget({required this.data});

  @override
  State<_AttendanceRowWidget> createState() => _AttendanceRowWidgetState();
}

class _AttendanceRowWidgetState extends State<_AttendanceRowWidget> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final dateFmt = DateFormat('dd/MM/yyyy');

    final info = attendanceTypeInfo(d.tipo);
    final badgeColor = info.color;
    final badgeText = info.label;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _hover
              ? AppColors.primary.withValues(alpha: 0.03)
              : Colors.transparent,
          border:
              Border(bottom: BorderSide(color: context.cBorder, width: 0.5)),
        ),
        child: Row(
          children: [
            // Employee name (real, from API)
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        d.fullName.isNotEmpty
                            ? d.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.fullName,
                          style: TextStyle(
                            color: context.cTextPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (d.cedulaEmpleado != null)
                          Text(
                            'C.C. ${d.cedulaEmpleado}',
                            style: TextStyle(
                              color: context.cTextTertiary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Type badge
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Text(
                dateFmt.format(d.fecha),
                style: TextStyle(
                    color: context.cTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
            // Time
            Expanded(
              flex: 2,
              child: Text(
                formatTimeOfDay(context, d.hora.toLocal()),
                style: TextStyle(
                  color: context.cTextPrimary,
                  fontSize: 13,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
