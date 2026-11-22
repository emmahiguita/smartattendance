// ============================================================================
// ARCHIVO: login_header_logo.dart
// QUÉ HACE: Renderiza el logotipo vectorial oficial de BuenTiempo en el Login.
// CÓMO FUNCIONA: Presenta `BuenTiempoLogo` en disposición vertical con ícono
//                squircle estilo Apple iOS y subtítulo corporativo limpio.
// POR QUÉ: Garantiza nitidez vectorial a 120 FPS y contraste en modo claro/oscuro (< 40 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../shared/widgets/buen_tiempo_logo.dart';

class LoginHeaderLogo extends StatelessWidget {
  const LoginHeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: BuenTiempoLogo(
          size: 56,
          isHorizontal: false,
          iosSquircle: true,
          showSubtitle: true,
          subtitleText: 'CONTROL DE ASISTENCIA Y JORNADAS',
        ),
      ),
    );
  }
}
