// lib/features/attendance/presentation/widgets/realtime_map_viewer.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'explorable_map_dialog.dart';

/// Recursos de mapas reales (100% verificados sin marcas de agua ni API key)
enum MapCartoStyle {
  streets(
    'Calles Reales',
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    Icons.map_rounded,
  ),
  satellite(
    'Satélite HD',
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    Icons.satellite_alt_rounded,
  ),
  topo(
    'GIS Oficial',
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    Icons.terrain_rounded,
  );

  final String label;
  final String url;
  final IconData icon;
  const MapCartoStyle(this.label, this.url, this.icon);
}

/// ============================================================================
/// COMPONENTE: RealtimeMapViewer (Cartografía Interactiva y Animada de Alta Gama)
/// ============================================================================
/// QUÉ HACE:
/// Despliega la cartografía en tiempo real sobre la ubicación GPS del colaborador
/// con animación de radar sonar continua, transición de cámara cinematográfica,
/// capas de mapas reales (OpenStreetMap Oficial, Satélite Esri ArcGIS y GIS Oficial),
/// coordenadas exactas en vivo y controles táctiles HUD.
///
/// CARACTERÍSTICAS CLAVE:
/// 1. 100% Interactivo: Soporta arrastre panorámico, pellizco para zoom y doble tap.
/// 2. Animación Sonar: Doble onda expansiva continua con decaimiento de opacidad.
/// 3. Recursos Reales: OpenStreetMap oficial y Satélite Esri ArcGIS sin marcas.
/// 4. Cámara Cinematográfica: Recentrados y zoom con interpolación FastOutSlowIn.
/// 5. HUD Glassmorphism: Botones flotantes de zoom, recentrado, capas y pantalla completa.
/// 6. Pin Interactivo: Muestra badge flotante con coordenadas reales y geocerca (60 m).
/// ============================================================================
class RealtimeMapViewer extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final bool hasFix;
  final String? address;
  final double height;

  const RealtimeMapViewer({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.hasFix,
    this.address,
    this.height = 215.0,
  });

  @override
  State<RealtimeMapViewer> createState() => _RealtimeMapViewerState();
}

