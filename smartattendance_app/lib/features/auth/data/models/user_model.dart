// lib/features/auth/data/models/user_model.dart
import '../../domain/entities/user_entity.dart';

/// Data model: parses API JSON and maps to UserEntity.
/// SRP: only data transformation (JSON ↔ domain entity).
final class UserModel {
  const UserModel({
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
  final String? fotoUrl;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        apellido: json['apellido'] as String,
        cedula: json['cedula'] as String,
        correo: json['correo'] as String,
        cargo: json['cargo'] as String,
        fechaNacimiento: json['fecha_nacimiento'] as String?,
        telefono: json['telefono'] as String?,
        direccion: json['direccion'] as String?,
        fotoUrl: json['foto_url'] as String?,
      );

  /// LSP: UserEntity can be substituted wherever UserModel is expected.
  UserEntity toEntity() => UserEntity(
        id: id,
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
        correo: correo,
        cargo: cargo,
        fechaNacimiento: fechaNacimiento,
        telefono: telefono,
        direccion: direccion,
        fotoUrl: fotoUrl,
      );

  /// Crea un UserModel desde una fila de SQLite (usuarios_locales).
  factory UserModel.fromLocalRow(Map<String, dynamic> row) => UserModel(
        id: row['id'] as int,
        nombre: row['nombre'] as String,
        apellido: row['apellido'] as String,
        cedula: row['cedula'] as String,
        correo: (row['correo'] as String?) ?? '',
        cargo: (row['cargo'] as String?) ?? 'Empleado',
        fotoUrl: row['foto_url'] as String?,
        telefono: row['telefono'] as String?,
      );
}
