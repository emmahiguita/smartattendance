// ============================================================================
// ARCHIVO: settings_screen.dart
// QUÉ HACE: Pantalla de Configuración profesional estilo Apple iOS nativo
//           (CupertinoIcons, Inset Grouped cards, controles adaptativos).
// CÓMO FUNCIONA: Squircles con glifos blancos, switches y segmented controls
//                iOS, consulta `localActorProvider` para panel admin.
// POR QUÉ: Elimina estilo vibecoder y cumple < 190 líneas con arquitectura sólida.
// ============================================================================

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/localstore/secure_storage_provider.dart';
import '../../../../core/notifications/journey_reminders.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/confirm_logout.dart';
import '../../../../shared/widgets/app_appbar.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../profile/presentation/widgets/app_info_modal.dart';
import 'settings_legal_sheets.dart';
import 'settings_permissions_card.dart';
import 'settings_server_section.dart';
import 'settings_widgets.dart';

/// Módulo Configuración — estilo iOS Human Interface Guidelines.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final String _appVersion = AppConfig.appVersion;
  bool _clearingCache = false;

  Future<void> _toggleNotifications(bool value) async {
    await ref
        .read(secureStorageProvider)
        .write(key: AppConfig.keyNotificationsEnabled, value: value.toString());
    ref.invalidate(notificationsEnabledProvider);
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Caché temporal liberado correctamente'),
        backgroundColor: Color(0xFF34C759)));
  }

  Widget get _disclosureChevron => Icon(
        CupertinoIcons.chevron_forward,
        size: 15,
        color:
            context.isDark ? const Color(0xFF545458) : const Color(0xFFC7C7CC),
      );

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);
    final notificationsEnabled =
        ref.watch(notificationsEnabledProvider).valueOrNull ?? true;
    final isAdmin = ref.watch(localActorProvider).isStrictAdmin;

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppAppBar(
        title: 'Configuración',
        centerTitle: true,
        leadingWidget: IconButton(
          icon: Icon(CupertinoIcons.chevron_back,
              size: 22, color: context.cPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          const SettingsSectionTitle('Apariencia'),
          SettingsGroupCard(children: [
            const SettingItemRow(
              icon: CupertinoIcons.moon_fill,
              accentColor: Color(0xFF5856D6),
              title: 'Tema',
              subtitle: 'Automático, claro u oscuro',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<ThemeMode>(
                  groupValue: themeMode,
                  children: const {
                    ThemeMode.system: Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Auto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    ThemeMode.light: Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Claro', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    ThemeMode.dark: Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Oscuro', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  },
                  onValueChanged: (val) {
                    if (val != null) ref.read(themeControllerProvider.notifier).setMode(val);
                  },
                ),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          const SettingsSectionTitle('Notificaciones'),
          SettingsGroupCard(children: [
            SettingItemRow(
              icon: CupertinoIcons.bell_fill,
              accentColor: const Color(0xFFFF9500),
              title: 'Recordatorios de jornada',
              subtitle: notificationsEnabled
                  ? 'Alertas activas para marcas de jornada'
                  : 'Notificaciones desactivadas',
              trailing: CupertinoSwitch(
                value: notificationsEnabled,
                activeTrackColor: const Color(0xFF34C759),
                onChanged: _toggleNotifications,
              ),
            ),
          ]),
          if (isAdmin) ...[
            const SizedBox(height: 18),
            const SettingsSectionTitle('Servidor (Solo Administrador)'),
            const SettingsGroupCard(children: [SettingsServerUrlRow()]),
          ],
          const SizedBox(height: 18),
          const SettingsSectionTitle('Permisos'),
          const SettingsPermissionsCard(),
          const SizedBox(height: 18),
          const SettingsSectionTitle('Información y Legal'),
          SettingsGroupCard(children: [
            SettingItemRow(
              icon: CupertinoIcons.info_circle_fill,
              accentColor: const Color(0xFF007AFF),
              title: 'Acerca de ${AppConfig.appName}',
              subtitle: 'Versión v$_appVersion · dev emm ai · Autoría y Canales',
              trailing: _disclosureChevron,
              onTap: () => showAppInfoModal(context),
            ),
            const SettingsGroupDivider(),
            SettingItemRow(
              icon: CupertinoIcons.doc_text_fill,
              accentColor: const Color(0xFF5856D6),
              title: 'Términos de Servicio',
              subtitle: 'Licencia propietaria comercial y condiciones de uso',
              trailing: _disclosureChevron,
              onTap: () => showLegalTermsModal(context),
            ),
            const SettingsGroupDivider(),
            SettingItemRow(
              icon: CupertinoIcons.shield_lefthalf_fill,
              accentColor: const Color(0xFF34C759),
              title: 'Política de Privacidad y Habeas Data',
              subtitle: 'Protección de datos personales, biometría y GPS',
              trailing: _disclosureChevron,
              onTap: () => showPrivacyPolicyModal(context),
            ),
            const SettingsGroupDivider(),
            SettingItemRow(
              icon: CupertinoIcons.trash_fill,
              accentColor: const Color(0xFFFF9500),
              title: 'Limpiar caché local',
              subtitle: 'Elimina archivos temporales de la aplicación',
              trailing: _disclosureChevron,
              onTap: _clearingCache ? null : _clearCache,
            ),
          ]),
          const SizedBox(height: 18),
          const SettingsSectionTitle('Sesión'),
          SettingsGroupCard(children: [
            SettingItemRow(
              icon: CupertinoIcons.square_arrow_right,
              accentColor: const Color(0xFFFF3B30),
              title: 'Cerrar sesión',
              subtitle: 'Sal de la cuenta en este dispositivo',
              trailing: _disclosureChevron,
              onTap: () => confirmLogout(context, ref),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
