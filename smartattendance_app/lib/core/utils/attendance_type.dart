// lib/core/utils/attendance_type.dart
import 'package:flutter/material.dart';

/// Información visual semántica por tipo de marca de jornada.
/// Colores del plano: 🟢 entrada · 🟠 almuerzo · 🔵 regreso · 🔴 salida.
/// Iconos DISTINTIVOS por marca: entrada/login, almuerzo/comida,
/// regreso/trabajo, salida/logout — cada uno cuenta su etapa.
/// Fuente única de verdad para confirmación, resumen, historial y admin.
({String label, Color color, IconData icon}) attendanceTypeInfo(String tipo) {
  switch (tipo.toLowerCase()) {
    case 'salida_almuerzo':
      return (
        label: 'Inicio de almuerzo',
        color: const Color(0xFFF59E0B), // Naranja
        icon: Icons.restaurant,
      );
    case 'regreso_almuerzo':
      return (
        label: 'Regreso de almuerzo',
        color: const Color(0xFF3B82F6), // Azul
        // Maletín: vuelta al trabajo tras la pausa (antes usaba el mismo
        // "restaurant" que la salida a almorzar — no se distinguían).
        icon: Icons.work,
      );
    case 'salida':
      return (
        label: 'Salida',
        color: const Color(0xFFEF4444), // Rojo
        icon: Icons.logout,
      );
    case 'hora_extra_entrada':
      return (
        label: 'Entrada Hora Extra',
        color: const Color(0xFFD97706), // Ámbar / Dorado corporativo
        icon: Icons.more_time_rounded,
      );
    case 'hora_extra_salida':
      return (
        label: 'Salida Hora Extra',
        color: const Color(0xFF8B5CF6), // Violeta
        icon: Icons.timer_off_rounded,
      );
    case 'entrada':
    default:
      return (
        label: 'Entrada',
        color: const Color(0xFF22C55E), // Verde
        icon: Icons.login,
      );
  }
}

/// Etiqueta corta para badges compactos (tablas/filtros).
String attendanceTypeShort(String tipo) {
  switch (tipo.toLowerCase()) {
    case 'salida_almuerzo':
      return 'Almuerzo';
    case 'regreso_almuerzo':
      return 'Regreso';
    case 'salida':
      return 'Salida';
    case 'hora_extra_entrada':
      return 'Extra In';
    case 'hora_extra_salida':
      return 'Extra Out';
    default:
      return 'Entrada';
  }
}

/// MARCAS QUE EL TRABAJADOR PUEDE REGISTRAR (solo las 4 de la jornada).
/// Las horas extras NO son una marcación: las define el administrador con
/// sus reglas (jornada pactada en WorkSchedule). Por eso no están aquí.
const List<String> attendanceTypes = [
  'entrada',
  'salida_almuerzo',
  'regreso_almuerzo',
  'salida',
];

/// Tipos que pueden EXISTIR en el historial (solo lectura). Incluye los
/// 'hora_extra_*' guardados por versiones anteriores para que los reportes
/// viejos se sigan mostrando sin romperse. Nunca se usan para marcar.
const List<String> knownAttendanceTypes = [
  ...attendanceTypes,
  'hora_extra_entrada',
  'hora_extra_salida',
];
