// ============================================================================
// ARCHIVO: confirmation_screen.dart
// QUÉ HACE: Pantalla oficial de comprobante tras registrar exitosamente una
//           marcación biométrica + GPS (`entrada`, `salida_almuerzo`,
//           `regreso_almuerzo`, `salida`).
// CÓMO FUNCIONA: Muestra animación elástica de verificación, resumen del
//                colaborador desde la sesión en memoria y hora exacta.
// POR QUÉ: Cumple SRP (< 180 líneas) y evita bloqueos de Keystore Android.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../shared/widgets/fade_slide_transition.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/primary_button.dart';

class ConfirmationScreen extends ConsumerStatefulWidget {
  const ConfirmationScreen({super.key, required this.tipo, this.fechaRegistro, this.horaRegistro});
  final String tipo;
  final String? fechaRegistro, horaRegistro;
  @override
  ConsumerState<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final DateTime _fechaHora = _resolveFechaHora();

  static const _configs = <String, (String, String, String, IconData, Color)>{
    'entrada': ('¡Entrada registrada!', 'Tu inicio de jornada fue verificado correctamente.', 'Entrada', Icons.login_rounded, AppColors.systemGreen),
    'salida_almuerzo': ('Inicio de almuerzo registrado', 'Tu pausa de almuerzo ha sido registrada.', 'Inicio de almuerzo', Icons.restaurant_rounded, AppColors.systemOrange),
    'regreso_almuerzo': ('Regreso de almuerzo registrado', 'Tu jornada laboral continúa activa.', 'Regreso de almuerzo', Icons.free_breakfast_rounded, AppColors.primary),
    'salida': ('¡Salida registrada!', 'Tu jornada laboral ha finalizado correctamente.', 'Salida', Icons.logout_rounded, AppColors.systemRed),
  };

  DateTime _resolveFechaHora() {
    final f = widget.fechaRegistro, h = widget.horaRegistro;
    if (f != null && f.isNotEmpty) {
      final parsed = DateTime.tryParse(f);
      if (parsed != null && h != null && h.isNotEmpty) {
        final p = h.split(':');
        return DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
          int.tryParse(p.elementAtOrNull(0) ?? '') ?? 0,
          int.tryParse(p.elementAtOrNull(1) ?? '') ?? 0,
          int.tryParse((p.elementAtOrNull(2) ?? '').split('.').first) ?? 0,
        );
      }
    }
    return DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..forward();
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _configs[widget.tipo] ?? _configs['entrada']!;
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppBar(
        backgroundColor: context.cSurface,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Comprobante de Marcación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          child: Column(children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: cfg.$5.withValues(alpha: 0.15), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: cfg.$5, shape: BoxShape.circle),
                  child: Icon(cfg.$4, size: 32, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(cfg.$1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(cfg.$2, textAlign: TextAlign.center, style: TextStyle(color: context.cGray, fontSize: 13.5)),
            const SizedBox(height: 24),
            FadeSlideTransition(
              delay: const Duration(milliseconds: 220),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _row(context, 'Hito', cfg.$3, color: cfg.$5),
                  const Divider(height: 20),
                  _row(context, 'Colaborador', user?.fullName ?? 'Colaborador'),
                  const Divider(height: 20),
                  _row(context, 'C.C.', user?.cedula ?? '---'),
                  const Divider(height: 20),
                  _row(context, 'Fecha y Hora', '${DateFormat('dd/MM/yyyy').format(_fechaHora)} · ${formatTimeOfDay(context, _fechaHora)}'),
                ]),
              ),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: PrimaryButton(label: 'Volver al Inicio', expanded: true, onPressed: () => context.go(AppRoutes.home)),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {Color? color}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: context.cGray)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color ?? context.cTextPrimary))),
        ],
      );
}
