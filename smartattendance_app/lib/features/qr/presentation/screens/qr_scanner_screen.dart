// lib/features/qr/presentation/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../history/presentation/viewmodels/history_viewmodel.dart';
import '../viewmodels/qr_viewmodel.dart';

/// QR Scanner screen — uses MobileScanner for real camera QR detection.
/// SRP: only handles camera view and QR detection callback.
class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController _cameraCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    _processCode(barcode.rawValue!);
  }

  /// Punto único de procesamiento: cámara y galería convergen aquí.
  void _processCode(String rawValue) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _cameraCtrl.stop();

    ref.read(qrViewModelProvider.notifier).validateQR(rawValue);
  }

  /// Galería real: escanea un QR desde una imagen del dispositivo.
  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    final XFile? image;
    try {
      image = await _picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      _showSnack('No se pudo acceder a la galería: $e');
      return;
    }
    if (image == null) return; // usuario canceló

    setState(() => _isProcessing = true);
    _cameraCtrl.stop();

    try {
      final capture = await _cameraCtrl.analyzeImage(image.path);
      final barcode = capture?.barcodes.firstOrNull;
      if (barcode == null || barcode.rawValue == null) {
        _showSnack('No se encontró ningún código QR en la imagen.');
        _resetProcessing();
        return;
      }
      ref.read(qrViewModelProvider.notifier).validateQR(barcode.rawValue!);
    } catch (e) {
      _showSnack('No se pudo analizar la imagen: $e');
      _resetProcessing();
    }
  }

  void _resetProcessing() {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ref.read(qrViewModelProvider.notifier).reset();
    _cameraCtrl.start();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.systemRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Ayuda real: instrucciones de uso.
  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ctx.cSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cómo usar el escáner',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const _HelpRow(
                icon: Icons.qr_code_scanner,
                text:
                    'Apunta la cámara al código QR que te entregue tu administrador.'),
            const SizedBox(height: 12),
            const _HelpRow(
                icon: Icons.photo_library,
                text:
                    'Usa "Galería" para escanear un QR desde una imagen guardada.'),
            const SizedBox(height: 12),
            const _HelpRow(
                icon: Icons.how_to_reg,
                text:
                    'Al validar, el sistema registra tu asistencia automáticamente.'),
            const SizedBox(height: 12),
            const _HelpRow(
                icon: Icons.verified_user,
                text:
                    'Cada código es de un solo uso y personal. No lo compartas.'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QRState>(qrViewModelProvider, (previous, next) {
      if (next is QRError) {
        _showSnack(next.message);
        Future.delayed(const Duration(seconds: 2), _resetProcessing);
      } else if (next is QRSuccess) {
        // Invalida el estado del historial para refrescar automáticamente el resumen del día
        ref.invalidate(historyViewModelProvider);

        // El servidor registró la asistencia y decidió el tipo (C1 + C2):
        // pasamos el resultado validado (tipo, fecha, hora) a la confirmación.
        final query = StringBuffer('?tipo=${next.tipo}');
        if (next.fechaRegistro != null && next.fechaRegistro!.isNotEmpty) {
          query.write('&fecha=${next.fechaRegistro}');
        }
        if (next.horaRegistro != null && next.horaRegistro!.isNotEmpty) {
          query.write('&hora=${next.horaRegistro}');
        }
        context.go('${AppRoutes.confirmation}$query');
        ref.read(qrViewModelProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera feed with real permission error handling
          MobileScanner(
            controller: _cameraCtrl,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Container(
                color: const Color(0xFF0F172A),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.systemRed.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.no_photography,
                          color: AppColors.systemRed,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Acceso a la cámara requerido',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'SmartAttendance requiere permisos de cámara para escanear el código QR de asistencia.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Geolocator.openAppSettings(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.settings, size: 20),
                        label: const Text('Abrir Ajustes de Permisos'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Gradient vignette
          const _Vignette(),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar (dark variant)
                _DarkTopBar(cameraCtrl: _cameraCtrl),

                const Spacer(),

                // ── Scanner window + corners
                Center(child: _ScannerWindow(isProcessing: _isProcessing)),

                const SizedBox(height: 20),
                // ── Instructions
                const _Instructions(),

                const Spacer(flex: 2),

                // ── Bottom controls
                _BottomControls(
                  onGallery: _pickFromGallery,
                  onHelp: _showHelp,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Vignette extends StatelessWidget {
  const _Vignette();
  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: .8,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: .6)
                ],
              ),
            ),
          ),
        ),
      );
}

class _DarkTopBar extends StatefulWidget {
  const _DarkTopBar({required this.cameraCtrl});
  final MobileScannerController cameraCtrl;

  @override
  State<_DarkTopBar> createState() => _DarkTopBarState();
}

class _DarkTopBarState extends State<_DarkTopBar> {
  bool _torchOn = false;
  bool _frontCamera = false;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          // Back
          _IconBtn(
            icon: Icons.arrow_back_ios_new,
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user,
                        size: 12, color: AppColors.systemGreen),
                    SizedBox(width: 4),
                    Text(
                      '${AppConfig.companyName} · VERIFICADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Escanear QR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Camera Switch
          _IconBtn(
            icon: Icons.cameraswitch,
            onPressed: () {
              widget.cameraCtrl.switchCamera();
              setState(() => _frontCamera = !_frontCamera);
            },
            active: _frontCamera,
          ),
          const SizedBox(width: 8),
          // Torch
          _IconBtn(
            icon: _torchOn ? Icons.flashlight_off : Icons.flashlight_on,
            onPressed: () {
              widget.cameraCtrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
            active: _torchOn,
          ),
        ]),
      );
}

class _IconBtn extends StatelessWidget {
  const _IconBtn(
      {required this.icon, required this.onPressed, this.active = false});
  final IconData icon;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppColors.primary.withValues(alpha: .6)
                : Colors.white.withValues(alpha: .12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );
}

class _ScannerWindow extends StatelessWidget {
  const _ScannerWindow({required this.isProcessing});
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * .68;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        // Corners
        ..._corners(size),
        // Center window
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: size - 4,
            height: size - 4,
            color: Colors.transparent,
          ),
        ),
        // Scan line animation
        if (!isProcessing)
          const _ScanLine()
        else
          const CircularProgressIndicator(color: Colors.white),
      ]),
    );
  }

  List<Widget> _corners(double size) {
    const side = 40.0;
    const bw = 4.0;
    const r = 12.0;
    const clr = AppColors.primary;

    return [
      const Positioned(
          top: 0,
          left: 0,
          child: _Corner(
              side: side,
              bw: bw,
              r: r,
              color: clr,
              position: _CornerPos.topLeft)),
      const Positioned(
          top: 0,
          right: 0,
          child: _Corner(
              side: side,
              bw: bw,
              r: r,
              color: clr,
              position: _CornerPos.topRight)),
      const Positioned(
          bottom: 0,
          left: 0,
          child: _Corner(
              side: side,
              bw: bw,
              r: r,
              color: clr,
              position: _CornerPos.bottomLeft)),
      const Positioned(
          bottom: 0,
          right: 0,
          child: _Corner(
              side: side,
              bw: bw,
              r: r,
              color: clr,
              position: _CornerPos.bottomRight)),
    ];
  }
}

