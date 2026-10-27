// ============================================================================
// ARCHIVO: user_model.dart
// QUÉ HACE: Modelo de datos que transforma JSON de API o filas SQLite a
//           la entidad de dominio `UserEntity`.
// CÓMO FUNCIONA: Evalúa privilegios administrativos mediante la regla estricta
//                `LocalAuthDataSource.isRoleAdmin` (sin subcadenas ambiguas).
// POR QUÉ: Evita escalamiento de privilegios por cargos como "Auxiliar
//          Administrativo" y cumple Clean Architecture (< 100 líneas).
// ============================================================================

import '../../domain/entities/user_entity.dart';
import '../datasources/local_auth_datasource.dart';

/// Modelo de transformación de datos de usuario (JSON / SQLite ↔ Dominio).
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

  /// QUÉ HACE: Construye `UserModel` desde JSON validando rol estricto.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final role = (json['cargo'] ?? json['rol'] ?? json['role'] ?? '').toString();
    final cedula = (json['cedula'] ?? '').toString();
    final bool admin = (json['is_admin'] == 1 || json['is_admin'] == true) ||
        (json['isAdmin'] == 1 || json['isAdmin'] == true) ||
        LocalAuthDataSource.isRoleAdmin(role, cedula);

    return UserModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      cedula: cedula,
      correo: (json['correo'] ?? '').toString(),
      cargo: role.isEmpty ? 'Colaborador' : role,
      fechaNacimiento: json['fecha_nacimiento'] as String?,
      telefono: json['telefono'] as String?,
      direccion: json['direccion'] as String?,
      fotoUrl: json['foto_url'] as String?,
      isAdmin: admin,
    );
  }

  /// QUÉ HACE: Convierte el modelo de datos en entidad de dominio inmutable.
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

  /// QUÉ HACE: Construye `UserModel` desde una fila local de `usuarios_locales`.
  factory UserModel.fromLocalRow(Map<String, dynamic> row) {
    final cargo = (row['cargo'] as String?) ?? 'Colaborador';
    final cedula = (row['cedula'] as String?) ?? '';
    return UserModel(
      id: row['id'] as int,
      nombre: row['nombre'] as String,
      apellido: (row['apellido'] as String?) ?? '',
      cedula: cedula,
      correo: (row['correo'] as String?) ?? '',
      cargo: cargo,
      fechaNacimiento: row['fecha_nacimiento'] as String?,
      telefono: row['telefono'] as String?,
      direccion: row['direccion'] as String?,
      fotoUrl: row['foto_url'] as String?,
      isAdmin: row['is_admin'] == 1 || LocalAuthDataSource.isRoleAdmin(cargo, cedula),
    );
  }
}
