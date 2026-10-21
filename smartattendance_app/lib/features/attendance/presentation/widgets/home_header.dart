// lib/features/attendance/presentation/widgets/home_header.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'live_clock_widget.dart';

/// ============================================================================
/// COMPONENTE: HomeHeader (Estilo Apple iOS)
/// ============================================================================
/// QUÉ HACE:
/// Muestra el saludo al colaborador, su cargo, documento de identidad y
/// el reloj digital con cifras tabulares en tiempo real.
///
/// CÓMO FUNCIONA:
/// Diseñado con estética limpia Apple HIG: tipografía con peso marcado,
/// sin botones redundantes de "Marcar" (la marcación se hace directamente
/// tocando las tarjetas de jornada: Entrada, Almuerzo, Regreso, Salida).
///
/// POR QUÉ:
/// Elimina duplicidad de controles y redundancias visuales cumpliendo SOLID (< 200 líneas).
/// ============================================================================
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.user,
  });

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${user?.fullName ?? 'Colaborador'}',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: context.cTextPrimary,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${user?.cargo ?? 'Colaborador'} · C.C. ${user?.cedula ?? '---'}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6C6C70),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              const LiveClockWidget(),
            ],
          ),
        ),
      ],
    );
  }
}
