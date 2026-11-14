// ============================================================================
// ARCHIVO: admin_dashboard_header.dart
// QUÉ HACE: Barra superior del dashboard administrativo en modo escritorio.
//           Incluye búsqueda en tiempo real, indicador de estado del sistema,
//           hora de última sincronización y avatar del administrador.
// CÓMO FUNCIONA: Recibe el estado del dashboard y callbacks para buscar/refrescar.
//                Usa PulseAlert para alertar visualmente cuando hay errores.
// POR QUÉ: Extraído de admin_dashboard_screen.dart para cumplir SRP (< 200 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/premium_animations.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';

// QUÉ HACE: Header del dashboard con búsqueda, estado del sistema y perfil.
// CÓMO: Recibe el estado vía props (no depende de Riverpod directamente).
// POR QUÉ: Widget extraído para mantener admin_dashboard_screen.dart < 200 líneas.
class AdminDashboardHeader extends StatelessWidget {
  const AdminDashboardHeader({
    super.key,
    required this.adminName,
    required this.state,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRefresh,
  });

  /// Nombre del administrador autenticado.
  final String adminName;

  /// Estado actual del dashboard (para mostrar errores y sync time).
  final AdminDashboardState state;

  /// Controlador del campo de búsqueda (gestionado por el padre).
  final TextEditingController searchController;

  /// Callback cuando cambia el texto de búsqueda.
  final ValueChanged<String> onSearchChanged;

  /// Callback para refrescar datos desde la API.
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: context.cBackgroundSecondary,
        border: Border(bottom: BorderSide(color: context.cBorder, width: 1)),
      ),
      child: Row(
        children: [
          // QUÉ HACE: Campo de búsqueda que filtra la tabla en tiempo real.
          Expanded(child: _buildSearchField(context)),
          const SizedBox(width: 32),

          // QUÉ HACE: Indicador pulsante de estado del sistema (verde=ok, rojo=error).
          _buildStatusIndicator(context),
          const SizedBox(width: 24),

          // QUÉ HACE: Muestra la hora de última sincronización con el servidor.
          _buildSyncLabel(context),
          const SizedBox(width: 24),

          // QUÉ HACE: Botón para forzar recarga manual de datos.
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Actualizar datos',
          ),
          const SizedBox(width: 16),

          // QUÉ HACE: Avatar con la inicial del admin y su cargo.
          _buildProfileBadge(context),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  // QUÉ HACE: Campo de texto para filtrar registros por nombre/cédula/tipo.
  Widget _buildSearchField(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.cSurface,
        border: Border.all(color: context.cBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: TextStyle(color: context.cTextPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar empleados, reportes...',
          hintStyle: TextStyle(color: context.cTextSecondary, fontSize: 14),
          prefixIcon:
              Icon(Icons.search, color: context.cTextSecondary, size: 20),
          suffixIcon: searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged('');
                  },
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // QUÉ HACE: Indicador visual que pulsea cuando hay error en el sistema.
  Widget _buildStatusIndicator(BuildContext context) {
    final hasError = state.error != null;
    final color = hasError ? AppColors.systemRed : AppColors.systemGreen;
    return PulseAlert(
      isActive: hasError,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              hasError ? 'Error' : 'Sistema Online',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // QUÉ HACE: Etiqueta de última sincronización con ícono de refresh.
  Widget _buildSyncLabel(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.refresh, color: context.cTextSecondary, size: 16),
        const SizedBox(width: 6),
        Text(
          'Sync: ${state.lastSyncLabel}',
          style: TextStyle(
            color: context.cTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // QUÉ HACE: Badge con avatar (inicial del nombre) y cargo del administrador.
  Widget _buildProfileBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cBorder),
      ),
      child: Row(
        children: [
          // QUÉ HACE: Círculo con gradiente y la inicial del nombre.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accentIndigo],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                adminName,
                style: TextStyle(
                  color: context.cTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Administrador',
                style: TextStyle(color: context.cTextSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
