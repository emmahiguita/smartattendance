import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import 'dashboard_action_card.dart';
import 'dashboard_hero_card.dart';

/// Accesos con responsabilidades distintas: registrar, gestionar trabajadores
/// y consultar/exportar. Evita duplicar botones que abrían la misma pantalla.
class DashboardActionGrid extends StatelessWidget {
  const DashboardActionGrid(
      {super.key,
      required this.user,
      required this.nextTipo,
      required this.registering,
      required this.onRegisterAttendance});
  final dynamic user;
  final String nextTipo;
  final bool registering;
  final VoidCallback onRegisterAttendance;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeroCard(onTap: onRegisterAttendance),
              const SizedBox(height: 12),
              DashboardActionCard(
                  title: 'Historial y reportes',
                  subtitle: 'Fotos · PDF · Excel · Compartir',
                  icon: Icons.folder_copy_outlined,
                  accentColor: const Color(0xFF059669),
                  isRowLayout: true,
                  onTap: () => context.push(AppRoutes.history)),
            ]);
      });
}
