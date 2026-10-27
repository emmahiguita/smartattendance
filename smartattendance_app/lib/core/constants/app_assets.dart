// ============================================================================
// ARCHIVO: app_assets.dart
// QUÉ HACE: Registro centralizado de recursos gráficos (logos, banners e iconos)
//           del kit visual oficial de Serviciudad E.S.P.
// CÓMO FUNCIONA: Constantes fuertemente tipadas organizadas por categoría con
//                soporte para carga directa mediante `Image.asset`.
// POR QUÉ: Evita strings mágicos y centraliza rutas de assets (< 180 líneas).
// ============================================================================

abstract final class AppAssets {
  // ── LOGOS ──
  static const String logoOficialReal = 'assets/logos/serviciudad_oficial_real.png';
  static const String logoCompletoVertical = 'assets/logos/logo_completo_vertical.png';
  static const String logoHorizontal = 'assets/logos/logo_horizontal.png';
  static const String simboloSinFondo = 'assets/logos/simbolo_sin_fondo.png';
  static const String logoOficial = 'assets/images/serviciudad_logo.png';

  // ── BANNERS INSTITUCIONALES ──
  static const String bannerInicioAlcantarillado = 'assets/banners/banner_inicio_alcantarillado.jpg';
  static const String bannerAcueducto = 'assets/banners/banner_acueducto.png';
  static const String bannerAlcantarillado = 'assets/banners/banner_alcantarillado.png';
  static const String bannerAseo = 'assets/banners/banner_aseo.png';
  static const String bannerZonas = 'assets/banners/banner_zonas.png';

  // ── ICONOS DE SERVICIOS ──
  static const String iconoAcueducto = 'assets/iconos/acueducto.png';
  static const String iconoAlcantarillado = 'assets/iconos/alcantarillado.png';
  static const String iconoAseo = 'assets/iconos/aseo.png';

  // ── ICONOS DE ROLES ──
  static const String iconoAdministrador = 'assets/iconos/administrador.png';
  static const String iconoSupervisor = 'assets/iconos/supervisor.png';
  static const String iconoEmpleado = 'assets/iconos/empleado.png';
  static const String iconoPersonal = 'assets/iconos/personal.png';

  // ── ICONOS DE ASISTENCIA Y ESTADOS ──
  static const String iconoAsistencia = 'assets/iconos/asistencia.png';
  static const String iconoPresente = 'assets/iconos/presente.png';
  static const String iconoAusente = 'assets/iconos/ausente.png';
  static const String iconoDescanso = 'assets/iconos/descanso.png';
  static const String iconoSalida = 'assets/iconos/salida.png';
  static const String iconoHistorial = 'assets/iconos/historial.png';
  static const String iconoIncidencias = 'assets/iconos/incidencias.png';

  // ── ICONOS DE MAPAS, RUTAS Y OPERACIONES ──
  static const String iconoUbicacionGps = 'assets/iconos/ubicacion_gps.png';
  static const String iconoGeocerca = 'assets/iconos/geocerca.png';
  static const String iconoZonas = 'assets/iconos/zonas.png';
  static const String iconoRutas = 'assets/iconos/rutas.png';
  static const String iconoTareas = 'assets/iconos/tareas.png';
  static const String iconoOffline = 'assets/iconos/offline.png';
  static const String iconoSincronizar = 'assets/iconos/sincronizar.png';

  // ── ICONOS DE ACCIONES Y NAVEGACIÓN ──
  static const String iconoBuscar = 'assets/iconos/buscar.png';
  static const String iconoCamara = 'assets/iconos/camara.png';
  static const String iconoCompartir = 'assets/iconos/compartir.png';
  static const String iconoConfiguracion = 'assets/iconos/configuracion.png';
  static const String iconoCrearReporte = 'assets/iconos/crear_reporte.png';
  static const String iconoDescargar = 'assets/iconos/descargar.png';
  static const String iconoDocumentos = 'assets/iconos/documentos.png';
  static const String iconoEditar = 'assets/iconos/editar.png';
  static const String iconoEliminar = 'assets/iconos/eliminar.png';
  static const String iconoEscanear = 'assets/iconos/escanear.png';
  static const String iconoFotos = 'assets/iconos/fotos.png';
  static const String iconoInicio = 'assets/iconos/inicio.png';
  static const String iconoNotificaciones = 'assets/iconos/notificaciones.png';
  static const String iconoReportes = 'assets/iconos/reportes.png';
}
