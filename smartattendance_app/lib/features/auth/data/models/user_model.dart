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
    this.isAdmin = false,
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
  final bool isAdmin;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Determine admin status from json if backend provides it, otherwise default to false.
    // The backend in this project does not explicitly send is_admin in the base user schema,
    // so we rely on the role check or the local DB sync when available.
    final bool admin = json.containsKey('is_admin')
        ? (json['is_admin'] == 1 || json['is_admin'] == true)
        : false;

    return UserModel(
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
      isAdmin: admin,
    );
  }

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
        isAdmin: isAdmin,
      );

  /// Crea un UserModel desde una fila de SQLite (usuarios_locales).
  factory UserModel.fromLocalRow(Map<String, dynamic> row) => UserModel(
        id: row['id'] as int,
        nombre: row['nombre'] as String,
        apellido: row['apellido'] as String,
        cedula: row['cedula'] as String,
        correo: (row['correo'] as String?) ?? '',
        cargo: (row['cargo'] as String?) ?? 'Empleado',
        fechaNacimiento: row['fecha_nacimiento'] as String?,
        telefono: row['telefono'] as String?,
        direccion: row['direccion'] as String?,
        fotoUrl: row['foto_url'] as String?,
        isAdmin: row['is_admin'] == 1,
      );
}
