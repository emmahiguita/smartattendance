// lib/features/photo_attendance/presentation/photo_capture_screen.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/router/app_router.dart';
import '../data/capture_draft.dart';
import '../domain/attendance_location.dart';
import '../domain/photo_record.dart';
import 'biometric_viewfinder.dart';
import 'capture_controls.dart';
import 'local_providers.dart';
import 'worker_assignment_dialog.dart';

/// ============================================================================
/// PANTALLA: PhotoCaptureScreen (Reconocimiento Facial en Vivo y Marcación)
/// ============================================================================
/// QUÉ HACE:
/// Integra el sensor de cámara frontal en tiempo real dentro del visor de la app
/// con retícula biométrica Face ID, valida presencia con Google ML Kit,
/// obtiene coordenadas GPS reales y confirma el registro con animación.
/// ============================================================================
class PhotoCaptureScreen extends ConsumerStatefulWidget {
  const PhotoCaptureScreen({
    super.key,
    required this.worker,
    this.initialPath,
    this.initialType = 'entrada',
    this.initialCaptureId,
  });

  final LocalWorker worker;
  final String? initialPath;
  final String initialType;
  final String? initialCaptureId;

  @override
  ConsumerState<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends ConsumerState<PhotoCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraCtrl;
  bool _isInitializingCamera = false;
  String? _path, _stage, _error, _coords;
  bool _busy = false, _faceOk = false;
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

    if (!_recovered) {
      _initCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraCtrl?.dispose();
      _cameraCtrl = null;
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
      if (cameras.isEmpty) {
        if (mounted) setState(() => _isInitializingCamera = false);
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _cameraCtrl = ctrl;
        _isInitializingCamera = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isInitializingCamera = false);
    }
  }

  void _setStage(String text) {
    if (mounted) setState(() => _stage = text);
  }

  Future<void> _captureAndVerify() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final repo = ref.read(localPhotoRepositoryProvider);
    final gpsSource = ref.read(localLocationSourceProvider);
    final type = widget.initialType;

    try {
      await repo.prepare(widget.worker);
      _setStage('Iniciando sensor GPS…');
      final Future<AttendanceLocation> gpsTask = (await gpsSource.ready())
          ? (gpsSource.capture()..ignore())
          : Future.value(await gpsSource.capture());

      // 1. Obtener fotografía (Cámara embebida en vivo o selector)
      if (_path == null) {
        if (_cameraCtrl != null && _cameraCtrl!.value.isInitialized) {
          _setStage('Capturando rostro…');
          final xfile = await _cameraCtrl!.takePicture();
          _path = xfile.path;
        } else {
          _setStage('Abriendo cámara…');
          final photo = await ImagePicker().pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.front,
            imageQuality: 85,
            maxWidth: 1280,
            maxHeight: 1280,
          );
          if (photo == null) throw const FormatException('Captura cancelada.');
          _path = photo.path;
        }
        await _draft.write(widget.worker, type, _path, _captureId);
        if (mounted) setState(() {});
      }

      // 2. Validación facial en el dispositivo con Google ML Kit
      _setStage('Verificando rostro…');
      await ref.read(localFaceVerifierProvider).verify(_path!);
      if (mounted) setState(() => _faceOk = true);

      // 3. Resolución de coordenadas GPS
      _setStage('Obteniendo coordenadas GPS…');
      final gps = await gpsTask;
      _coords = gps.description;

      // 4. Persistencia en la base de datos
      _setStage('Guardando asistencia…');
      await repo.capture(widget.worker, type, _path!, location: gps, captureId: _captureId);
      await _draft.clear();

      if (!mounted) return;

      // 5. Navegación a pantalla de confirmación oficial
      final now = DateTime.now();
      final fechaStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final horaStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      context.go('${AppRoutes.confirmation}?tipo=$type&fecha=$fechaStr&hora=$horaStr');
    } on FormatException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _path = null; // Regresa al visor de cámara en vivo para reintentar
          _faceOk = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo completar la marcación. Revisa permisos de cámara y ubicación.';
          _path = null;
          _faceOk = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _stage = null;
        });
      }
    }
  }

  Future<void> _configureWorker() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WorkerAssignmentDialog(worker: widget.worker),
    );
    if (saved == true && mounted) await _captureAndVerify();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(localActorProvider).isAdmin;
    final canSubmit = !_busy &&
        !_isInitializingCamera &&
        (_path != null ||
            _recovered ||
            _error != null ||
            (_cameraCtrl != null && _cameraCtrl!.value.isInitialized));

    final controls = CaptureControls(
      worker: widget.worker,
      type: widget.initialType,
      busy: _busy,
      stage: _stage,
      error: _error,
      coords: _coords,
      recovered: _recovered,
      onRetry: canSubmit ? _captureAndVerify : null,
      onConfigureWorker: isAdmin ? _configureWorker : null,
      onConfigureZones: isAdmin ? () => context.push(AppRoutes.settings) : null,
    );

    return PopScope(
      canPop: !_busy,
      onPopInvokedWithResult: (didPop, _) => didPop ? _draft.clear() : null,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registro Facial'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, size) {
            final preview = BiometricViewfinder(
              cameraController: _cameraCtrl,
              imagePath: _path,
              busy: _busy,
              verified: _faceOk,
              hasError: _error != null,
              isInitializingCamera: _isInitializingCamera,
              onTap: _busy ? null : _captureAndVerify,
            );

            if (size.maxWidth >= 600) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: size.maxHeight - 24),
                      child: preview,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: SingleChildScrollView(child: controls)),
                ]),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(children: [preview, const SizedBox(height: 16), controls]),
            );
          }),
        ),
      ),
    );
  }
}
