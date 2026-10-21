// lib/features/history/presentation/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../attendance/presentation/widgets/export_preview_sheet.dart';
import '../../../photo_attendance/presentation/local_day_history.dart';
import '../viewmodels/history_viewmodel.dart';
import '../widgets/ios_attendance_calendar.dart';

/// ============================================================================
/// PANTALLA: HistoryScreen (Estilo Apple iOS Glass con Calendario Profesional)
/// ============================================================================
/// QUÉ HACE:
/// Muestra el calendario interactivo y el historial de asistencia del colaborador
/// con datos reales de SQLite sin anidamientos redundantes de AppBar.
///
/// CÓMO FUNCIONA:
/// 1. Observa [localDayHistoryProvider] para reflejar marcas inmediatamente.
/// 2. Renderiza [IosAttendanceCalendar] con selección interactiva mensual y diaria.
/// 3. Abre [ExportPreviewSheet] con [useRootNavigator: true] para evitar solapamientos.
///
/// POR QUÉ:
/// Principio SRP y Clean Architecture: interfaz moderna inspirada en iOS Calendar.
/// ============================================================================
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  void _openExportSheet(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportPreviewSheet(
        fechaDesde: firstDayOfMonth,
        fechaHasta: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(localDayHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return historyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.systemRed),
              const SizedBox(height: 12),
              Text(
                'No se pudo cargar el historial: $err',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(localDayHistoryProvider),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reintentar'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
      data: (records) {
        return IosAttendanceCalendar(
          records: records,
          onExport: () => _openExportSheet(context),
          onRefresh: () async {
            ref.invalidate(localDayHistoryProvider);
            await ref.read(historyViewModelProvider.notifier).loadHistory();
          },
        );
      },
    );
  }
}
