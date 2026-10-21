import '../../../../core/location/location_service.dart';
import '../domain/attendance_location.dart';

/// Adaptador al sensor real. El servicio valida permiso, antigüedad, precisión
/// y la señal de ubicación simulada que Android entrega; no usa geocodificación.
class DeviceAttendanceLocation implements AttendanceLocationSource {
  const DeviceAttendanceLocation();

  @override
  Future<AttendanceLocation> capture() async {
    final position = await const LocationService().attendancePosition();
    return AttendanceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        fixedAt: position.timestamp.toUtc());
  }

  @override
  Future<bool> ready() async {
    final status = await const LocationService().checkStatus();
    return status.serviceEnabled && status.permissionGranted;
  }
}
