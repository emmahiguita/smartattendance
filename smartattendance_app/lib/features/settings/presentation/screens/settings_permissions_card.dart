// ============================================================================
// ARCHIVO: settings_permissions_card.dart
// QUÉ HACE: Tarjeta iOS Inset Grouped para auditoría y solicitud de permisos
//           reales del SO (Cámara, GPS geocerca y servicio de localización).
// CÓMO FUNCIONA: Consulta Geolocator y MobileScanner para verificar disponibilidad
//                de hardware sin simulaciones, mostrando badges dinámicos.
// POR QUÉ: Descompone SettingsScreen (< 200 líneas) bajo Clean Architecture
//          respetando la regla de modularización estricta.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/location/location_service.dart';
import 'settings_widgets.dart';

/// Tarjeta Inset Grouped con diagnósticos de hardware en tiempo real.
class SettingsPermissionsCard extends StatefulWidget {
  const SettingsPermissionsCard({super.key});

  @override
  State<SettingsPermissionsCard> createState() => _SettingsPermissionsCardState();
}

class _SettingsPermissionsCardState extends State<SettingsPermissionsCard> {
  static const _location = LocationService();
  bool _cameraOk = false;
  bool _checkingCamera = false;
  bool _locationOk = false;
  bool _locationService = false;

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final status = await _location.checkStatus();
    if (!mounted) return;
    setState(() {
      _locationOk = status.permissionGranted;
      _locationService = status.serviceEnabled;
    });
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
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
      await _refreshPermissions();
    } catch (_) {}
  }

  Widget _statusChip(bool ok) => Text(ok ? 'Concedido' : 'Requerido',
      style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface));
  @override
  Widget build(BuildContext context) {
    return SettingsGroupCard(
      children: [
        SettingItemRow(
          icon: CupertinoIcons.camera_fill,
          accentColor: const Color(0xFF007AFF),
          title: 'Cámara',
          subtitle:
              _cameraOk ? 'Disponible para captura biométrica' : 'Toca para verificar el acceso a la cámara',
          trailing: _checkingCamera
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : _statusChip(_cameraOk),
          onTap: _checkCamera,
        ),
        const SettingsGroupDivider(),
        SettingItemRow(
          icon: CupertinoIcons.location_fill,
          accentColor: const Color(0xFF34C759),
          title: 'Ubicación GPS',
          subtitle: _locationOk ? 'Permiso concedido' : 'Sin permiso — requerido para geocerca',
          trailing: _statusChip(_locationOk),
          onTap: _requestLocationPermission,
        ),
        const SettingsGroupDivider(),
        SettingItemRow(
          icon: CupertinoIcons.compass_fill,
          accentColor: const Color(0xFF30B0C7),
          title: 'Servicio de ubicación',
          subtitle: _locationService ? 'Activado en el sistema' : 'Desactivado en el sistema',
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: Geolocator.openLocationSettings,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ajustes',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 2),
                Icon(CupertinoIcons.chevron_forward,
                    size: 14, color: Theme.of(context).colorScheme.onSurface),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
