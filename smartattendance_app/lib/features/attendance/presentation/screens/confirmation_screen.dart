import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/fade_slide_transition.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Confirmation screen — shown after successful attendance registration.
///
/// All employee data comes from the session (Riverpod state), NOT from
/// secure_storage — avoids Android Keystore hangs on devices without
/// screen lock.
class ConfirmationScreen extends ConsumerStatefulWidget {
  const ConfirmationScreen({
    super.key,
    required this.tipo,
    this.fechaRegistro,
    this.horaRegistro,
  });

  final String tipo;
  final String? fechaRegistro;
  final String? horaRegistro;

  @override
  ConsumerState<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  // Fecha/hora mostradas: servidor primero, reloj local como fallback.
  late final DateTime _fechaHora = _resolveFechaHora();

  static const Map<String, _ConfirmConfig> _configs = {
    'entrada': _ConfirmConfig(
      title: '¡Entrada registrada!',
      subtitle: 'Tu registro ha sido procesado correctamente.',
      tipoLabel: 'Entrada',
      iconData: Icons.login,
      iconBg: AppColors.systemGreen,
      iconColor: Colors.white,
      badgeColor: AppColors.systemGreen,
    ),
    'salida_almuerzo': _ConfirmConfig(
      title: 'Inicio de almuerzo registrado',
      subtitle: 'Tu pausa ha sido procesada correctamente.',
      tipoLabel: 'Inicio de almuerzo',
      iconData: Icons.restaurant,
      iconBg: AppColors.systemOrange,
      iconColor: Colors.white,
      badgeColor: AppColors.systemOrange,
    ),
    'regreso_almuerzo': _ConfirmConfig(
      title: 'Regreso de almuerzo registrado',
      subtitle: 'Tu jornada continúa.',
      tipoLabel: 'Regreso de almuerzo',
      iconData: Icons.restaurant,
      iconBg: AppColors.primary,
      iconColor: Colors.white,
      badgeColor: AppColors.primary,
    ),
    'salida': _ConfirmConfig(
      title: '¡Salida registrada!',
      subtitle: 'Tu jornada ha finalizado correctamente.',
      tipoLabel: 'Salida',
      iconData: Icons.logout,
      iconBg: AppColors.systemRed,
      iconColor: Colors.white,
      badgeColor: AppColors.systemRed,
    ),
  };

  DateTime _resolveFechaHora() {
    final fechaStr = widget.fechaRegistro;
    final horaStr = widget.horaRegistro;
    if (fechaStr != null && fechaStr.isNotEmpty) {
      final fecha = DateTime.tryParse(fechaStr);
      if (fecha != null) {
        final now = DateTime.now();
        if (horaStr != null && horaStr.isNotEmpty) {
          final parts = horaStr.split(':');
          final h =
              parts.isNotEmpty ? int.tryParse(parts[0]) ?? now.hour : now.hour;
          final m = parts.length > 1
              ? int.tryParse(parts[1]) ?? now.minute
              : now.minute;
          final secStr = parts.length > 2 ? parts[2].split('.').first : '';
          final s = secStr.isNotEmpty
              ? (int.tryParse(secStr) ?? now.second)
              : now.second;
          return DateTime(fecha.year, fecha.month, fecha.day, h, m, s);
        }
        return fecha;
      }
    }
    return DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _configs[widget.tipo] ?? _configs['entrada']!;
    final now = _fechaHora;

    // Employee data from session (zero secure_storage dependency)
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;
    final empleadoNombre = user?.fullName ?? 'Empleado';
    final empleadoCedula = user?.cedula ?? '---';
    final empleadoCargo = user?.cargo ?? '---';

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: _buildCupertinoNavBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
                child: Column(
                  children: [
                    // Animated icon
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: cfg.iconBg.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: cfg.iconBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: cfg.iconBg.withValues(alpha: .3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Icon(cfg.iconData,
                              size: 36, color: cfg.iconColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      cfg.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cfg.subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: context.cGray),
                    ),
                    const SizedBox(height: 32),

                    // Detail card (iOS Grouped List style)
                    FadeSlideTransition(
                      delay: const Duration(milliseconds: 300),
                      child: GlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(children: [
                          _DetailRow(
                              label: 'Tipo',
                              value: cfg.tipoLabel,
                              valueColor: cfg.badgeColor),
                          _DetailRow(label: 'Empleado', value: empleadoNombre),
                          _DetailRow(label: 'C.C.', value: empleadoCedula),
                          _DetailRow(label: 'Cargo', value: empleadoCargo),
                          _DetailRow(
                              label: 'Fecha',
                              value: DateFormat('dd/MM/yyyy').format(now)),
                          _DetailRow(
                              label: 'Hora',
                              value: formatTimeOfDay(context, now),
                              isLast: true),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: PrimaryButton(
            label: 'Continuar',
            expanded: true,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildCupertinoNavBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.cSurface,
      elevation: 0,
      centerTitle: true,
      title: Text('Confirmación',
          style: TextStyle(
              color: context.cTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: -0.41)),
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          color: context.cGray4.withValues(alpha: 0.5),
          height: 0.5,
        ),
      ),
    );
  }
}

// ── Config value object ───────────────────────────────────────────────────────
class _ConfirmConfig {
  const _ConfirmConfig({
    required this.title,
    required this.subtitle,
    required this.tipoLabel,
    required this.iconData,
    required this.iconBg,
    required this.iconColor,
    required this.badgeColor,
  });

  final String title;
  final String subtitle;
  final String tipoLabel;
  final IconData iconData;
  final Color iconBg;
  final Color iconColor;
  final Color badgeColor;
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 17,
                      color: context.cTextPrimary,
                      letterSpacing: -0.41),
                ),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: valueColor != null
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: valueColor ?? context.cGray,
                        letterSpacing: -0.41),
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Divider(
                  color: context.cGray4.withValues(alpha: .5), height: 1),
            ),
        ],
      );
}
