// Stub de geolocator_linux: Linux no es plataforma objetivo.
// Existe solo para satisfacer la resolución de geolocator (federated plugin)
// sin arrastrar package_info_plus, cuyo módulo Android rompe el build.
library;

import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

/// Implementación mínima no funcional. Lanza si se usara en Linux (no ocurre).
class GeolocatorLinuxStub extends GeolocatorPlatform {
  GeolocatorLinuxStub();

  /// Contrato exigido por flutter tools para `dartPluginClass`.
  static void registerWith() {}

  @override
  Future<bool> isLocationServiceEnabled() async => false;

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.denied;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.denied;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) =>
      throw UnimplementedError(
          'geolocator_linux no está soportado (proyecto target Android).');
}
