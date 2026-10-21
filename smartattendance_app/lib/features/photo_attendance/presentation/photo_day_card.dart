import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/photo_record.dart';
import '../domain/work_schedule.dart';
import 'journey_summary.dart';

/// Una tarjeta por trabajador y fecha. Cada etapa conserva sus horas y fotos;
/// si hay varias marcas se muestran todas, sin elegir una en silencio.
class PhotoDayCard extends StatelessWidget {
  const PhotoDayCard({super.key, required this.day, this.onChanged});
  final PhotoDay day;
  final VoidCallback? onChanged;
  static const stages = {
    'entrada': 'Entrada',
    'salida_almuerzo': 'Inicio de almuerzo',
    'regreso_almuerzo': 'Regreso de almuerzo',
    'salida': 'Salida'
  };

  Widget _mark(BuildContext context, PhotoRecord record) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
          onTap: () => showDialog<void>(
              context: context,
              builder: (context) => Dialog(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                        child: InteractiveViewer(
                            child: Image.file(File(record.localPath),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text('Foto no disponible.'))))),
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                            '${stages[record.type]} · ${ColombiaClock.hour(record.capturedAt)}')),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(record.location?.description ??
                            'Registro anterior sin ubicación guardada.')),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar')),
                  ]))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(record.localPath),
                    width: 64,
                    height: 72,
                    cacheWidth: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                        width: 64,
                        height: 72,
                        child: Icon(Icons.broken_image_outlined)))),
            const SizedBox(width: 10),
            Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text(ColombiaClock.hour(record.capturedAt),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(record.location?.description ?? 'Sin GPS guardado',
                      style: Theme.of(context).textTheme.bodySmall),
                ])),
          ])));

  @override
  Widget build(BuildContext context) => Card.filled(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(day.worker.name,
                style: Theme.of(context).textTheme.titleLarge),
            Text(
                'C.C. ${day.worker.document}${day.worker.job.isEmpty ? '' : ' · ${day.worker.job}'}'),
            const SizedBox(height: 4),
            Text(DateFormat('EEEE dd/MM/yyyy', 'es').format(day.date),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, size) {
              final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final columns = size.maxWidth >= 340 * scale ? 2 : 1;
              final width = (size.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(spacing: 12, runSpacing: 12, children: [
                for (final stage in stages.entries)
                  SizedBox(
                      width: width,
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(stage.value,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    if (day.marks(stage.key).isEmpty)
                                      const Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text('Sin registrar')),
                                    for (final record in day.marks(stage.key))
                                      _mark(context, record),
                                  ])))),
              ]);
            }),
            JourneySummary(day: day, onChanged: onChanged),
          ])));
}