enum _CornerPos { topLeft, topRight, bottomLeft, bottomRight }

class _Corner extends StatelessWidget {
  const _Corner({
    required this.side,
    required this.bw,
    required this.r,
    required this.color,
    required this.position,
  });

  final double side, bw, r;
  final Color color;
  final _CornerPos position;

  @override
  Widget build(BuildContext context) {
    final tl = position == _CornerPos.topLeft;
    final tr = position == _CornerPos.topRight;
    final bl = position == _CornerPos.bottomLeft;
    return SizedBox(
      width: side,
      height: side,
      child: CustomPaint(
          painter: _CornerPainter(
        color: color,
        bw: bw,
        r: r,
        top: tl || tr,
        left: tl || bl,
      )),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(
      {required this.color,
      required this.bw,
      required this.r,
      required this.top,
      required this.left});

  final Color color;
  final double bw, r;
  final bool top, left;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = bw
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? r : -r;
    final dy = top ? r : -r;

    path.moveTo(x + dx, y);
    path.lineTo(x, y);
    path.lineTo(x, y + dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (ctx, box) {
        return AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Positioned(
            top: _anim.value * (box.maxHeight - 2),
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.primary,
                    Colors.transparent
                  ],
                ),
                boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 8)],
              ),
            ),
          ),
        );
      });
}

class _Instructions extends StatelessWidget {
  const _Instructions();
  @override
  Widget build(BuildContext context) => Column(children: [
        const Text(
          'Apunta la cámara al código QR de ${AppConfig.companyName}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.systemGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Detección automática en tiempo real',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .65),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ]);
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.onGallery,
    required this.onHelp,
  });

  final VoidCallback onGallery;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _CtrlBtn(
                icon: Icons.photo_library, label: 'Galería', onTap: onGallery),
            const SizedBox(width: 24),
            _CtrlBtn(icon: Icons.info, label: 'Ayuda', onTap: onHelp),
          ]),
          const SizedBox(height: 16),
          Container(
              width: 120,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .28),
                  borderRadius: BorderRadius.circular(999))),
        ],
      );
}

class _CtrlBtn extends StatelessWidget {
  const _CtrlBtn(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: .2)),
                  color: Colors.white.withValues(alpha: .08)),
              child: Icon(icon, color: Colors.white.withValues(alpha: .75))),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
        ]),
      );
}

/// Fila de ayuda: ícono + texto.
class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 14, color: context.cTextPrimary)),
          ),
        ],
      );
}
