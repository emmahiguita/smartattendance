// lib/features/attendance/presentation/widgets/worker_hr_management_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/journey_report.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/photo_capture_screen.dart';
import '../../../photo_attendance/presentation/photo_history_screen.dart';
import '../../../photo_attendance/presentation/worker_assignment_dialog.dart';
import 'staff_status_types.dart';

/// ============================================================================
/// COMPONENTE: WorkerHrManagementSheet (Ficha Ejecutiva de Talento Humano)
/// ============================================================================
/// QUÉ HACE:
/// Panel de gestión de Talento Humano para un colaborador específico:
/// 1. Consulta y edición de la jornada pactada asignada por el administrador.
/// 2. Control, auditoría y aprobación/rechazo de horas extras (tiempo adicional).
/// 3. Acceso directo a marcación biométrica facial.
/// 4. Consulta del historial de jornadas y firmas de revisión.
///
/// CÓMO FUNCIONA:
/// Lee en tiempo real desde SQLite la configuración del trabajador y su última
/// jornada. Permite delegar cambios a [WorkerAssignmentDialog] e invocar revisiones
/// auditadas en [LocalAdminStore] respetando Clean Architecture y modo offline.
/// ============================================================================
class WorkerHrManagementSheet extends ConsumerStatefulWidget {
  const WorkerHrManagementSheet({super.key, required this.worker});

  final LocalWorker worker;

  static Future<void> show(BuildContext context, {required LocalWorker worker}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkerHrManagementSheet(worker: worker),
    );
  }

  @override
  ConsumerState<WorkerHrManagementSheet> createState() => _WorkerHrManagementSheetState();
}

