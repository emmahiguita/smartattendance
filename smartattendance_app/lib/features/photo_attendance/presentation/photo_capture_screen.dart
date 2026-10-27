// ============================================================================
// ARCHIVO: photo_capture_screen.dart
// QUÉ HACE: Pantalla de reconocimiento facial en vivo integrada en la app y
//           validación de geocerca GPS real antes de registrar marcaciones.
// CÓMO FUNCIONA: Inicializa `CameraController` frontal directamente en el visor
//                (`BiometricViewfinder`) sin abrir cámaras externas, y ejecuta
//                `ML Kit FaceDetector` + `Geolocator` en paralelo.
// POR QUÉ: Cumple SRP (< 180 líneas), corrige el bug de ciclo de vida en
//          `resumed` y garantiza captura 100% integrada estilo iOS.
// ============================================================================

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/router/app_router.dart';
import '../data/capture_draft.dart';
import '../domain/attendance_location.dart';
import '../domain/photo_record.dart';
import 'biometric_viewfinder.dart';
import 'capture_controls.dart';
import 'local_providers.dart';
import 'worker_assignment_dialog.dart';

class PhotoCaptureScreen extends ConsumerStatefulWidget {
  const PhotoCaptureScreen({
    super.key,
    required this.worker,
    this.initialPath,
    this.initialType = 'entrada',
    this.initialCaptureId,
  });

  final LocalWorker worker;
  final String? initialPath, initialCaptureId;
  final String initialType;

  @override
  ConsumerState<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends ConsumerState<PhotoCaptureScreen> with WidgetsBindingObserver {
  CameraController? _cameraCtrl;
  bool _isInitializingCamera = false, _busy = false, _faceOk = false;
  String? _path, _stage, _error, _coords;
  late bool _recovered;
  late final String _captureId;
  final _draft = CaptureDraft();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _path = widget.initialPath;
    _recovered = widget.initialPath != null;
    _captureId = widget.initialCaptureId ?? const Uuid().v4();
    if (!_recovered) _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      final ctrl = _cameraCtrl;
      _cameraCtrl = null;
      ctrl?.dispose();
    } else if (state == AppLifecycleState.resumed && _path == null) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraCtrl?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    if (_isInitializingCamera) return;
    setState(() => _isInitializingCamera = true);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
      final ctrl = CameraController(front, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() => _cameraCtrl = ctrl);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isInitializingCamera = false);
    }
  }

  Future<void> _captureAndVerify() async {
    if (_busy) return;
    setState(() => (_busy = true, _error = null));
    final repo = ref.read(localPhotoRepositoryProvider);
    final gpsSource = ref.read(localLocationSourceProvider);
    final type = widget.initialType;

    try {
      await repo.prepare(widget.worker);
      setState(() => _stage = 'Obteniendo coordenadas GPS…');
      final Future<AttendanceLocation> gpsTask = (await gpsSource.ready())
          ? (gpsSource.capture()..ignore())
          : Future.value(await gpsSource.capture());

      if (_path == null) {
        if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) await _initCamera();
        if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) {
          throw const FormatException('Cámara frontal no disponible. Intenta de nuevo.');
        }
        setState(() => _stage = 'Capturando biometría facial…');
        _path = (await _cameraCtrl!.takePicture()).path;
        await _draft.write(widget.worker, type, _path, _captureId);
      }

      setState(() => _stage = 'Verificando rostro con ML Kit…');
      await ref.read(localFaceVerifierProvider).verify(_path!);
      if (mounted) setState(() => _faceOk = true);

      setState(() => _stage = 'Validando geocerca GPS…');
      final gps = await gpsTask;
      _coords = gps.description;

      setState(() => _stage = 'Registrando asistencia…');
      await repo.capture(widget.worker, type, _path!, location: gps, captureId: _captureId);
      await _draft.clear();
      if (!mounted) return;

      final n = DateTime.now();
      final f = '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
      final h = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
      context.go('${AppRoutes.confirmation}?tipo=$type&fecha=$f&hora=$h');
    } on FormatException catch (e) {
      if (mounted) setState(() => (_error = e.message, _path = null, _faceOk = false));
    } catch (_) {
      if (mounted) setState(() => (_error = 'No se pudo completar la marcación. Verifica cámara y GPS.', _path = null, _faceOk = false));
    } finally {
      if (mounted) setState(() => (_busy = false, _stage = null));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(localActorProvider).isAdmin;
    final preview = BiometricViewfinder(
      cameraController: _cameraCtrl,
      imagePath: _path,
      busy: _busy,
      verified: _faceOk,
      hasError: _error != null,
      isInitializingCamera: _isInitializingCamera,
      onTap: _busy ? null : _captureAndVerify,
    );
    final controls = CaptureControls(
      worker: widget.worker,
      type: widget.initialType,
      busy: _busy,
      stage: _stage,
      error: _error,
      coords: _coords,
      recovered: _recovered,
      onRetry: !_busy ? _captureAndVerify : null,
      onConfigureWorker: isAdmin ? () => showDialog<bool>(context: context, builder: (_) => WorkerAssignmentDialog(worker: widget.worker)) : null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Verificación Biométrica'), centerTitle: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, size) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: size.maxWidth >= 600
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: preview), const SizedBox(width: 20), Expanded(child: controls)])
                : Column(children: [preview, const SizedBox(height: 14), controls]),
          ),
        ),
      ),
    );
  }
}
