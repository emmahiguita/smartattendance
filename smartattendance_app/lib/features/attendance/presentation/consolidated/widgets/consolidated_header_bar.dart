// ============================================================================
// ARCHIVO: consolidated_header_bar.dart
// CAPA: Presentation / Consolidated / Widgets
// QUÉ HACE: Barra superior estilo Apple iOS con botones de Registrar (+),
//           Exportar (.xlsx/.csv) y Cerrar sobre fondo negro puro (#000000).
// CÓMO FUNCIONA: Despliega título, subtítulo dinámico y acciones compactas.
// POR QUÉ: Permite crear asistencias manuales y exportar sin desbordamientos
//          (< 175 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../controllers/consolidated_attendance_state.dart';

class ConsolidatedHeaderBar extends StatelessWidget {
  const ConsolidatedHeaderBar({
    super.key,
    required this.state,
    required this.onClose,
    required this.onExportTap,
    this.onCreateTap,
  });

  final ConsolidatedAttendanceState state;
  final VoidCallback onClose;
  final VoidCallback onExportTap;
  final VoidCallback? onCreateTap;

  String _formatSubtitle() {
    final count = state.totalJornadas;
    final plural = count == 1 ? 'registro' : 'registros';
    try {
      if (state.startDate != null && state.endDate != null) {
        final f = DateFormat('d MMM', 'es');
        return '${f.format(state.startDate!)} - ${f.format(state.endDate!)} · $count $plural';
      } else if (state.startDate != null) {
        final f = DateFormat('d MMM yyyy', 'es');
        return 'Desde ${f.format(state.startDate!)} · $count $plural';
      }
      final now = DateTime.now();
      final f = DateFormat('d MMM yyyy', 'es');
      return '${f.format(now)} · $count $plural';
    } catch (_) {
      final now = DateTime.now();
      return '${now.day}/${now.month}/${now.year} · $count $plural';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(
          bottom: BorderSide(color: context.cBorder, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 34,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Consolidado de Asistencias',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.35,
                        color: context.cTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatSubtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: context.cTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onCreateTap != null) ...[
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  minimumSize: const Size(30, 30),
                  onPressed: onCreateTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.add,
                        size: 13,
                        color: context.cTextPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Registrar',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: context.cTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                minimumSize: const Size(30, 30),
                onPressed: state.isExporting ? null : onExportTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.share_up,
                      size: 13,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.selectedCount > 0
                          ? 'Exportar (${state.selectedCount})'
                          : 'Exportar',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(30, 30),
                onPressed: onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 13,
                    color: context.cTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
