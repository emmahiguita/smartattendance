// lib/features/auth/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

/// Domain entity — pure Dart, no framework dependencies.
/// Equatable: value equality for testing and state comparison.
final class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.correo,
    required this.cargo,
    this.fechaNacimiento,
    this.telefono,
    this.direccion,
    this.fotoUrl,
  });

  final int id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String correo;
  final String cargo;
  final String? fechaNacimiento;
  final String? telefono;
  final String? direccion;

  /// Foto de perfil — ruta relativa del servidor (/static/fotos/{filename}).
  /// Null si no ha subido foto (se muestra el avatar con iniciales).
  final String? fotoUrl;

  String get fullName => '$nombre $apellido';

  @override
  List<Object?> get props => [
        id,
        cedula,
        nombre,
        apellido,
        correo,
        cargo,
        fechaNacimiento,
        telefono,
        direccion,
        fotoUrl,
      ];
}
