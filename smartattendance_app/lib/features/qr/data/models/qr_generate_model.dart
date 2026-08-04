// lib/features/qr/data/models/qr_generate_model.dart

/// Respuesta de POST /qr/generate — código QR recién creado.
final class QRGenerateModel {
  const QRGenerateModel({
    required this.codigo,
    required this.usuarioId,
    required this.fechaGeneracion,
    required this.estado,
  });

  final String codigo;
  final int usuarioId;
  final String fechaGeneracion;
  final bool estado;

  factory QRGenerateModel.fromJson(Map<String, dynamic> json) =>
      QRGenerateModel(
        codigo: json['codigo'] as String,
        usuarioId: json['usuario_id'] as int,
        fechaGeneracion: json['fecha_generacion'] as String,
        estado: json['estado'] as bool,
      );
}
