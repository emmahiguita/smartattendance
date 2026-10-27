// ============================================================================
// ARCHIVO: settings_server_section.dart
// QUÉ HACE: Panel exclusivo del Administrador para configurar y probar la URL
//           del servidor backend corporativo.
// CÓMO FUNCIONA: Valida formato URI y ejecuta prueba de conectividad real.
// POR QUÉ: Evita que colaboradores normales apunten la app a servidores falsos
//          y mantiene el archivo bajo < 145 líneas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/server_config_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'settings_widgets.dart';

/// QUÉ HACE: Controla la edición y verificación de la URL del backend (solo Admin).
class SettingsServerUrlRow extends ConsumerStatefulWidget {
  const SettingsServerUrlRow({super.key});
  @override
  ConsumerState<SettingsServerUrlRow> createState() => _SettingsServerUrlRowState();
}

class _SettingsServerUrlRowState extends ConsumerState<SettingsServerUrlRow> {
  bool _testing = false;
  bool? _lastTestResult;

  Future<void> _showServerDialog() async {
    final notifier = ref.read(serverConfigNotifierProvider.notifier);
    final controller = TextEditingController(text: notifier.currentUrl);
    final formKey = GlobalKey<FormState>();

    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Servidor Backend (Solo Admin)'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'URL del servidor',
              hintText: 'http://192.168.1.100:8000/api/v1',
              helperText: 'Incluye el puerto. /api/v1 se agrega automáticamente.',
              helperMaxLines: 2,
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa una URL';
              final uri = Uri.tryParse(v.trim());
              if (uri == null || !uri.hasScheme) return 'URL inválida';
              return null;
            },
          ),
        ),
        actions: [
          if (notifier.isCustom)
            TextButton(
              onPressed: () {
                notifier.resetToDefault();
                Navigator.pop(ctx, 'DEFAULT');
              },
              child: const Text('Restaurar default', style: TextStyle(color: AppColors.systemRed)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (url == 'DEFAULT') {
      _showSnack('URL restaurada al default', ok: true);
    } else if (url != null && url.isNotEmpty) {
      await ref.read(serverConfigNotifierProvider.notifier).setUrl(url);
      if (mounted) _showSnack('Servidor actualizado. Reconectando...', ok: true);
    }
  }

  Future<void> _testConnection() async {
    setState(() => (_testing = true, _lastTestResult = null));
    final ok = await ref.read(serverConfigNotifierProvider.notifier).testConnection();
    if (!mounted) return;
    setState(() => (_testing = false, _lastTestResult = ok));
    _showSnack(
      ok ? 'Conexión exitosa al servidor' : 'No se pudo conectar al servidor.',
      ok: ok,
    );
  }

  void _showSnack(String message, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: ok ? AppColors.systemGreen : AppColors.systemRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final serverUrl = ref.watch(serverConfigNotifierProvider);
    final isCustom = ref.watch(serverConfigNotifierProvider.notifier).isCustom;
    final display = serverUrl.replaceAll('/api/v1', '');

    return Column(
      children: [
        SettingItemRow(
          icon: Icons.dns,
          accentColor: const Color(0xFF7C3AED),
          title: 'Dirección del servidor',
          subtitle: isCustom ? 'Personalizado: $display' : 'Default: $display',
          trailing: IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: _showServerDialog, tooltip: 'Cambiar servidor'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _testing ? null : _testConnection,
              icon: _testing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_lastTestResult == true ? Icons.check_circle : (_lastTestResult == false ? Icons.error : Icons.wifi_find), size: 18),
              label: Text(_testing ? 'Probando...' : 'Probar conexión'),
            ),
          ),
        ),
      ],
    );
  }
}
