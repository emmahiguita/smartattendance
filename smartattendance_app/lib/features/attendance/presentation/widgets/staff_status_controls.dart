import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Controles de consulta del equipo: total activo, búsqueda y filtro de jornada.
/// Solo notifica cambios; el panel padre conserva y filtra los datos reales.
class StaffStatusControls extends StatelessWidget {
  const StaffStatusControls({
    super.key,
    required this.controller,
    required this.search,
    required this.filter,
    required this.activeCount,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final String search, filter;
  final int activeCount, totalCount;
  final ValueChanged<String> onSearchChanged, onFilterChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final neutral = dark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final secondary = dark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text('Estado del personal',
              style: TextStyle(
                  color: context.cTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ),
        Text('$activeCount/$totalCount activos',
            style: TextStyle(
                color: secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: AppDesignTokens.tabularFigures)),
      ]),
      const SizedBox(height: 10),
      TextField(
        controller: controller,
        onChanged: onSearchChanged,
        style: TextStyle(color: context.cTextPrimary, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Buscar trabajador o cédula',
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: secondary),
          suffixIcon: search.isEmpty
              ? null
              : IconButton(
                  onPressed: onClearSearch,
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
          filled: true,
          fillColor: neutral,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Todos', 'todos', neutral, dark),
            _filterChip('En jornada', 'en_jornada', neutral, dark),
            _filterChip('Sin entrada', 'sin_entrada', neutral, dark),
            _filterChip('Jornada cerrada', 'jornada_cerrada', neutral, dark),
            _filterChip('Incompletos', 'incompletos', neutral, dark),
          ],
        ),
      ),
    ]);
  }

  /// Un chip representa un filtro; la selección se delega al panel padre.
  Widget _filterChip(String label, String value, Color neutral, bool dark) {
    final selected = filter == value;
    final textColor = selected
        ? Colors.white
        : (dark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70));

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onFilterChanged(value),
        selectedColor: AppColors.primary,
        backgroundColor: neutral,
        labelStyle: TextStyle(color: textColor, fontSize: 11),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
