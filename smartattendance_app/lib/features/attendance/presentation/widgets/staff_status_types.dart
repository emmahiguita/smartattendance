// lib/features/attendance/presentation/widgets/staff_status_types.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../photo_attendance/domain/photo_record.dart';

/// ============================================================================
/// MODELO Y UTILIDADES: Estados de Asistencia del Personal
/// ============================================================================
/// QUÉ HACE:
/// Clasifica el estado operativo de cada trabajador (En jornada, Almuerzo,
/// Cerrada, Sin entrada o Incompleta) para filtros y presentación visual.
///
/// CÓMO FUNCIONA:
/// Compara la fecha de la última marca con la fecha actual de Colombia y analiza
/// la secuencia de marcas para determinar el estado en tiempo real.
///
/// POR QUÉ:
/// Principio de Responsabilidad Única (SRP): desacopla la lógica de negocio
/// del personal de los widgets de interfaz gráfica.
/// ============================================================================

enum StaffStatusCategory {
  enJornada,
  sinEntrada,
  jornadaCerrada,
  incompleta,
}

class StaffAttendanceStatus {
  const StaffAttendanceStatus({
    required this.label,
    required this.color,
    required this.category,
  });

  final String label;
  final Color color;
  final StaffStatusCategory category;

  bool get active => category == StaffStatusCategory.enJornada;
}

/// Calcula el estado actual del colaborador según su última marca registrada
StaffAttendanceStatus calculateStaffStatus(LocalWorker worker, String today) {
  if (worker.lastWorkDate != today) {
    return worker.lastJourneyStatus == 'open'
        ? const StaffAttendanceStatus(
            label: 'Jornada incompleta',
            color: AppColors.systemOrange,
            category: StaffStatusCategory.incompleta,
          )
        : const StaffAttendanceStatus(
            label: 'Sin entrada',
            color: Color(0xFF8E8E93),
            category: StaffStatusCategory.sinEntrada,
          );
  }

  return switch (worker.lastMark) {
    'entrada' || 'regreso_almuerzo' || 'hora_extra_entrada' =>
      const StaffAttendanceStatus(
        label: 'En jornada',
        color: AppColors.systemGreen,
        category: StaffStatusCategory.enJornada,
      ),
    'salida_almuerzo' => const StaffAttendanceStatus(
        label: 'En almuerzo',
        color: AppColors.systemOrange,
        category: StaffStatusCategory.enJornada,
      ),
    'salida' || 'hora_extra_salida' => const StaffAttendanceStatus(
        label: 'Jornada cerrada',
        color: AppColors.accentIndigo,
        category: StaffStatusCategory.jornadaCerrada,
      ),
    _ => const StaffAttendanceStatus(
        label: 'Sin entrada',
        color: Color(0xFF8E8E93),
        category: StaffStatusCategory.sinEntrada,
      ),
  };
}
