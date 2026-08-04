// lib/features/qr/data/models/qr_model.dart

/// Resultado de la validación de un QR.
/// `tipo`, `fechaRegistro` y `horaRegistro` los decide el SERVIDOR — el reloj
/// del dispositivo jamás influye en qué tipo de registro se crea (C2).
final class QRValidateModel {
  const QRValidateModel({
    required this.valid,
    required this.mensaje,
    this.usuarioId,
    this.tipo,
    this.fechaRegistro,
    this.horaRegistro,
  });

  final bool valid;
  final String mensaje;
  final int? usuarioId;

  /// 'entrada' | 'salida' — decidido por el servidor.
  final String? tipo;

  /// Fecha del registro en formato YYYY-MM-DD (server time).
  final String? fechaRegistro;

  /// Hora del registro en formato HH:MM:SS (server time).
  final String? horaRegistro;

  factory QRValidateModel.fromJson(Map<String, dynamic> json) =>
      QRValidateModel(
        valid: json['valid'] as bool,
        mensaje: json['mensaje'] as String,
        usuarioId: json['usuario_id'] as int?,
        tipo: json['tipo'] as String?,
        fechaRegistro: json['fecha_registro'] as String?,
        horaRegistro: json['hora_registro'] as String?,
      );
}
