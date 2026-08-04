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
    default:
      return 'Entrada';
  }
}

/// Lista canónica de tipos de jornada (orden de la máquina de estado).
const List<String> attendanceTypes = [
  'entrada',
  'salida_almuerzo',
  'regreso_almuerzo',
  'salida',
];