class _RealtimeMapViewerState extends State<RealtimeMapViewer> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _pulseController;
  AnimationController? _cameraController;

  bool _ready = false;
  bool _interactiveMode = true;
  bool _showPinInfo = false;
  MapCartoStyle _selectedStyle = MapCartoStyle.streets;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RealtimeMapViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready && widget.latitude != null && widget.longitude != null) {
      final changed = widget.latitude != oldWidget.latitude || widget.longitude != oldWidget.longitude;
      if (changed) {
        _animatedMapMove(LatLng(widget.latitude!, widget.longitude!), 16.5);
      }
    }
  }

  /// Desplazamiento de cámara suave y cinematográfico
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!_ready) return;
    _cameraController?.dispose();

    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _cameraController = controller;

    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.forward();
  }

  Future<void> _openExternal(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _cycleNextStyle() {
    final nextIndex = (MapCartoStyle.values.indexOf(_selectedStyle) + 1) % MapCartoStyle.values.length;
    setState(() {
      _selectedStyle = MapCartoStyle.values[nextIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (widget.latitude == null || widget.longitude == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final h = (constraints.maxHeight.isFinite && constraints.maxHeight < widget.height)
              ? constraints.maxHeight
              : widget.height;
          return Container(
            height: h,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.systemOrange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sincronizando satélites GPS…',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.cTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final lat = widget.latitude!;
    final lng = widget.longitude!;
    final point = LatLng(lat, lng);

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = (constraints.maxHeight.isFinite && constraints.maxHeight < widget.height)
            ? constraints.maxHeight
            : widget.height;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: h,
            width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (widget.hasFix ? AppColors.primary : AppColors.systemOrange).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── MAPA FLUTTER_MAP CON RECURSOS REALES ─────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                onMapReady: () => _ready = true,
                initialCenter: point,
                initialZoom: 16.5,
                minZoom: 4,
                maxZoom: 19.5,
                interactionOptions: InteractionOptions(
                  flags: _interactiveMode
                      ? (InteractiveFlag.all & ~InteractiveFlag.rotate)
                      : (InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom),
                ),
                onTap: (_, __) {
                  if (_showPinInfo) {
                    setState(() => _showPinInfo = false);
                  }
                },
              ),
              children: [
                // 1. Capa de Cartografía Real (OpenStreetMap / Satélite Esri / GIS Oficial)
                TileLayer(
                  key: ValueKey(_selectedStyle.url),
                  urlTemplate: _selectedStyle.url,
                  userAgentPackageName: 'io.smartattendance.attendance',
                  tileProvider: NetworkTileProvider(
                    headers: {
                      'User-Agent': 'SmartAttendanceApp/1.0.0 (io.smartattendance.attendance; Android)',
                    },
                  ),
                  maxNativeZoom: 19,
                  subdomains: const ['a', 'b', 'c'],
                ),

                // 2. Ondas Sonar y Perímetro de Geocerca (Animadas en Tiempo Real)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final progress = _pulseController.value;
                    // Onda interior (0 a 45m)
                    final innerRadius = 20.0 + (progress * 35.0);
                    final innerAlpha = (1.0 - progress) * 0.40;

                    // Onda exterior (10 a 80m)
                    final outerRadius = 35.0 + (progress * 55.0);
                    final outerAlpha = (1.0 - progress) * 0.25;

                    return CircleLayer(
                      circles: [
                        // Geocerca estática autorizada (60m)
                        CircleMarker(
                          point: point,
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderColor: AppColors.primary.withValues(alpha: 0.75),
                          borderStrokeWidth: 2.0,
                          useRadiusInMeter: true,
                          radius: 60,
                        ),
                        // Onda Sonar Primaria
                        CircleMarker(
                          point: point,
                          color: AppColors.primary.withValues(alpha: innerAlpha * 0.55),
                          borderColor: AppColors.primary.withValues(alpha: innerAlpha),
                          borderStrokeWidth: 1.5,
                          useRadiusInMeter: true,
                          radius: innerRadius,
                        ),
                        // Onda Sonar Secundaria
                        CircleMarker(
                          point: point,
                          color: AppColors.accentIndigo.withValues(alpha: outerAlpha * 0.45),
                          borderColor: AppColors.accentIndigo.withValues(alpha: outerAlpha),
                          borderStrokeWidth: 1.2,
                          useRadiusInMeter: true,
                          radius: outerRadius,
                        ),
                      ],
                    );
                  },
                ),

                // 3. Marcador Biométrico de Posición con Pulso Luminoso
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 58,
                      height: 58,
                      child: GestureDetector(
                        onTap: () => setState(() => _showPinInfo = !_showPinInfo),
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale = 1.0 + (_pulseController.value * 0.14);
                            return Center(
                              child: Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: widget.hasFix
                                          ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                                          : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (widget.hasFix ? AppColors.primary : AppColors.systemOrange)
                                            .withValues(alpha: 0.50),
                                        blurRadius: 12,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                    border: Border.all(color: Colors.white, width: 2.5),
                                  ),
                                  child: const Icon(
                                    Icons.my_location_rounded,
                                    size: 17,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── HUD SUPERIOR: BADGE DE ESTADO Y SELECTOR DE MAPA REAL ─────────
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge GPS Status con Coordenadas en vivo
                  _buildGlassBadge(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            final glow = 0.4 + (_pulseController.value * 0.6);
                            return Container(
                              width: 7.5,
                              height: 7.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (widget.hasFix ? AppColors.systemGreen : AppColors.systemOrange)
                                    .withValues(alpha: glow),
                                boxShadow: [
                                  BoxShadow(
                                    color: (widget.hasFix ? AppColors.systemGreen : AppColors.systemOrange)
                                        .withValues(alpha: glow * 0.9),
                                    blurRadius: 6,
                                    spreadRadius: 1.5,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 7),
                        Text(
                          widget.hasFix
                              ? 'GPS: ${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°'
                              : 'BUSCANDO SEÑAL GPS',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selector de Recursos de Mapas Reales
                  GestureDetector(
                    onTap: _cycleNextStyle,
                    child: _buildGlassBadge(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_selectedStyle.icon, size: 12.5, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            _selectedStyle.label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── DIÁLOGO FLOTANTE DE INFORMACIÓN AL TOCAR EL PIN ───────────────
            if (_showPinInfo)
              Positioned(
                bottom: 60,
                left: 14,
                right: 14,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user_rounded, size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.address ?? 'Sede Autorizada',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: context.cTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${lat.toStringAsFixed(5)}°, ${lng.toStringAsFixed(5)}° · Geocerca 60m',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: context.cTextSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new_rounded, size: 17, color: AppColors.primary),
                            onPressed: () => _openExternal(lat, lng),
                            tooltip: 'Abrir en Google Maps',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, size: 17, color: context.cTextSecondary),
                            onPressed: () => setState(() => _showPinInfo = false),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── HUD INFERIOR: CONTROLES DE ZOOM Y PANTALLA COMPLETA ───────────
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Botón Pantalla Completa
                  _buildGlassButton(
                    icon: Icons.fullscreen_rounded,
                    label: 'Explorar',
                    onTap: () => ExplorableMapDialog.show(
                      context,
                      latitude: lat,
                      longitude: lng,
                      hasFix: widget.hasFix,
                      address: widget.address,
                    ),
                  ),

                  // Barra Táctica de Zoom y Recentrado
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle Modo Interactivo / Bloqueo Scroll
                      _buildCircularGlassButton(
                        icon: _interactiveMode ? Icons.touch_app_rounded : Icons.pan_tool_outlined,
                        tooltip: _interactiveMode ? 'Arrastre activo' : 'Pellizco activo',
                        color: _interactiveMode ? AppColors.primary : Colors.white70,
                        onTap: () {
                          setState(() => _interactiveMode = !_interactiveMode);
                        },
                      ),
                      const SizedBox(width: 6),
                      // Zoom Out
                      _buildCircularGlassButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Alejar',
                        onTap: () {
                          if (_ready) {
                            _animatedMapMove(_mapController.camera.center, _mapController.camera.zoom - 0.8);
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      // Zoom In
                      _buildCircularGlassButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Acercar',
                        onTap: () {
                          if (_ready) {
                            _animatedMapMove(_mapController.camera.center, _mapController.camera.zoom + 0.8);
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      // Recentrar en GPS Real
                      _buildCircularGlassButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Centrar en mi GPS real',
                        color: AppColors.primary,
                        onTap: () => _animatedMapMove(point, 16.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);
  }

  Widget _buildGlassBadge({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 0.8,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: const Color(0xFF0F172A).withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color color = Colors.white,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: const Color(0xFF0F172A).withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Tooltip(
              message: tooltip ?? '',
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(icon, size: 16, color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
