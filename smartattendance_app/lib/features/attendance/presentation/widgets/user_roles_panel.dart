// QUÉ HACE: Describe las responsabilidades de cada rol de la aplicación.
// CÓMO: Presenta filas con iconos neutros y divisores, sin tarjetas gráficas.
// POR QUÉ: Hace visibles los permisos sin confundirlos con el acceso de la sesión.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class UserRolesPanel extends StatelessWidget {
  const UserRolesPanel({super.key});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ROLES DE USUARIO',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.cTextSecondary)),
          const SizedBox(height: 8),
          _role(context, Icons.person_outline, 'Colaborador',
              'Registra su jornada y consulta su horario asignado.'),
          _role(context, Icons.groups_outlined, 'Supervisor',
              'Gestiona el personal y la asistencia de su equipo autorizado.'),
          _role(context, Icons.manage_accounts_outlined, 'Administrador',
              'Administra personal, equipos, sitios, horarios y reportes.'),
        ],
      );
  Widget _role(BuildContext context, IconData icon, String label, String text) => Column(children: [
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: context.cTextSecondary),
            title: Text(label, style: TextStyle(color: context.cTextPrimary)),
            subtitle: Text(text, style: TextStyle(color: context.cTextSecondary))),
        Divider(height: 1, color: context.cBorder),
      ]);
}
