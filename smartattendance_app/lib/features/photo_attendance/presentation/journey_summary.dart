import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/photo_record.dart';
import '../domain/journey_report.dart';
import 'local_providers.dart';

/// Métricas añadidas al historial existente. La revisión queda ligada a la
/// jornada y al administrador; nunca basta con mostrar una etiqueta «aprobado».
class JourneySummary extends ConsumerStatefulWidget {
  const JourneySummary({super.key, required this.day, this.onChanged});
  final PhotoDay day;
  final VoidCallback? onChanged;
  @override
  ConsumerState<JourneySummary> createState() => _JourneySummaryState();
}

class _JourneySummaryState extends ConsumerState<JourneySummary> {
  bool _busy = false;
  Future<void> _review(String action) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Revisión del administrador'),
                content: Text(switch (action) {
                  'approve' =>
                    'Reconocer el tiempo adicional calculado para esta jornada.',
                  'reject' =>
                    'Registrar que el tiempo adicional no fue aprobado.',
                  'schedule' =>
                    'Aplicar a esta jornada histórica el horario actualmente asignado al trabajador. Las marcas y fotos se conservan.',
                  _ =>
                    'Cerrar como incompleta sin inventar una salida. Se conservan todas las fotos y horas.',
                }),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Confirmar'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final store = ref.read(localAdminStoreProvider);
      if (action == 'schedule') {
        await store.applySchedule(widget.day);
      } else {
        await store.review(widget.day,
            approve: action == 'approve', abandon: action == 'void');
      }
      widget.onChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is FormatException
                ? e.message
                : 'No se pudo guardar la revisión.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = JourneyReport.labels(widget.day);
    final admin = ref.watch(localActorProvider).isAdmin;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Divider(),
      Row(children: [
        Expanded(
            child: Text(values['Estado de jornada']!,
                style: Theme.of(context).textTheme.titleSmall)),
        if (admin && widget.day.status != 'void')
          PopupMenuButton<String>(
              enabled: !_busy,
              onSelected: _review,
              tooltip: 'Revisar jornada',
              itemBuilder: (_) => [
                    if (widget.day.schedule == null)
                      const PopupMenuItem(
                          value: 'schedule',
                          child: Text('Aplicar jornada pactada')),
                    if (widget.day.totals.complete &&
                        widget.day.schedule != null) ...[
                      const PopupMenuItem(
                          value: 'approve', child: Text('Aprobar adicional')),
                      const PopupMenuItem(
                          value: 'reject', child: Text('No aprobar adicional'))
                    ],
                    if (!widget.day.totals.complete)
                      const PopupMenuItem(
                          value: 'void', child: Text('Cerrar como incompleta')),
                  ]),
      ]),
      for (final key in [
        'Tiempo trabajado',
        'Almuerzo registrado',
        'Adicional por revisar',
        'Adicional aprobado'
      ])
        Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('$key: ${values[key]}')),
      ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Detalle de tiempo'),
          children: [
            for (final e in values.entries.where((e) => ![
                  'Estado de jornada',
                  'Tiempo trabajado',
                  'Almuerzo registrado',
                  'Adicional por revisar',
                  'Adicional aprobado'
                ].contains(e.key)))
              if (e.value.isNotEmpty)
                Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text('${e.key}: ${e.value}'))),
            const Text(
                'Domingos y festivos pueden coincidir; no se suman nuevamente al total. El adicional se revisa según el régimen y horario pactados.'),
          ]),
      if (_busy) const LinearProgressIndicator(),
    ]);
  }
}
