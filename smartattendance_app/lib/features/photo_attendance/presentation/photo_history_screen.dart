import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/photo_pdf_exporter.dart';
import '../data/photo_xlsx_exporter.dart';
import '../domain/photo_record.dart';
import 'local_providers.dart';
import 'photo_day_card.dart';
import 'photo_share.dart';

/// Historial local paginado y búsqueda explícita. No consulta internet ni tiene
/// timers/polling. Los resultados obsoletos se descartan con una generación.
class PhotoHistoryScreen extends ConsumerStatefulWidget {
  const PhotoHistoryScreen({super.key});
  @override
  ConsumerState<PhotoHistoryScreen> createState() => _PhotoHistoryScreenState();
}

class _PhotoHistoryScreenState extends ConsumerState<PhotoHistoryScreen> {
  final _search = TextEditingController();
  final _records = <PhotoDay>[];
  bool _loading = false, _more = true, _exporting = false;
  int _generation = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _generation++;
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading && !reset) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) _records.clear();
    });
    try {
      final rows = await ref
          .read(localPhotoRepositoryProvider)
          .days(skip: _records.length, search: _search.text.trim());
      if (!mounted || generation != _generation) return;
      setState(() {
        _records.addAll(rows);
        _more = rows.length == 20;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _error = 'No se pudo leer el historial local.');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _export(String format) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final repository = ref.read(localPhotoRepositoryProvider);
      final paths = switch (format) {
        'pdf' => await PhotoPdfExporter().export(repository),
        'xlsx' => await PhotoXlsxExporter().export(repository),
        _ => [await repository.exportCsv()],
      };
      if (!mounted) return;
      await shareAttendanceFiles(context, paths);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No se pudo exportar o abrir el selector para compartir.')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Historial con fotos'), actions: [
          PopupMenuButton<String>(
              enabled: !_exporting,
              tooltip: 'Exportar y compartir',
              onSelected: _export,
              itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'pdf',
                        child: Text('PDF con fotos (todo el historial)')),
                    PopupMenuItem(
                        value: 'xlsx',
                        child:
                            Text('Excel XLSX con fotos (todo el historial)')),
                    PopupMenuItem(
                        value: 'csv',
                        child: Text(
                            'CSV con horas y referencias de fotos (todo)')),
                  ],
              icon: const Icon(Icons.ios_share)),
        ]),
        body: SafeArea(
            child: Column(children: [
          if (_exporting) const LinearProgressIndicator(),
          Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                  controller: _search,
                  onSubmitted: (_) => _load(reset: true),
                  decoration: InputDecoration(
                      labelText: 'Buscar nombre o cédula',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                          onPressed: () => _load(reset: true),
                          icon: const Icon(Icons.arrow_forward))))),
          if (_error != null)
            TextButton(
                onPressed: () => _load(reset: true), child: Text(_error!)),
          if (_loading && _records.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_records.isEmpty)
            const Expanded(
                child: Center(child: Text('No hay asistencias para mostrar.')))
          else
            Expanded(
                child: RefreshIndicator(
                    onRefresh: () => _load(reset: true),
                    child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _records.length + 1,
                        itemBuilder: (context, index) {
                          if (index < _records.length) {
                            return PhotoDayCard(
                                key: ValueKey(_records[index].id),
                                day: _records[index],
                                onChanged: () => _load(reset: true));
                          }
                          return Padding(
                              padding: const EdgeInsets.all(16),
                              child: _more
                                  ? OutlinedButton(
                                      onPressed: _loading ? null : _load,
                                      child: Text(_loading
                                          ? 'Cargando…'
                                          : 'Cargar más'))
                                  : const Text('Fin del historial',
                                      textAlign: TextAlign.center));
                        }))),
        ])),
      );
}
