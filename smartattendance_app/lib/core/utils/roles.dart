// ============================================================================
// ARCHIVO: roles.dart
// QUÉ HACE: Fuente única de verdad para la jerarquía de roles y puestos (RBAC)
//           en Serviciudad E.S.P. / SmartAttendance:
//           - Administrador General: Crea puestos, equipos, zonas y todo rol.
//           - Supervisor / Encargado: Gestiona su cuadrilla y asigna puestos
//             operativos (Operador, Colaborador, Operario, etc.).
//           - Operativo (Operador, Colaborador, Operario, etc.): Marcación.
// CÓMO FUNCIONA: Clasifica cadenas de cargo y combina los puestos base con los
//                puestos personalizados creados por el Administrador en SQLite.
// POR QUÉ: Garantiza seguridad de permisos y consistencia de puestos (< 130 líneas).
// ============================================================================

import '../../features/auth/domain/entities/user_entity.dart';

abstract final class AppRoles {
  /// Puestos operativos base aplicables a equipos y colaboradores.
  static const operationalPositions = [
    'Operador',
    'Colaborador',
    'Operario',
    'Promotor',
    'Técnico de Campo',
    'Auxiliar Operativo',
    'Conductor',
  ];

  /// Roles de mando exclusivos para creación por el Administrador General.
  static const managementPositions = [
    'Supervisor',
    'Encargado',
    'Administrador',
  ];

  /// Roles permitidos para registro por un Administrador General.
  static const rolesForAdmin = [
    ...operationalPositions,
    ...managementPositions,
  ];

  /// Roles operativos asignables por Supervisores o Encargados de cuadrilla.
  static const rolesForSupervisor = [
    ...operationalPositions,
  ];

  /// QUÉ HACE: Devuelve una descripción clara del puesto o nivel de acceso.
  static String descriptionFor(String role) {
    return switch (role.trim()) {
      'Operador' => 'Operador técnico o de planta adscrito al equipo',
      'Colaborador' => 'Colaborador de equipo (marca ingreso, almuerzo y salida)',
      'Operario' => 'Operario de campo adscrito a la cuadrilla y geocerca',
      'Promotor' => 'Promotor operativo de zona o gestión ambiental',
      'Técnico de Campo' => 'Técnico especializado en redes, acueducto o aseo',
      'Auxiliar Operativo' => 'Apoyo operativo en ruta o frente de servicio',
      'Conductor' => 'Conductor de vehículo operativo o compactador',
      'Supervisor' => 'Líder de cuadrilla con control de asistencia de su equipo',
      'Encargado' => 'Encargado delegado de brigada o frente de obra',
      'Administrador' => 'Control total de puestos, equipos, horarios y reportes',
      _ => 'Puesto operativo creado por el Administrador',
    };
  }

  /// QUÉ HACE: Combina los puestos base con los creados por el Administrador.
  static List<String> mergePositions(
    List<String> customPositions, {
    required bool includeManagement,
  }) {
    final result = <String>[
      ...operationalPositions,
      for (final c in customPositions)
        if (c.trim().isNotEmpty &&
            !operationalPositions.contains(c.trim()) &&
            !managementPositions.contains(c.trim()))
          c.trim(),
      if (includeManagement) ...managementPositions,
    ];
    return result;
  }

  /// QUÉ HACE: Evalúa si un usuario es Administrador General (RRHH o Dirección).
  static bool isStrictAdmin(String? roleOrJob, {String? cedula}) {
    final r = (roleOrJob ?? '').trim().toLowerCase();
    return const {'admin', 'administrador', 'administrador general',
      'super_admin', 'gerente', 'rrhh'}.contains(r);
  }

  /// QUÉ HACE: Evalúa si el usuario es Supervisor o Encargado de equipo/zona.
  static bool isSupervisorOrManager(String? roleOrJob) {
    final r = (roleOrJob ?? '').trim().toLowerCase();
    return r == 'supervisor' ||
        r.startsWith('supervisor ') ||
        r == 'encargado' ||
        r == 'encargada' ||
        r.startsWith('encargado ') ||
        r.startsWith('encargada ');
  }

  /// QUÉ HACE: Evalúa si el usuario tiene privilegios de gestión (Admin o Supervisor).
  static bool isManagementUser(UserEntity? user) {
    if (user == null) return false;
    return isStrictAdmin(user.cargo, cedula: user.cedula) ||
        isSupervisorOrManager(user.cargo) ||
        user.isAdmin;
  }

  /// QUÉ HACE: Retorna la lista de roles que el usuario actual está autorizado a crear.
  static List<String> allowedAssignableRoles({
    required bool isStrictAdminUser,
    List<String> customPositions = const [],
  }) {
    return mergePositions(
      customPositions,
      includeManagement: isStrictAdminUser,
    );
  }

  /// Devuelve true si el usuario tiene privilegios administrativos genéricos.
  static bool isAdminUser(UserEntity? user) {
    if (user == null) return false;
    return user.isAdmin || isStrictAdmin(user.cargo, cedula: user.cedula);
  }
}
