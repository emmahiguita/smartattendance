// lib/features/photo_attendance/presentation/local_attendance_home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/photo_record.dart';
import '../domain/mark_sequence.dart';
import '../data/capture_draft.dart';
import 'local_providers.dart';
import 'photo_capture_screen.dart';
import 'photo_history_screen.dart';
import 'worker_dialog.dart';
import 'worker_assignment_dialog.dart';

/// ============================================================================
/// PANTALLA: LocalAttendanceHome (Directorio de Selección de Colaborador)
/// ============================================================================
/// QUÉ HACE:
/// Permite al operador o supervisor seleccionar un colaborador registrado en el
/// dispositivo para abrir la cámara de reconocimiento facial y GPS real.
///
/// CÓMO FUNCIONA:
/// 1. Recupera borradores si Android interrumpió la captura previa.
/// 2. Búsqueda reactiva por nombre o cédula.
/// 3. Abre de inmediato [PhotoCaptureScreen] sin pasos intermedios.
///
/// POR QUÉ:
/// Principio SRP: navegación limpia sin duplicidad de botones "Marcar" (< 190 líneas).
/// ============================================================================
class LocalAttendanceHome extends ConsumerStatefulWidget {
  const LocalAttendanceHome({super.key, this.initialType});
  final String? initialType;

  @override
  ConsumerState<LocalAttendanceHome> createState() => _LocalAttendanceHomeState();
}

class _LocalAttendanceHomeState extends ConsumerState<LocalAttendanceHome> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverCapture());
  }

  Future<void> _recoverCapture() async {
    try {
      final draft = await CaptureDraft().recover();
      if (!mounted || draft == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute<bool>(
          builder: (_) => PhotoCaptureScreen(
            worker: draft.worker,
            initialPath: draft.path,
            initialType: draft.type,
            initialCaptureId: draft.captureId,
          ),
        ),
      );
    } catch (_) {}
  }

  void _create() => showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const WorkerDialog(),
      );

  Widget _workerItem(LocalWorker worker) {
    final next = MarkSequence.next(worker.lastMark);
    final requested = widget.initialType ?? next;
    final initial = worker.name.trim().isEmpty ? '?' : worker.name.trim().substring(0, 1).toUpperCase();
    final isAdmin = ref.watch(localActorProvider).isAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6), width: 0.8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 19,
          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
          child: Text(initial, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 13.5)),
        ),
        title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('C.C. ${worker.document}${worker.job.isEmpty ? '' : ' · ${worker.job}'}\nSiguiente: $next', style: const TextStyle(fontSize: 11.5)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(next, style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 18),
                onPressed: () => showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => WorkerAssignmentDialog(worker: worker)),
              ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<bool>(builder: (_) => PhotoCaptureScreen(worker: worker, initialType: requested)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workers = ref.watch(localWorkersProvider);
    final isAdmin = ref.watch(localActorProvider).isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colaboradores'),
        actions: [
          IconButton(
            tooltip: 'Historial y reportes',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PhotoHistoryScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _search = val.trim().toLowerCase()),
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Buscar por nombre o cédula…',
                            prefixIcon: Icon(Icons.search_rounded, size: 18),
                          ),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        IconButton.filled(onPressed: _create, tooltip: 'Registrar colaborador', icon: const Icon(Icons.person_add_rounded, size: 18)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: workers.when(
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (_, __) => Center(child: TextButton(onPressed: () => ref.invalidate(localWorkersProvider), child: const Text('Reintentar cargar'))),
                      data: (rows) {
                        final filtered = rows.where((w) => w.name.toLowerCase().contains(_search) || w.document.contains(_search)).toList();
                        if (rows.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey),
                                const SizedBox(height: 10),
                                const Text('No hay colaboradores registrados.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                if (isAdmin) ...[
                                  const SizedBox(height: 12),
                                  FilledButton.icon(onPressed: _create, icon: const Icon(Icons.person_add_rounded, size: 16), label: const Text('Registrar colaborador')),
                                ],
                              ],
                            ),
                          );
                        }
                        if (filtered.isEmpty) return const Center(child: Text('Sin coincidencias en la búsqueda.'));
                        return ListView.builder(itemCount: filtered.length, itemBuilder: (_, i) => _workerItem(filtered[i]));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
