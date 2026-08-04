// lib/core/notifications/journey_reminders.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/attendance/domain/entities/attendance_entity.dart';
import '../config/app_config.dart';
import '../localstore/secure_storage_provider.dart';
import '../utils/attendance_type.dart';

/// Preferencia de recordatorios de jornada — persistida por Configuración,
/// leída por el Home para decidir si muestra el badge/banner.
final notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  try {
    final saved = await storage.read(key: AppConfig.keyNotificationsEnabled);
    return saved == null ? true : saved == 'true';
  } catch (_) {
    return true; // sin preferencia → activos
  }
});

/// Nivel de urgencia de un recordatorio.
enum ReminderLevel { info, warning }

/// Recordatorio REAL calculado desde el estado de la jornada del día.
/// Sin sistema push: se computan localmente con los registros de la API y el
/// reloj del dispositivo — solo se muestran, jamás registran nada.
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

/// Horarios de referencia de la jornada (configurables por la empresa).
/// Solo informativos: el servidor decide el tipo de marca real (C2).
const _lunchStartHour = 12; // 12:00 → pendiente iniciar almuerzo
const _lunchEndHour = 13; // 13:00 → pendiente regreso de almuerzo
const _workEndHour = 18; // 18:00 → pendiente marcar salida
const _lateEntryHour = 9; // 09:00 → entrada aún sin marcar

/// Calcula los recordatorios pendientes para la jornada de hoy.
///
/// Reglas (espejo de la máquina de estado del servidor):
/// - Sin marca hoy y pasadas las 09:00            → entrada pendiente
/// - Última marca = entrada y pasadas las 12:00   → iniciar almuerzo
/// - Última marca = salida_almuerzo y pasadas las 13:00 → regreso de almuerzo
/// - Última marca = regreso_almuerzo y pasadas las 18:00 → salida
/// - Jornada completa (4 marcas)                  → sin recordatorios
List<JourneyReminder> computeJourneyReminders(
  List<AttendanceEntity> records, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  // toLocal(): la fecha del servidor es UTC; "hoy" se evalúa en hora local.
  final today = records.where((r) {
    final local = r.fecha.toLocal();
    return local.year == current.year &&
        local.month == current.month &&
        local.day == current.day;
  }).toList()
    // Orden cronológico para aislar la jornada ACTUAL.
    ..sort((a, b) => a.hora.compareTo(b.hora));

  // Última jornada del día (secuencia entrada→…→salida), SIN mezclar marcas
  // de jornadas distintas (el bug del map por tipo daba "completada" aunque
  // la jornada actual estuviera a medias).
  var inicio = 0;
  for (var i = 0; i < today.length; i++) {
    if (today[i].tipo == 'entrada') inicio = i;
  }
  final jornadaActual = today.sublist(inicio);

  final byType = attendanceTypes
      .map((t) => jornadaActual.where((r) => r.tipo == t).firstOrNull)
      .toList();
  final ultima = byType.lastWhere((m) => m != null, orElse: () => null);
  final jornadaCompleta = byType.every((m) => m != null);

  if (jornadaCompleta) return const [];

  final reminders = <JourneyReminder>[];

  if (ultima == null) {
    if (current.hour >= _lateEntryHour) {
      reminders.add(const JourneyReminder(
        titulo: 'Entrada pendiente',
        detalle: 'Aún no has marcado tu entrada hoy',
        icon: Icons.login,
        color: Color(0xFFF59E0B),
        level: ReminderLevel.warning,
      ));
    }
  } else {
    switch (ultima.tipo) {
      case 'entrada':
        if (current.hour >= _lunchStartHour) {
          reminders.add(const JourneyReminder(
            titulo: 'Iniciar almuerzo',
            detalle: 'Marcaste entrada, pero falta registrar el almuerzo',
            icon: Icons.restaurant,
            color: Color(0xFFF59E0B),
            level: ReminderLevel.info,
          ));
        }
      case 'salida_almuerzo':
        if (current.hour >= _lunchEndHour) {
          reminders.add(const JourneyReminder(
            titulo: 'Regreso de almuerzo',
            detalle: 'Tu pausa debería haber terminado',
            icon: Icons.restaurant,
            color: Color(0xFF3B82F6),
            level: ReminderLevel.info,
          ));
        }
      case 'regreso_almuerzo':
        if (current.hour >= _workEndHour) {
          reminders.add(const JourneyReminder(
            titulo: 'Salida pendiente',
            detalle: 'Tu jornada laboral debería haber terminado',
            icon: Icons.logout,
            color: Color(0xFFEF4444),
            level: ReminderLevel.warning,
          ));
        }
    }
  }

  return reminders;
}
