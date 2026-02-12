import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import '../common/app_dialogs.dart';
import '../../config/app_routes.dart';
import 'ocr_viewmodel.dart';

class CameraOcrScreen extends StatefulWidget {
  const CameraOcrScreen({super.key});

  @override
  State<CameraOcrScreen> createState() => _CameraOcrScreenState();
}

class _CameraOcrScreenState extends State<CameraOcrScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? cameras;
  int _selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;
  String? _errorMessage;

  bool _isProcessing = false;
  bool _isPreviewFrozen = false;

  final GlobalKey _cameraFrameKey = GlobalKey();
  final GlobalKey _boundingBoxKey = GlobalKey();

  Timer? _inactivityTimer;
  static const int _timeoutSeconds = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    _initCamera();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    _inactivityTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_selectedCameraIndex);
    }
  }

  void _resetInactivityTimer([_]) {
    _inactivityTimer?.cancel();
    if (mounted && !_isProcessing) {
      _startInactivityTimer();
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer = Timer(const Duration(seconds: _timeoutSeconds), () {
      if (mounted) {
        Navigator.of(context).pop("TIMEOUT_BY_SYSTEM");
      }
    });
  }

  Future<void> _initCamera([int cameraIndex = 0]) async {
    final ocrViewModel = context.read<OcrViewModel>();

    if (Platform.isAndroid || Platform.isIOS) {
      final hasPermission = await ocrViewModel.checkCameraPermission();
      if (!hasPermission) {
        if (mounted) setState(() => _errorMessage = "Izin kamera diperlukan.");
        return;
      }
    }

    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        if (mounted) setState(() => _errorMessage = "Kamera tidak ditemukan.");
        return;
      }

      _selectedCameraIndex = (cameraIndex >= 0 && cameraIndex < cameras!.length)
          ? cameraIndex
          : 0;

      _controller = CameraController(
        cameras![_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888,
      );

      _initializeControllerFuture = _controller!.initialize().then((_) {
        if (mounted) {
          if (Platform.isAndroid || Platform.isIOS) {
            _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
          }
          setState(() {});
        }
      });
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Gagal: $e");
    }
  }

  Future<void> _takePicture() async {
    _inactivityTimer?.cancel();

    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    final ocrViewModel = context.read<OcrViewModel>();
    ocrViewModel.resetState();

    try {
      setState(() {
        _isProcessing = true;
        _isPreviewFrozen = true;
      });
      await _controller?.pausePreview();

      final XFile imageFile = await _controller!.takePicture();

      if (!mounted) return;

      final Uint8List? croppedBytes = await _cropImage(imageFile);

      if (!mounted) return;

      if (croppedBytes != null) {
        await ocrViewModel.scanImage(croppedBytes);

        if (!mounted) return;

        if (ocrViewModel.state == OcrState.successFound) {
          final serverMsg = ocrViewModel.message ?? "Info aset tersedia.";
          final assetNum = ocrViewModel.foundAssetNumber ?? "-";

          showConfirmationDialog(
            context,
            "Hasil Scan",
            "$serverMsg\nLihat detail?",
            () {
              Navigator.pushNamed(
                context,
                AppRoutes.assetDetail,
                arguments: assetNum,
              ).then((_) {
                _resumeCamera();
              });
            },
            onCancel: () {
              _resumeCamera();
            },
          );
        } else if (ocrViewModel.state == OcrState.successNotFound) {
          showErrorDialog(
            context,
            ocrViewModel.message ?? "Aset tidak dikenali.",
            onOkPressed: _resumeCamera,
          );
        } else if (ocrViewModel.state == OcrState.error) {
          showErrorDialog(
            context,
            ocrViewModel.message ?? "Terjadi kesalahan.",
            onOkPressed: _resumeCamera,
          );
        }
      } else {
        showErrorDialog(
          context,
          "Gagal memproses gambar.",
          onOkPressed: _resumeCamera,
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          "Error sistem: $e",
          onOkPressed: _resumeCamera,
        );
      } else {
        _resumeCamera();
      }
    }
  }

  Future<Uint8List?> _cropImage(XFile imageFile) async {
    final imageBytes = await imageFile.readAsBytes();

    if (!mounted) return null;

    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) return null;

    bool isMobile = Platform.isAndroid || Platform.isIOS;
    if (isMobile && originalImage.width > originalImage.height) {
      originalImage = img.copyRotate(originalImage, angle: 90);
    }

    try {
      final RenderBox? cameraBox =
          _cameraFrameKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? cropBox =
          _boundingBoxKey.currentContext?.findRenderObject() as RenderBox?;

      if (cameraBox == null || cropBox == null) return null;

      final frameSize = cameraBox.size;
      final cropSize = cropBox.size;

      final offset = cameraBox.globalToLocal(
        cropBox.localToGlobal(Offset.zero),
      );

      final double scaleX = originalImage.width / frameSize.width;
      final double scaleY = originalImage.height / frameSize.height;

      final int x = (offset.dx * scaleX).toInt();
      final int y = (offset.dy * scaleY).toInt();
      final int w = (cropSize.width * scaleX).toInt();
      final int h = (cropSize.height * scaleY).toInt();

      final img.Image cropped = img.copyCrop(
        originalImage,
        x: x,
        y: y,
        width: w,
        height: h,
      );

      return Uint8List.fromList(img.encodeJpg(cropped));
    } catch (e) {
      debugPrint("Crop Error: $e");
      return imageBytes;
    }
  }

  void _resumeCamera() {
    if (mounted && _controller != null) {
      setState(() {
        _isProcessing = false;
        _isPreviewFrozen = false;
      });
      _controller!.resumePreview();
      _resetInactivityTimer();
    }
  }

  void _flipCamera() {
    _resetInactivityTimer();
    if (cameras == null || _isProcessing) return;

    if (cameras!.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hanya satu kamera terdeteksi."),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final newIndex = (_selectedCameraIndex + 1) % cameras!.length;
    _initCamera(newIndex);
  }

  void _toggleFlash() {
    _resetInactivityTimer();
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      _currentFlashMode = (_currentFlashMode == FlashMode.off)
          ? FlashMode.torch
          : FlashMode.off;
    });
    _controller!.setFlashMode(_currentFlashMode);
  }

  IconData _getFlashIcon() {
    return _currentFlashMode == FlashMode.torch
        ? Icons.flash_on
        : Icons.flash_off;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _resetInactivityTimer,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            titleSpacing: 0,
            title: const Text(
              'Scan Aset',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: _isProcessing
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(4.0),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.greenAccent,
                      ),
                    ),
                  )
                : null,
          ),
          body: Column(
            children: [
              Expanded(
                child: FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (_errorMessage != null) {
                      return Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.done &&
                        _controller != null &&
                        _controller!.value.isInitialized) {
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black,
                        child: _buildCameraPreview(),
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                  },
                ),
              ),
              Container(
                width: double.infinity,
                color: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (Platform.isWindows)
                        const SizedBox(width: 48)
                      else
                        IconButton(
                          icon: Icon(
                            _getFlashIcon(),
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _isProcessing ? null : _toggleFlash,
                        ),
                      GestureDetector(
                        onTap: _isProcessing ? null : _takePicture,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isProcessing
                                ? Colors.grey[800]
                                : Colors.white,
                            border: Border.all(
                              color: _isProcessing
                                  ? Colors.grey
                                  : Colors.grey.shade400,
                              width: 4,
                            ),
                          ),
                          child: _isProcessing
                              ? const Padding(
                                  padding: EdgeInsets.all(18.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.flip_camera_ios,
                          color: (cameras != null && cameras!.length > 1)
                              ? Colors.white
                              : Colors.white38,
                          size: 28,
                        ),
                        onPressed: (_isProcessing) ? null : _flipCamera,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox();
    }

    final previewSize = _controller!.value.previewSize!;

    bool isMobile = Platform.isAndroid || Platform.isIOS;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: isMobile ? previewSize.height : previewSize.width,
              height: isMobile ? previewSize.width : previewSize.height,
              child: CameraPreview(_controller!),
            ),
          ),
        ),
        SizedBox.expand(
          key: _cameraFrameKey,
          child: Container(color: Colors.transparent),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text(
                  "Arahkan kamera ke kode aset",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
              Container(
                key: _boundingBoxKey,
                width: 280,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isPreviewFrozen)
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),
      ],
    );
  }
}