class _WorkerHrManagementSheetState extends ConsumerState<WorkerHrManagementSheet> {
  late LocalWorker _worker;
  PhotoDay? _latestDay;
  bool _loadingDay = true;
  bool _reviewing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _worker = widget.worker;
    _loadLatestDay();
  }

  Future<void> _loadLatestDay() async {
    setState(() => _loadingDay = true);
    try {
      final days = await ref.read(localPhotoRepositoryProvider).days(
            search: _worker.document,
            limit: 1,
          );
      if (mounted) {
        setState(() {
          _latestDay = days.isNotEmpty ? days.first : null;
          _loadingDay = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDay = false);
    }
  }

  Future<void> _openScheduleDialog() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => WorkerAssignmentDialog(worker: _worker),
    );
    if (updated == true && mounted) {
      ref.invalidate(localWorkersProvider);
      // Recargar trabajador actualizado
      final list = await ref.read(localPhotoRepositoryProvider).workers();
      final fresh = list.firstWhere(
        (w) => w.id == _worker.id,
        orElse: () => _worker,
      );
      if (mounted) {
        setState(() => _worker = fresh);
        _loadLatestDay();
      }
    }
  }

  Future<void> _reviewOvertime({required bool approve}) async {
    final day = _latestDay;
    if (day == null || _reviewing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Aprobar Horas Extras' : 'Rechazar Horas Extras'),
        content: Text(
          approve
              ? '¿Deseas autorizar el tiempo adicional calculado para esta jornada? La aprobación quedará firmada por el administrador.'
              : '¿Deseas registrar que el tiempo adicional no fue autorizado para esta jornada?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _reviewing = true);
    try {
      final store = ref.read(localAdminStoreProvider);
      await store.review(day, approve: approve, abandon: false);
      if (mounted) {
        setState(() {
          _message = approve ? 'Horas extras aprobadas exitosamente' : 'Tiempo adicional no autorizado';
        });
        await _loadLatestDay();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = e is FormatException ? e.message : 'No se pudo registrar la revisión';
        });
      }
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  Future<void> _applyScheduleToDay() async {
    final day = _latestDay;
    if (day == null || _reviewing) return;
    setState(() => _reviewing = true);
    try {
      await ref.read(localAdminStoreProvider).applySchedule(day);
      if (mounted) {
        setState(() => _message = 'Jornada pactada aplicada a este registro');
        await _loadLatestDay();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = e is FormatException ? e.message : 'Error al aplicar jornada');
      }
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = ColombiaClock.day(DateTime.now());
    final status = calculateStaffStatus(_worker, today);
    final initial = _worker.name.trim().isEmpty ? '?' : _worker.name.trim()[0].toUpperCase();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior de agarre
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Cabecera del colaborador
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _worker.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.cTextPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_worker.job.isEmpty ? 'Colaborador' : _worker.job} · C.C. ${_worker.document}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (_message != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _message!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ══════════════════════════════════════════════════════════════════
              //  SECCIÓN 1: JORNADA Y HORARIO ASIGNADO (TALENTO HUMANO)
              // ══════════════════════════════════════════════════════════════════
              _buildSectionCard(
                context,
                title: 'Jornada Asignada por Administrador',
                icon: Icons.access_time_filled_rounded,
                isDark: isDark,
                trailing: TextButton.icon(
                  onPressed: _openScheduleDialog,
                  icon: const Icon(Icons.edit_calendar_rounded, size: 15),
                  label: const Text('Modificar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
                children: [
                  if (_worker.schedule != null) ...[
                    _buildInfoRow(
                      context,
                      label: 'Jornada ordinaria pactada',
                      value: '${(_worker.schedule!.dailyMinutes / 60).toStringAsFixed(1)} horas diarias',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      context,
                      label: 'Descuento de almuerzo',
                      value: _worker.schedule!.deductLunch ? 'Descuenta 1h automática' : 'No descuenta almuerzo',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      context,
                      label: 'Franja nocturna legal',
                      value:
                          '${_worker.schedule!.nightStartMinute ~/ 60}:${(_worker.schedule!.nightStartMinute % 60).toString().padLeft(2, '0')} a ${_worker.schedule!.nightEndMinute ~/ 60}:${(_worker.schedule!.nightEndMinute % 60).toString().padLeft(2, '0')}',
                      isDark: isDark,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.systemOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sin jornada fija asignada. El cálculo de horas extras requiere vincular un horario.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ══════════════════════════════════════════════════════════════════
              //  SECCIÓN 2: CONTROL Y APROBACIÓN DE HORAS EXTRAS
              // ══════════════════════════════════════════════════════════════════
              _buildSectionCard(
                context,
                title: 'Control de Horas Extras y Liquidación',
                icon: Icons.verified_user_rounded,
                isDark: isDark,
                children: [
                  if (_loadingDay)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (_latestDay == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No hay registros de jornada reciente para este colaborador.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                        ),
                      ),
                    )
                  else ...[
                    _buildLatestDayOvertimeContent(context, _latestDay!, isDark),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // ══════════════════════════════════════════════════════════════════
              //  BOTONES DE ACCIÓN EMPRESARIAL
              // ══════════════════════════════════════════════════════════════════
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PhotoCaptureScreen(worker: _worker, initialType: 'entrada'),
                    ),
                  );
                },
                icon: const Icon(Icons.face_retouching_natural_rounded, size: 18),
                label: const Text('Registrar Asistencia Facial', style: TextStyle(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PhotoHistoryScreen()),
                  );
                },
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('Ver Historial Completo de Jornadas', style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.cTextPrimary,
                  minimumSize: const Size.fromHeight(44),
                  side: BorderSide(color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestDayOvertimeContent(BuildContext context, PhotoDay day, bool isDark) {
    final values = JourneyReport.labels(day);
    final worked = values['Tiempo trabajado'] ?? '0h';
    final additional = values['Adicional por revisar'] ?? '0h';
    final approved = values['Adicional aprobado'] ?? '0h';
    final hasOvertime = additional.isNotEmpty && additional != '0h 0m' && additional != '0m';
    final isApproved = day.approvedSeconds != null && day.approvedSeconds! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fecha de jornada: ${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: (isApproved ? AppColors.systemGreen : (hasOvertime ? AppColors.systemOrange : AppColors.primary))
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isApproved ? 'Extras aprobadas' : (hasOvertime ? 'Adicional por aprobar' : 'Ordinaria regular'),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isApproved ? AppColors.systemGreen : (hasOvertime ? AppColors.systemOrange : AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildInfoRow(context, label: 'Tiempo laborado total', value: worked, isDark: isDark),
        const SizedBox(height: 6),
        _buildInfoRow(context, label: 'Tiempo adicional (Horas extras)', value: additional, isDark: isDark),
        if (isApproved) ...[
          const SizedBox(height: 6),
          _buildInfoRow(
            context,
            label: 'Adicional aprobado por Talento Humano',
            value: '$approved (Firma: ${day.reviewedBy ?? 'Administrador'})',
            isDark: isDark,
          ),
        ],
        const SizedBox(height: 12),

        // Acciones de aprobación para el Administrador de Talento Humano
        if (day.schedule == null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _reviewing ? null : _applyScheduleToDay,
              icon: const Icon(Icons.link_rounded, size: 16),
              label: const Text('Aplicar Jornada Pactada a este registro', style: TextStyle(fontSize: 12.5)),
            ),
          ),
        ] else if (hasOvertime && !isApproved) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _reviewing ? null : () => _reviewOvertime(approve: true),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Aprobar Horas Extras', style: TextStyle(fontSize: 12.5)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.systemGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _reviewing ? null : () => _reviewOvertime(approve: false),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('No Aprobar', style: TextStyle(fontSize: 12.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.systemRed,
                  side: BorderSide(color: AppColors.systemRed.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: context.cTextPrimary,
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            thickness: 0.5,
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: context.cTextPrimary,
          ),
        ),
      ],
    );
  }
}
