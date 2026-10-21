// lib/features/attendance/presentation/widgets/explorable_map_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'realtime_map_viewer.dart';

/// ============================================================================
/// COMPONENTE: ExplorableMapDialog (Explorador Cartográfico Inmersivo)
/// ============================================================================
/// Modal de pantalla casi completa con soporte para:
/// - Recursos de mapas reales: OpenStreetMap oficial y Satélite Esri ArcGIS.
/// - Gestos 100% interactivos (arrastre, pellizco, inercia, rotación bloqueada).
/// - Animación continua de radar/sonar sobre la geocerca real de 60m.
/// - Desplazamiento cinematográfico para zoom y recentrado en GPS.
/// ============================================================================
class ExplorableMapDialog extends StatefulWidget {
  final double latitude, longitude;
  final bool hasFix;
  final String? address;

  const ExplorableMapDialog({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.hasFix,
    this.address,
  });

  static Future<void> show(
    BuildContext context, {
    required double latitude,
    required double longitude,
    required bool hasFix,
    String? address,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ExplorableMapDialog(
        latitude: latitude,
        longitude: longitude,
        hasFix: hasFix,
        address: address,
      ),
    );
  }

  @override
  State<ExplorableMapDialog> createState() => _ExplorableMapDialogState();
}

class _ExplorableMapDialogState extends State<ExplorableMapDialog> with TickerProviderStateMixin {
  final MapController _controller = MapController();
  late final AnimationController _pulseController;
  AnimationController? _cameraController;
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
    _controller.dispose();
    super.dispose();
  }

  void _animatedMove(LatLng destLocation, double destZoom) {
    _cameraController?.dispose();
    final camera = _controller.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _cameraController = controller;
    final anim = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _controller.move(
        LatLng(latTween.evaluate(anim), lngTween.evaluate(anim)),
        zoomTween.evaluate(anim),
      );
    });
    controller.forward();
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final point = LatLng(widget.latitude, widget.longitude);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            // Header del diálogo con coordenadas reales
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (widget.hasFix ? AppColors.primary : AppColors.systemOrange).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.hasFix ? Icons.near_me_rounded : Icons.search_rounded,
                      size: 16,
                      color: widget.hasFix ? AppColors.primary : AppColors.systemOrange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.address ?? 'Explorador GPS en Tiempo Real',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: context.cTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.latitude.toStringAsFixed(5)}°, ${widget.longitude.toStringAsFixed(5)}° · Geocerca 60m',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.cTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Visor de mapa inmersivo con recursos de mapa reales
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _controller,
                    options: MapOptions(
                      initialCenter: point,
                      initialZoom: 16.5,
                      minZoom: 4,
                      maxZoom: 19.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      // Capa Real (OpenStreetMap / Satélite Esri / GIS)
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
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final progress = _pulseController.value;
                          final innerRadius = 20.0 + (progress * 35.0);
                          final innerAlpha = (1.0 - progress) * 0.40;
                          final outerRadius = 35.0 + (progress * 55.0);
                          final outerAlpha = (1.0 - progress) * 0.25;

                          return CircleLayer(
                            circles: [
                              CircleMarker(
                                point: point,
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderColor: AppColors.primary.withValues(alpha: 0.75),
                                borderStrokeWidth: 2.0,
                                useRadiusInMeter: true,
                                radius: 60,
                              ),
                              CircleMarker(
                                point: point,
                                color: AppColors.primary.withValues(alpha: innerAlpha * 0.55),
                                borderColor: AppColors.primary.withValues(alpha: innerAlpha),
                                borderStrokeWidth: 1.5,
                                useRadiusInMeter: true,
                                radius: innerRadius,
                              ),
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
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: 54,
                            height: 54,
                            child: Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: widget.hasFix
                                        ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                                        : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                                  ),
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.my_location_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Selector de estilo de mapa real flotante
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: MapCartoStyle.values.map((s) {
                          final selected = s == _selectedStyle;
                          return InkWell(
                            onTap: () => setState(() => _selectedStyle = s),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    s.icon,
                                    size: 13,
                                    color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    s.label,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                      color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Botones tácticos de navegación y zoom
                  Positioned(
                    right: 14,
                    bottom: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _btn(
                          icon: Icons.add_rounded,
                          tooltip: 'Acercar',
                          onTap: () => _animatedMove(_controller.camera.center, _controller.camera.zoom + 1.0),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _btn(
                          icon: Icons.remove_rounded,
                          tooltip: 'Alejar',
                          onTap: () => _animatedMove(_controller.camera.center, _controller.camera.zoom - 1.0),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _btn(
                          icon: Icons.my_location_rounded,
                          tooltip: 'Centrar en mi posición GPS',
                          onTap: () => _animatedMove(point, 16.5),
                          isDark: isDark,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        _btn(
                          icon: Icons.open_in_new_rounded,
                          tooltip: 'Abrir en Google Maps',
                          onTap: _openExternal,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    String? tooltip,
    Color? color,
  }) {
    return Material(
      color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: tooltip ?? '',
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                width: 0.8,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 18,
                color: color ?? (isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
