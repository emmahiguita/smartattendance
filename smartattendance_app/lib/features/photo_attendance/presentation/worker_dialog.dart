// ============================================================================
// ARCHIVO: worker_dialog.dart
// QUÉ HACE: Ventana completa profesional sin cards para alta de personal o mandos:
//           - Restringe roles según jerarquía RBAC (Admin crea todos; Supervisor crea operarios).
//           - Asigna horario dual (12h/24h Colombia), tolerancia, cuadrilla y geocerca GPS.
// CÓMO FUNCIONA: Sincroniza ubicación y persiste en SQLite (`workers` y `usuarios_locales`).
// POR QUÉ: Sustituye modales pequeños por una pantalla ejecutiva iOS (< 165 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/location/traccar_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/roles.dart';
import '../domain/shift_template.dart';
import '../domain/work_schedule.dart';
import '../domain/worker_site.dart';
import 'crew_dialog.dart';
import 'local_providers.dart';
import 'worker_dialog_fields.dart';

part 'worker_dialog_actions.dart';

class WorkerDialog extends ConsumerStatefulWidget {
  const WorkerDialog({super.key});

  /// QUÉ HACE: Abre la ventana profesional completa de registro con transición iOS.
  /// CÓMO: Usa CupertinoPageRoute con fullscreenDialog y respuesta háptica.
  /// POR QUÉ: Otorga deslizamiento vertical fluido nativo de iOS.
  static Future<bool?> open(BuildContext context) {
    HapticFeedback.selectionClick();
    return Navigator.push<bool>(
      context,
      CupertinoPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => const WorkerDialog(),
      ),
    );
  }

  @override
  ConsumerState<WorkerDialog> createState() => _WorkerDialogState();
}

class _WorkerDialogState extends _WorkerDialogActions {
  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(localActorProvider);
    final isDark = context.isDark;
    final title = actor.isStrictAdmin
        ? 'Registrar Personal / Mando'
        : 'Registrar Operario';

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : context.cBackground,
        appBar: AppBar(
          toolbarHeight: 50,
          backgroundColor: isDark ? Colors.black : context.cBackground,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Container(height: 0.5, color: context.cBorder),
          ),
          leading: IconButton(
            icon: Icon(CupertinoIcons.xmark,
                size: 19, color: context.cTextPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary)),
            Text('Serviciudad E.S.P. · Gestión Operativa',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.cTextSecondary)),
          ]),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CupertinoActivityIndicator(radius: 9)
                    : Text('Guardar',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.cTextPrimary)),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.systemRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.systemRed.withValues(alpha: 0.35),
                            width: 0.5),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.systemRed)),
                    ),
                  WorkerDialogFields(
                    nameCtrl: _name,
                    docCtrl: _document,
                    jobCtrl: _job,
                    addressCtrl: _address,
                    passwordCtrl: _password,
                    confirmPasswordCtrl: _confirmation,
                    selectedTemplate: _selectedTemplate,
                    toleranceMode: _toleranceMode,
                    crewName: _crewName,
                    gpsLat: _gpsLat,
                    gpsLng: _gpsLng,
                    isStrictAdmin: actor.isStrictAdmin,
                    onPickRole: _pickRole,
                    onPickSchedule: _pickSchedule,
                    onPickTolerance: _pickTolerance,
                    onPickCrew: _pickCrew,
                    onLocationChanged: (pt, addr) => setState(() {
                      _gpsLat = pt.latitude;
                      _gpsLng = pt.longitude;
                      _address.text = addr;
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF1C1C1E)
                            : const Color(0xFF0F172A),
                        elevation: 0,
                        side: BorderSide(color: context.cBorder, width: 0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const CupertinoActivityIndicator(
                              color: Colors.white)
                          : Text(
                              actor.isStrictAdmin
                                  ? 'Guardar Colaborador / Mando'
                                  : 'Afiliar Operario al Equipo',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
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
