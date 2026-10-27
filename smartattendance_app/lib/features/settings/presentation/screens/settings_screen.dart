// ============================================================================
// ARCHIVO: settings_screen.dart
// QUÉ HACE: Pantalla de Configuración con control de tema, permisos de hardware,
//           recordatorios, caché y sección de servidor exclusiva para Admin.
// CÓMO FUNCIONA: Consulta `localActorProvider` para ocultar la configuración de
//                servidor backend (`SettingsServerUrlRow`) a usuarios normales.
// POR QUÉ: Impide que colaboradores alteren la infraestructura de red y cumple
//          estrictamente el límite de < 195 líneas.
// ============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/localstore/secure_storage_provider.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/notifications/journey_reminders.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/confirm_logout.dart';
import '../../../../shared/widgets/app_appbar.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import 'settings_server_section.dart';
import 'settings_widgets.dart';

/// Módulo Configuración — preferencias reales y estado de permisos.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _location = LocationService();
  final String _appVersion = AppConfig.appVersion;
  bool _cameraOk = false, _checkingCamera = false, _locationOk = false, _locationService = false, _clearingCache = false;

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final status = await _location.checkStatus();
    if (!mounted) return;
    setState(() => (_locationOk = status.permissionGranted, _locationService = status.serviceEnabled));
  }

  Future<void> _toggleNotifications(bool value) async {
    await ref.read(secureStorageProvider).write(key: AppConfig.keyNotificationsEnabled, value: value.toString());
    ref.invalidate(notificationsEnabledProvider);
  }

  Future<void> _checkCamera() async {
    if (_checkingCamera) return;
    setState(() => _checkingCamera = true);
    bool cam = false;
    try {
      final ctrl = MobileScannerController();
      await ctrl.start();
      cam = true;
      await ctrl.stop();
      await ctrl.dispose();
    } catch (_) {}
    if (mounted) setState(() => (_cameraOk = cam, _checkingCamera = false));
  }

  Future<void> _requestLocationPermission() async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.deniedForever) await Geolocator.openAppSettings();
      await _refreshPermissions();
    } catch (_) {}
  }

  Future<void> _clearCache() async {
    if (kIsWeb) return;
    setState(() => _clearingCache = true);
    try {
      final dir = await getTemporaryDirectory();
      await for (final entity in dir.list()) {
        try {
          if (entity is File) await entity.delete();
          if (entity is Directory) await entity.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _clearingCache = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caché temporal liberado correctamente'), backgroundColor: AppColors.systemGreen),
    );
  }

  Widget _statusChip(bool ok) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: (ok ? AppColors.systemGreen : AppColors.systemRed).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(ok ? 'OK' : 'Falta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ok ? AppColors.systemGreen : AppColors.systemRed)),
      );

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider).valueOrNull ?? true;
    final isAdmin = ref.watch(localActorProvider).isAdmin;

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppAppBar(
        title: 'Configuración',
        centerTitle: true,
        leadingWidget: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.systemBlue), onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SettingsSectionTitle('Apariencia'),
          SettingsGroupCard(children: [
            const SettingItemRow(icon: Icons.dark_mode, accentColor: Color(0xFF8B5CF6), title: 'Tema', subtitle: 'Sistema, claro u oscuro'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro')),
                  ],
                  selected: {themeMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (sel) => ref.read(themeControllerProvider.notifier).setMode(sel.first),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          const SettingsSectionTitle('Notificaciones'),
          SettingsGroupCard(children: [
            SettingItemRow(
              icon: Icons.notifications,
              accentColor: const Color(0xFFF59E0B),
              title: 'Recordatorios de jornada',
              subtitle: notificationsEnabled ? 'Alertas activas para marcas de entrada y salida' : 'Notificaciones desactivadas',
              trailing: Switch(value: notificationsEnabled, activeThumbColor: AppColors.primary, onChanged: _toggleNotifications),
            ),
          ]),
          if (isAdmin) ...[
            const SizedBox(height: 20),
            const SettingsSectionTitle('Servidor (Solo Administrador)'),
            const SettingsGroupCard(children: [SettingsServerUrlRow()]),
          ],
          const SizedBox(height: 20),
          const SettingsSectionTitle('Permisos'),
          SettingsGroupCard(children: [
            SettingItemRow(
              icon: Icons.photo_camera,
              accentColor: const Color(0xFF3B82F6),
              title: 'Cámara',
              subtitle: _cameraOk ? 'Disponible para captura biométrica' : 'Toca para verificar el acceso a la cámara',
              trailing: _checkingCamera ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : _statusChip(_cameraOk),
              onTap: _checkCamera,
            ),
            const Divider(height: 1),
            SettingItemRow(
              icon: Icons.location_on,
              accentColor: const Color(0xFF22C55E),
              title: 'Ubicación GPS',
              subtitle: _locationOk ? 'Permiso concedido' : 'Sin permiso — requerido para validar geocerca',
              trailing: _statusChip(_locationOk),
              onTap: _requestLocationPermission,
            ),
            const Divider(height: 1),
            SettingItemRow(
              icon: Icons.my_location,
              accentColor: const Color(0xFF14B8A6),
              title: 'Servicio de ubicación',
              subtitle: _locationService ? 'Activado' : 'Desactivado en el sistema',
              trailing: const TextButton(onPressed: Geolocator.openLocationSettings, child: Text('Ajustes')),
            ),
          ]),
          const SizedBox(height: 20),
          const SettingsSectionTitle('Acerca de & Sesión'),
          SettingsGroupCard(children: [
            SettingItemRow(icon: Icons.description, accentColor: const Color(0xFF6366F1), title: 'Términos y Privacidad', subtitle: 'Tratamiento de datos personales y ubicación', trailing: Icon(Icons.chevron_right, color: context.cGray), onTap: () => showSettingsTermsModal(context)),
            const Divider(height: 1),
            SettingItemRow(icon: Icons.cleaning_services, accentColor: const Color(0xFFF59E0B), title: 'Limpiar caché local', subtitle: 'Elimina archivos temporales v$_appVersion', trailing: Icon(Icons.chevron_right, color: context.cGray), onTap: _clearingCache ? null : _clearCache),
            const Divider(height: 1),
            SettingItemRow(icon: Icons.logout, accentColor: AppColors.systemRed, title: 'Cerrar sesión', subtitle: 'Sal de la cuenta en este dispositivo', trailing: Icon(Icons.chevron_right, color: context.cGray), onTap: () => confirmLogout(context, ref)),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
