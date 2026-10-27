// ============================================================================
// ARCHIVO: local_attendance_home.dart
// QUÉ HACE: Directorio de colaboradores y marcaciones estilo Apple iOS con
//           el compositor de cristal `NanoCompactGlassComposer` integrado.
// CÓMO FUNCIONA: Lista en `IosGlassCard`, cabecera translúcida e input Nano
//                con menú anclado [+] para cámara, fotos, archivos y WhatsApp.
// POR QUÉ: Cumple estrictamente SRP y la regla de < 185 líneas.
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/capture_draft.dart';
import '../domain/mark_sequence.dart';
import '../domain/photo_record.dart';
import 'local_providers.dart';
import 'photo_capture_screen.dart';
import 'photo_history_screen.dart';
import 'worker_assignment_dialog.dart';
import 'worker_dialog.dart';

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

  void _create() => showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => const WorkerDialog());

  Widget _workerItem(LocalWorker worker) {
    final next = MarkSequence.next(worker.lastMark);
    final requested = widget.initialType ?? next;
    final initial = worker.name.trim().isEmpty ? '?' : worker.name.trim().substring(0, 1).toUpperCase();
    final isAdmin = ref.watch(localActorProvider).isAdmin;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IosGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: 14,
        onTap: () => Navigator.push(context, MaterialPageRoute<bool>(builder: (_) => PhotoCaptureScreen(worker: worker, initialType: requested))),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 0.8),
              ),
              child: Center(child: Text(initial, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(worker.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: context.cTextPrimary)),
                  const SizedBox(height: 2),
                  Text('C.C. ${worker.document}${worker.job.isEmpty ? '' : ' · ${worker.job}'}', style: TextStyle(fontSize: 11.5, color: context.cTextSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: AppColors.systemGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.systemGreen.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Text(next, style: const TextStyle(color: AppColors.systemGreen, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(CupertinoIcons.slider_horizontal_3, size: 16, color: context.cTextSecondary),
                onPressed: () => showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => WorkerAssignmentDialog(worker: worker)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isAdmin) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(54),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: context.cSurface.withValues(alpha: context.isDark ? 0.72 : 0.85),
              border: Border(bottom: BorderSide(color: context.cBorder.withValues(alpha: 0.6), width: 0.6)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  IconButton(icon: const Icon(CupertinoIcons.back, size: 20), onPressed: () => Navigator.maybePop(context)),
                  const SizedBox(width: 4),
                  Text('Directorio de Personal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.cTextPrimary)),
                  const Spacer(),
                  IconButton(tooltip: 'Historial', icon: const Icon(CupertinoIcons.clock, size: 19), onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PhotoHistoryScreen()))),
                  if (isAdmin) IconButton(tooltip: 'Registrar', icon: const Icon(CupertinoIcons.person_add, size: 19, color: AppColors.primary), onPressed: _create),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workers = ref.watch(localWorkersProvider);
    final isAdmin = ref.watch(localActorProvider).isAdmin;

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: _buildAppBar(context, isAdmin),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: CupertinoSearchTextField(
                  placeholder: 'Buscar colaborador por nombre o cédula…',
                  onChanged: (text) => setState(() => _search = text.toLowerCase().trim()),
                ),
              ),
              Expanded(
                child: workers.when(
                  loading: () => const Center(child: CupertinoActivityIndicator()),
                  error: (_, __) => Center(child: TextButton(onPressed: () => ref.invalidate(localWorkersProvider), child: const Text('Reintentar'))),
                  data: (rows) {
                    final filtered = rows.where((w) => w.name.toLowerCase().contains(_search) || w.document.contains(_search)).toList();
                    if (rows.isEmpty) {
                      return Center(child: Text('No hay colaboradores registrados.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: context.cTextPrimary)));
                    }
                    if (filtered.isEmpty) return Center(child: Text('Sin coincidencias para "$_search"', style: TextStyle(fontSize: 12.5, color: context.cTextSecondary)));
                    return ListView.builder(padding: const EdgeInsets.all(14), itemCount: filtered.length, itemBuilder: (_, i) => _workerItem(filtered[i]));
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
