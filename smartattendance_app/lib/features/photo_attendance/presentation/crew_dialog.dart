// ============================================================================
// ARCHIVO: crew_dialog.dart
// QUÉ HACE: Ventana flotante estilo iOS Inset Grouped para crear o editar un
//           Equipo de Trabajo / Cuadrilla (`crews`) con supervisor, geocerca
//           asociada y rango de vigencia.
// CÓMO FUNCIONA: Utiliza `IosFloatingModal` e `IosFormGroup` con selectores
//                limpios de geocerca y fechas de inicio/fin.
// POR QUÉ: Reemplaza el antiguo `AlertDialog` Material por un formulario iOS
//          coherente y libre de ruido visual (< 175 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'local_providers.dart';

class CrewDialog extends ConsumerStatefulWidget {
  const CrewDialog({super.key, this.crew, required this.zones});
  final Map<String, Object?>? crew;
  final List<Map<String, Object?>> zones;
  @override
  ConsumerState<CrewDialog> createState() => _CrewDialogState();
}

class _CrewDialogState extends ConsumerState<CrewDialog> {
  final _name = TextEditingController();
  final _supervisor = TextEditingController();
  final _alternate = TextEditingController();
  String? _from, _until, _error;
  int? _zone;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final team = widget.crew;
    final today = DateTime.now().toIso8601String().split('T').first;
    final nextYear = DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T').first;
    _from = today;
    _until = nextYear;
    if (team == null) return;
    _name.text = team['name'] as String;
    _supervisor.text = team['supervisor_document'] as String;
    _alternate.text = team['driver_document'] as String? ?? '';
    _zone = team['zone_id'] as int?;
    _from = team['valid_from'] as String;
    _until = team['valid_until'] as String;
  }

  @override
  void dispose() {
    _name.dispose();
    _supervisor.dispose();
    _alternate.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final current = start ? _from : _until;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(current ?? '') ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final value = date.toIso8601String().split('T').first;
    setState(() => start ? _from = value : _until = value);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _supervisor.text.trim().isEmpty) {
      setState(() => _error = 'Completa el nombre del equipo y cédula del supervisor.');
      return;
    }
    if (_from == null || _until == null) {
      setState(() => _error = 'Selecciona el período de vigencia.');
      return;
    }
    setState(() => (_busy = true, _error = null));
    try {
      await ref.read(localAdminStoreProvider).saveCrew({
        'name': _name.text.trim(),
        'supervisor_document': _supervisor.text.trim(),
        'driver_document': _alternate.text.trim(),
        'zone_id': _zone,
        'valid_from': _from,
        'valid_until': _until,
      }, id: widget.crew?['id'] as int?);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error is FormatException ? error.message : 'No se pudo guardar el equipo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.crew?['id'] as int?;
    if (id == null) return;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Eliminar Cuadrilla'),
        content: Text('¿Deseas eliminar la cuadrilla "${_name.text}"?'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => (_busy = true, _error = null));
      try {
        await ref.read(localAdminStoreProvider).deleteCrew(id);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) setState(() => _error = e is FormatException ? e.message : 'No se pudo eliminar el equipo.');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: IosFloatingModal(
        title: widget.crew == null ? 'Nuevo Equipo' : 'Editar Equipo',
        isSaving: _busy,
        errorMessage: _error,
        onSave: _save,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IosFormGroup(
              header: 'Datos de la Cuadrilla',
              children: [
                IosFormFieldRow(
                  label: 'Equipo',
                  placeholder: 'Ej. Cuadrilla Norte',
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                ),
                IosFormFieldRow(
                  label: 'Supervisor',
                  placeholder: 'Cédula del encargado',
                  controller: _supervisor,
                  keyboardType: TextInputType.number,
                ),
                IosFormFieldRow(
                  label: 'Suplente',
                  placeholder: 'Cédula adicional (opcional)',
                  controller: _alternate,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 12),
            IosFormGroup(
              header: 'Geocerca y Vigencia',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 104,
                        child: Text('Geocerca', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.cTextPrimary)),
                      ),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _zone,
                            isExpanded: true,
                            style: TextStyle(fontSize: 13, color: context.cTextPrimary),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Libre (sin restricción)')),
                              for (final z in widget.zones)
                                DropdownMenuItem<int?>(
                                  value: z['id'] as int,
                                  child: Text(
                                    (z['address'] as String?)?.isNotEmpty == true
                                        ? '${z['name']} (${z['address']})'
                                        : z['name'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: _busy ? null : (v) => setState(() => _zone = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _busy ? null : () => _pickDate(true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Válido desde', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.cTextPrimary)),
                        Text(_from ?? 'Seleccionar', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: _busy ? null : () => _pickDate(false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Válido hasta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.cTextPrimary)),
                        Text(_until ?? 'Seleccionar', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (widget.crew != null) ...[
              const SizedBox(height: 16),
              CupertinoButton(
                color: AppColors.systemRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.symmetric(vertical: 10),
                onPressed: _busy ? null : _delete,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.trash, size: 15, color: AppColors.systemRed),
                    SizedBox(width: 6),
                    Text('Eliminar Cuadrilla', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.systemRed)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
