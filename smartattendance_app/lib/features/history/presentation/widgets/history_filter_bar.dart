// lib/features/history/presentation/widgets/history_filter_bar.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/attendance_type.dart';

enum HistoryRange { hoy, semana, mes, todos }

/// ============================================================================
/// COMPONENTE: HistoryFilterBar (Estilo iOS Chips)
/// ============================================================================
/// QUÉ HACE:
/// Barra horizontal de filtros por rango temporal (Hoy, Semana, Mes, Todos) y
/// tipos de marcación laboral con diseño Apple HIG.
///
/// CÓMO FUNCIONA:
/// Muestra chips táctiles con bordes de 0.5dp y transiciones de selección.
///
/// POR QUÉ:
/// Desacopla la lógica de filtrado de la pantalla principal (< 200 líneas).
/// ============================================================================
class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({
    super.key,
    required this.selectedRange,
    required this.selectedType,
    required this.onRangeChanged,
    required this.onTypeChanged,
  });

  final HistoryRange selectedRange;
  final String? selectedType;
  final ValueChanged<HistoryRange> onRangeChanged;
  final ValueChanged<String?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: HistoryRange.values.map((r) {
              final sel = selectedRange == r;
              final label = switch (r) {
                HistoryRange.hoy => 'Hoy',
                HistoryRange.semana => 'Semana',
                HistoryRange.mes => 'Mes',
                HistoryRange.todos => 'Todos',
              };

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onRangeChanged(r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sel ? AppColors.primary : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                        color: sel ? Colors.white : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _typeChip(context, label: 'Todas las marcas', type: null, isDark: isDark),
              ...attendanceTypes.map((t) {
                return _typeChip(context, label: attendanceTypeInfo(t).label, type: t, isDark: isDark);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _typeChip(BuildContext context, {required String label, required String? type, required bool isDark}) {
    final sel = selectedType == type;
    final info = type != null ? attendanceTypeInfo(type) : null;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => onTypeChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: sel ? (info?.color ?? AppColors.systemBlue) : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: sel ? (info?.color ?? AppColors.systemBlue) : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (info != null) ...[
                Icon(info.icon, size: 12, color: sel ? Colors.white : info.color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                  color: sel ? Colors.white : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
