// ============================================================================
// ARCHIVO: login_header_logo.dart
// QUÉ HACE: Renderiza el icono oficial de Serviciudad E.S.P. en gran formato.
// CÓMO FUNCIONA: Muestra directamente el emblema institucional en alta definición
//                bien posicionado sin textos redundantes externos.
// POR QUÉ: El gráfico oficial ya integra el logotipo, isotipo y servicios (< 50 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class LoginHeaderLogo extends StatelessWidget {
  const LoginHeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 150,
        constraints: const BoxConstraints(maxWidth: 230),
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Image.asset(
          AppAssets.logoOficialReal,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.water_drop_rounded,
            size: 72,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
