import 'package:flutter/material.dart';
import '../../../photo_attendance/presentation/local_attendance_home.dart';

/// Compatibilidad de la ruta antigua. El alcance actual es evidencia con foto,
/// no biometría: primero se selecciona al trabajador en el módulo local real.
class FacialRecognitionScreen extends StatelessWidget {
  const FacialRecognitionScreen({super.key, this.tipo});
  final String? tipo;

  @override
  Widget build(BuildContext context) => const LocalAttendanceHome();
}
