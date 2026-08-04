// lib/core/utils/time_format.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formatea la hora para la UI SIGUIENDO el reloj real del dispositivo:
/// 24h si el sistema lo usa (siempreUse24HourFormat) o 12h AM/PM (Colombia).
/// Único punto de implementación — las pantallas no hardcodean 'HH:mm'.
String formatTimeOfDay(BuildContext context, DateTime time) {
  final use24h = MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? true;
  // Locale heredado del MaterialApp (es): '9:39 p. m.' en 12h.
  return use24h
      ? DateFormat('HH:mm').format(time)
      : DateFormat('h:mm a').format(time);
}
