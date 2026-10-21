import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/config/app_config.dart';
import 'local_providers.dart';
import 'admin_assignments.dart';
import 'privacy_fields.dart';
import 'admin_unlock_button.dart';
import '../../../../core/auth/session_controller.dart';

/// Ajustes del flujo Android local. No ofrece conexión a un servidor ni activa
/// servicios en segundo plano. Cada opción produce una acción real y visible.
class LocalSettingsScreen extends ConsumerWidget {
  const LocalSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Configuración')),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Apariencia', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<ThemeMode>(
              key: ValueKey(ref.watch(themeControllerProvider)),
              initialValue: ref.watch(themeControllerProvider),
              decoration: const InputDecoration(labelText: 'Tema'),
              items: const [
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('Del dispositivo')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Claro')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Oscuro'))
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeControllerProvider.notifier).setMode(value);
                }
              }),
          const SizedBox(height: 24),
          if (ref.watch(sessionControllerProvider)
              case SessionAuthenticated(user: final user))
            if (user.isAdmin) const AdminUnlockButton(),
          if (ref.watch(localActorProvider).isAdmin) ...[
            const Text('Empresa y operación'),
            const AdminAssignments(),
            const PrivacyFields(),
            const Divider(),
          ],
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.app_settings_alt),
              title: const Text('Permisos de cámara y ubicación'),
              subtitle: const Text('Abrir ajustes de Android'),
              onTap: () async {
                final opened = await Geolocator.openAppSettings();
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Abre los permisos desde los ajustes de Android.')));
                }
              }),
          const Divider(),
          const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.phone_android),
              title: Text('Almacenamiento local'),
              subtitle: Text(
                  'Fotos y asistencias permanecen en este dispositivo. Desinstalar o borrar datos las elimina.')),
          const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.ios_share),
              title: Text('Exportación'),
              subtitle: Text(
                  'Desde Historial puedes generar PDF con fotos o CSV para Excel y compartirlos.')),
          const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline),
              title: Text('Evidencia fotográfica'),
              subtitle: Text(
                  'Tomar una foto no verifica automáticamente identidad ni prueba de vida.')),
          const SizedBox(height: 16),
          const Text('Versión ${AppConfig.appVersion}',
              textAlign: TextAlign.center),
        ])),
      );
}
