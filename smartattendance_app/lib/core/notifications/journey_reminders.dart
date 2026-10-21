// lib/core/notifications/journey_reminders.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/attendance/domain/entities/attendance_entity.dart';
import '../config/app_config.dart';
import '../localstore/secure_storage_provider.dart';
import '../utils/attendance_type.dart';

/// ============================================================================
/// SERVICIO: JourneyReminders & ConfirmedNotifications (SOLID - Single Responsibility)
/// ============================================================================
/// QUÉ HACE:
/// Procesa las marcaciones de la jornada de hoy desde SQLite local y genera:
/// 1. Notificaciones de eventos confirmados (Entrada registrada a las HH:mm, etc.)
/// 2. Recordatorios de próximos pasos (Almuerzo, Regreso, Salida).
///
/// CÓMO FUNCIONA:
/// Compara la hora local del dispositivo con las marcas existentes en la BD.
/// Si la entrada ya fue realizada, NUNCA emite "Entrada pendiente" (evita inconsistencias).
///
/// POR QUÉ:
/// Garantiza coherencia absoluta entre el Dashboard y el modal de Notificaciones (< 200 líneas).
/// ============================================================================

/// Preferencia de recordatorios de jornada — persistida en storage seguro.
final notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  try {
    final saved = await storage.read(key: AppConfig.keyNotificationsEnabled);
    return saved == null ? true : saved == 'true';
  } catch (_) {
    return true; // sin preferencia → activos por defecto
  }
});

/// Nivel de urgencia o estado de una notificación.
enum ReminderLevel { info, warning, success }

/// Evento de asistencia confirmado registrado hoy en el dispositivo.
final class ConfirmedJourneyNotification {
  const ConfirmedJourneyNotification({
    required this.tipo,
    required this.titulo,
    required this.detalle,
    required this.hora,
    required this.icon,
    required this.color,
  });

  final String tipo;
  final String titulo;
  final String detalle;
  final String hora;
  final IconData icon;
  final Color color;
}

/// Recordatorio de jornada pendiente o próximo paso requerido.
final class JourneyReminder {
  const JourneyReminder({
    required this.titulo,
    required this.detalle,
    required this.icon,
    required this.color,
    required this.level,
  });

  final String titulo;
  final String detalle;
  final IconData icon;
  final Color color;
  final ReminderLevel level;
}

/// Horarios de referencia para la jornada diurna estándar.
const _lunchStartHour = 12; // 12:00 → inicio sugerido de almuerzo
const _lunchEndHour = 13;   // 13:00 → regreso de almuerzo
const _workEndHour = 18;    // 18:00 → fin de jornada estándar
const _lateEntryHour = 9;   // 09:00 → entrada pendiente si no ha marcado

/// Extrae las notificaciones de eventos CONFIRMADOS de hoy (Entrada, Almuerzo, etc.)
List<ConfirmedJourneyNotification> computeConfirmedNotifications(
  List<AttendanceEntity> records, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final today = records.where((r) {
    final local = r.fecha.toLocal();
    return local.year == current.year &&
        local.month == current.month &&
        local.day == current.day;
  }).toList()
    ..sort((a, b) => a.hora.compareTo(b.hora));

  final timeFormat = DateFormat('hh:mm a');
  final list = <ConfirmedJourneyNotification>[];

  for (final r in today) {
    final tipoKey = r.tipo.toLowerCase();
    final horaStr = timeFormat.format(r.hora.toLocal());
    final info = attendanceTypeInfo(tipoKey);

    final String desc = switch (tipoKey) {
      'entrada' => 'Registrada a las $horaStr · Reconocimiento facial y GPS verificado',
      'salida_almuerzo' => 'Registrada a las $horaStr · En receso de almuerzo',
      'regreso_almuerzo' => 'Registrada a las $horaStr · Jornada laboral reanudada',
      'salida' => 'Registrada a las $horaStr · Jornada concluida con éxito',
      _ => 'Marcación de ${info.label} a las $horaStr',
    };

    list.add(ConfirmedJourneyNotification(
      tipo: tipoKey,
      titulo: '${info.label} confirmada',
      detalle: desc,
      hora: horaStr,
      icon: info.icon,
      color: info.color,
    ));
  }

  return list;
}

/// Calcula los recordatorios pendientes para la jornada de hoy.
/// Si YA se registró entrada hoy → NUNCA muestra "Entrada pendiente".
List<JourneyReminder> computeJourneyReminders(
  List<AttendanceEntity> records, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final today = records.where((r) {
    final local = r.fecha.toLocal();
    return local.year == current.year &&
        local.month == current.month &&
        local.day == current.day;
  }).toList()
    ..sort((a, b) => a.hora.compareTo(b.hora));

  final hasEntrada = today.any((r) => r.tipo.toLowerCase() == 'entrada');

  // Si no hay entrada registrada hoy y es horario hábil matutino (>= 09:00 AM)
  if (!hasEntrada) {
    if (current.hour >= _lateEntryHour && current.hour < _workEndHour) {
      return const [
        JourneyReminder(
          titulo: 'Entrada pendiente',
          detalle: 'Aún no has registrado tu entrada para la jornada de hoy',
          icon: Icons.login_rounded,
          color: Color(0xFFF59E0B),
          level: ReminderLevel.warning,
        ),
      ];
    }
    return const [];
  }

  // Con entrada confirmada, evaluamos exclusivamente los pasos subsiguientes
  var inicio = 0;
  for (var i = 0; i < today.length; i++) {
    if (today[i].tipo.toLowerCase() == 'entrada') inicio = i;
  }
  final jornadaActual = today.sublist(inicio);

  final byType = attendanceTypes
      .map((t) => jornadaActual.where((r) => r.tipo.toLowerCase() == t).firstOrNull)
      .toList();
  final ultima = byType.lastWhere((m) => m != null, orElse: () => null);
  final jornadaCompleta = byType.every((m) => m != null);

  if (jornadaCompleta || ultima == null) return const [];

  final reminders = <JourneyReminder>[];
  switch (ultima.tipo.toLowerCase()) {
    case 'entrada':
      if (current.hour >= _lunchStartHour && current.hour < _lunchEndHour + 2) {
        reminders.add(const JourneyReminder(
          titulo: 'Iniciar almuerzo',
          detalle: 'Recuerda registrar el inicio de tu pausa de almuerzo',
          icon: Icons.restaurant_rounded,
          color: Color(0xFFF59E0B),
          level: ReminderLevel.info,
        ));
      }
    case 'salida_almuerzo':
      if (current.hour >= _lunchEndHour) {
        reminders.add(const JourneyReminder(
          titulo: 'Regreso de almuerzo',
          detalle: 'Tu receso de almuerzo debería haber finalizado',
          icon: Icons.work_rounded,
          color: Color(0xFF3B82F6),
          level: ReminderLevel.info,
        ));
      }
    case 'regreso_almuerzo':
      if (current.hour >= _workEndHour) {
        reminders.add(const JourneyReminder(
          titulo: 'Salida pendiente',
          detalle: 'Recuerda registrar la salida al finalizar tu turno',
          icon: Icons.logout_rounded,
          color: Color(0xFFEF4444),
          level: ReminderLevel.warning,
        ));
      }
  }

  return reminders;
}
