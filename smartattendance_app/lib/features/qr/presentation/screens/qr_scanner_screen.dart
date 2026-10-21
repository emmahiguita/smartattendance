// lib/features/qr/presentation/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../history/presentation/viewmodels/history_viewmodel.dart';
import '../viewmodels/qr_viewmodel.dart';
import '../widgets/qr_camera_error_view.dart';
import '../widgets/qr_scanner_bottom_controls.dart';
import '../widgets/qr_scanner_help_sheet.dart';
import '../widgets/qr_scanner_top_bar.dart';
import '../widgets/qr_scanner_window.dart';

/// ============================================================================
/// PANTALLA: QRScannerScreen
/// ============================================================================
/// QUÉ HACE:
/// Escanea códigos QR en tiempo real mediante la cámara del dispositivo móvil
/// o a través de imágenes cargadas desde la galería de fotos.
///
/// CONTROL DE CICLO DE VIDA (ZOMBIE PROCESS PREVENTION):
/// - Implementa WidgetsBindingObserver para pausar la cámara cuando la app
///   pasa a segundo plano y reanudarla al regresar, evitando fugas de memoria.
/// - Invoca _cameraCtrl.dispose() religiosamente en el método dispose().
///
/// PRINCIPIOS SOLID APLICADOS:
/// - S (Single Responsibility): Coordina el flujo de detección y navegación.
/// ============================================================================
class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _cameraCtrl;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraCtrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraCtrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraCtrl.stop();
    } else if (state == AppLifecycleState.resumed && !_isProcessing) {
      _cameraCtrl.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraCtrl.dispose();
    super.dispose();
  }

  /// Procesa el valor escaneado asegurando idempotencia (evita doble disparo)
  void _processCode(String rawValue) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _cameraCtrl.stop();
    ref.read(qrViewModelProvider.notifier).validateQR(rawValue.trim());
  }

  /// Escanea un QR existente desde una foto seleccionada en la galería
  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isProcessing = true);
      _cameraCtrl.stop();

      final capture = await _cameraCtrl.analyzeImage(image.path);
      final barcode = capture?.barcodes.firstOrNull;
      if (barcode == null || barcode.rawValue == null) {
        _showSnack('No se detectó un código QR válido en la imagen.');
        _resetProcessing();
        return;
      }
      ref.read(qrViewModelProvider.notifier).validateQR(barcode.rawValue!.trim());
    } catch (e) {
      _showSnack('Error al procesar la imagen: $e');
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
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: AppColors.systemRed,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    // Escucha el resultado de la validación
    ref.listen<QRState>(qrViewModelProvider, (_, next) {
      if (next is QRError) {
        _showSnack(next.message);
        Future.delayed(const Duration(seconds: 2), _resetProcessing);
      } else if (next is QRSuccess) {
        ref.invalidate(historyViewModelProvider);
        final query = StringBuffer('?tipo=${next.tipo}');
        if (next.fechaRegistro != null) query.write('&fecha=${next.fechaRegistro}');
        if (next.horaRegistro != null) query.write('&hora=${next.horaRegistro}');
        context.go('${AppRoutes.confirmation}$query');
        ref.read(qrViewModelProvider.notifier).reset();
      }
    });

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Visor nativo de cámara
          MobileScanner(
            controller: _cameraCtrl,
            onDetect: (cap) {
              final code = cap.barcodes.firstOrNull?.rawValue;
              if (code != null) _processCode(code);
            },
            errorBuilder: (_, err, __) => const QrCameraErrorView(onOpenSettings: Geolocator.openAppSettings),
          ),

          // 2. Viñeta estética oscura para contraste visual
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.85,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                  ),
                ),
              ),
            ),
          ),

          // 3. Capa de interfaz de usuario
          SafeArea(
            child: Column(
              children: [
                QrScannerTopBar(cameraCtrl: _cameraCtrl),
                const Spacer(),
                Center(child: QrScannerWindow(isProcessing: _isProcessing)),
                if (!isLandscape) const Spacer(flex: 2),
                QrScannerBottomControls(
                  onGallery: _pickFromGallery,
                  onHelp: () => QrScannerHelpSheet.show(context),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
