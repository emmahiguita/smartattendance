// lib/features/attendance/presentation/widgets/staff_directory_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import 'staff_status_types.dart';
import 'staff_worker_tile.dart';
import 'worker_hr_management_sheet.dart';

/// ============================================================================
/// COMPONENTE: StaffDirectorySheet (Directorio de Empleados Estilo iOS)
/// ============================================================================
/// QUÉ HACE:
/// Despliega el listado completo y detallado del personal registrado en la app
/// con buscador en tiempo real, desglose por cédula y acceso a marcación directa.
///
/// CÓMO FUNCIONA:
/// Observa [localWorkersProvider], filtra por término de búsqueda y estado, y
/// permite abrir la captura biométrica para el trabajador seleccionado.
///
/// POR QUÉ:
/// Cumple con la solicitud de información completa, organizada y separada sin
/// saturación ni pantallas zombies (< 200 líneas).
/// ============================================================================
class StaffDirectorySheet extends ConsumerStatefulWidget {
  const StaffDirectorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showIosFloatingGlassSheet<void>(
      context: context,
      title: 'Directorio de Personal',
      subtitle: 'Colaboradores registrados y estado en tiempo real',
      maxHeightFactor: 0.85,
      child: const StaffDirectorySheet(),
    );
  }

  @override
  ConsumerState<StaffDirectorySheet> createState() => _StaffDirectorySheetState();
}

class _StaffDirectorySheetState extends ConsumerState<StaffDirectorySheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(localWorkersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = ColombiaClock.day(DateTime.now());

    return Column(
      children: [
        const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _search = val),
                style: TextStyle(color: context.cTextPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  hintText: 'Buscar por nombre, cargo o cédula…',
                  hintStyle: TextStyle(color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70), fontSize: 12.5),
                  prefixIcon: Icon(Icons.search_rounded, size: 16, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: workersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (workers) {
                final q = _search.trim().toLowerCase();
                final filtered = workers.where((w) {
                  if (q.isEmpty) return true;
                  return w.name.toLowerCase().contains(q) || w.document.toLowerCase().contains(q) || w.job.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('No se encontraron colaboradores', style: TextStyle(color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70))),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final worker = filtered[i];
                    final status = calculateStaffStatus(worker, today);
                    return StaffWorkerTile(
                      worker: worker,
                      status: status,
                      showDivider: i < filtered.length - 1,
                      onTap: () {
                        WorkerHrManagementSheet.show(context, worker: worker);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
  }
}
