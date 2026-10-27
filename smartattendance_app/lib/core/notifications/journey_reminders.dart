// ============================================================================
// ARCHIVO: journey_reminders.dart
// QUÉ HACE: Procesa las marcaciones reales del día desde SQLite y genera:
//           1. Notificaciones de eventos confirmados (`ConfirmedJourneyNotification`)
//           2. Recordatorios de próximos pasos (`JourneyReminder`).
// CÓMO FUNCIONA: Compara la hora local con las marcas existentes. Si la entrada
//                ya fue realizada hoy, NUNCA emite "Entrada pendiente".
// POR QUÉ: Garantiza coherencia absoluta entre Inicio y Notificaciones (< 195 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/attendance/domain/entities/attendance_entity.dart';
import '../config/app_config.dart';
import '../localstore/secure_storage_provider.dart';
import '../utils/attendance_type.dart';

final notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  try {
    final saved = await storage.read(key: AppConfig.keyNotificationsEnabled);
    return saved == null ? true : saved == 'true';
  } catch (_) {
    return true;
  }
});

enum ReminderLevel { info, warning, success }

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

const _lunchStartHour = 12;
const _lunchEndHour = 13;
const _workEndHour = 18;
const _lateEntryHour = 9;

List<AttendanceEntity> _todayRecords(List<AttendanceEntity> records, DateTime now) {
  return records.where((r) {
    final local = r.fecha.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }).toList()
    ..sort((a, b) => a.hora.compareTo(b.hora));
}

List<ConfirmedJourneyNotification> computeConfirmedNotifications(
  List<AttendanceEntity> records, {
  DateTime? now,
}) {
  final today = _todayRecords(records, now ?? DateTime.now());
  final timeFormat = DateFormat('hh:mm a');
  return [
    for (final r in today)
      () {
        final tipoKey = r.tipo.toLowerCase();
        final horaStr = timeFormat.format(r.hora.toLocal());
        final info = attendanceTypeInfo(tipoKey);
        final desc = switch (tipoKey) {
          'entrada' =>
            'Registrada a las $horaStr · Reconocimiento facial y GPS verificado',
          'salida_almuerzo' => 'Registrada a las $horaStr · En receso de almuerzo',
          'regreso_almuerzo' =>
            'Registrada a las $horaStr · Jornada laboral reanudada',
          'salida' => 'Registrada a las $horaStr · Jornada concluida con éxito',
          _ => 'Marcación de ${info.label} a las $horaStr',
        };
        return ConfirmedJourneyNotification(
          tipo: tipoKey,
          titulo: '${info.label} confirmada',
          detalle: desc,
          hora: horaStr,
          icon: info.icon,
          color: info.color,
        );
      }(),
  ];
}

List<JourneyReminder> computeJourneyReminders(
  List<AttendanceEntity> records, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final today = _todayRecords(records, current);
  final hasEntrada = today.any((r) => r.tipo.toLowerCase() == 'entrada');

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

  var inicio = 0;
  for (var i = 0; i < today.length; i++) {
    if (today[i].tipo.toLowerCase() == 'entrada') inicio = i;
  }
  final jornadaActual = today.sublist(inicio);
  final byType = attendanceTypes
      .map((t) =>
          jornadaActual.where((r) => r.tipo.toLowerCase() == t).firstOrNull)
      .toList();
  final ultima = byType.lastWhere((m) => m != null, orElse: () => null);
  if (byType.every((m) => m != null) || ultima == null) return const [];

  return switch (ultima.tipo.toLowerCase()) {
    'entrada' when current.hour >= _lunchStartHour && current.hour < _lunchEndHour + 2 =>
      const [
        JourneyReminder(
          titulo: 'Iniciar almuerzo',
          detalle: 'Recuerda registrar el inicio de tu pausa de almuerzo',
          icon: Icons.restaurant_rounded,
          color: Color(0xFFF59E0B),
          level: ReminderLevel.info,
        ),
      ],
    'salida_almuerzo' when current.hour >= _lunchEndHour => const [
        JourneyReminder(
          titulo: 'Regreso de almuerzo',
          detalle: 'Tu receso de almuerzo debería haber finalizado',
          icon: Icons.work_rounded,
          color: Color(0xFF3B82F6),
          level: ReminderLevel.info,
        ),
      ],
    'regreso_almuerzo' when current.hour >= _workEndHour => const [
        JourneyReminder(
          titulo: 'Salida pendiente',
          detalle: 'Recuerda registrar la salida al finalizar tu turno',
          icon: Icons.logout_rounded,
          color: Color(0xFFEF4444),
          level: ReminderLevel.warning,
        ),
      ],
    _ => const [],
  };
}
