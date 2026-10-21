import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';

/// ============================================================================
/// COMPONENTE: LiveClockWidget
/// ============================================================================
/// QUÉ HACE:
/// Muestra un reloj en tiempo real sincronizado con el reloj del sistema operativo.
///
/// PARA QUÉ SIRVE:
/// Proporciona certeza visual al empleado de la hora exacta con la cual se generará
/// su registro de asistencia en el dispositivo.
///
/// GESTIÓN DEL CICLO DE VIDA (PREVENCIÓN DE PROCESOS ZOMBIE):
/// Un temporizador [Timer.periodic] que no se cancela crea una fuga de memoria
/// (memory leak) y continúa despertando el hilo de Flutter indefinidamente.
/// Aquí garantizamos la cancelación estricta en el método [dispose].
/// ============================================================================
class LiveClockWidget extends StatefulWidget {
  const LiveClockWidget({super.key});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget>
    with WidgetsBindingObserver {
  /// Un solo temporizador para el siguiente cambio de minuto; se pausa al salir.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Inicia el temporizador al crearse el widget en el árbol.
    WidgetsBinding.instance.addObserver(this);
    _scheduleMinute();
  }

  /// El diseño muestra minutos: no necesita reconstruirse cada segundo.
  void _scheduleMinute() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 60 - DateTime.now().second), () {
      if (!mounted) return;
      setState(() {});
      _scheduleMinute();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _scheduleMinute();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    // PREVENCIÓN DE PROCESO ZOMBIE: cancela el Timer al salir de la pantalla.
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time_rounded, size: 16, color: context.cGray),
        const SizedBox(width: 6),
        Text(
          // Formatea la hora respetando la configuración 12h/24h del sistema
          formatTimeOfDay(context, now),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.cTextPrimary,
            // Números monoespaciados para evitar saltos de ancho al cambiar los segundos
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
