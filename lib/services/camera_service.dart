import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isRecording = false;
  int _currentCameraIndex = 0;

  // Initialize camera service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request camera permission
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission != PermissionStatus.granted) {
        throw CameraException('Camera permission denied');
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('No cameras available');
      }

      // Initialize with back camera (index 0 is usually back camera)
      await _initializeCamera(_currentCameraIndex);
      _isInitialized = true;
    } catch (e) {
      throw CameraException('Failed to initialize camera: $e');
    }
  }

  // Initialize specific camera
  Future<void> _initializeCamera(int cameraIndex) async {
    if (cameraIndex >= _cameras.length) {
      throw CameraException('Invalid camera index');
    }

    // Dispose previous controller
    await _controller?.dispose();

    // Create new controller
    _controller = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Initialize controller
    await _controller!.initialize();
  }

  // Switch between front and back camera
  Future<void> switchCamera() async {
    if (!_isInitialized || _cameras.length < 2) return;

    try {
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
      await _initializeCamera(_currentCameraIndex);
    } catch (e) {
      throw CameraException('Failed to switch camera: $e');
    }
  }

  // Take a picture
  Future<File> takePicture() async {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      throw CameraException('Camera not initialized');
    }

    try {
      final XFile picture = await _controller!.takePicture();
      return File(picture.path);
    } catch (e) {
      throw CameraException('Failed to take picture: $e');
    }
  }

  // Start image stream for real-time processing
  Future<void> startImageStream(Function(CameraImage) onImageAvailable) async {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      throw CameraException('Camera not initialized');
    }

    try {
      await _controller!.startImageStream(onImageAvailable);
    } catch (e) {
      throw CameraException('Failed to start image stream: $e');
    }
  }

  // Stop image stream
  Future<void> stopImageStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        await _controller!.stopImageStream();
      } catch (e) {
        throw CameraException('Failed to stop image stream: $e');
      }
    }
  }

  // Set flash mode
  Future<void> setFlashMode(FlashMode flashMode) async {
    if (!_isInitialized || _controller == null) return;

    try {
      await _controller!.setFlashMode(flashMode);
    } catch (e) {
      throw CameraException('Failed to set flash mode: $e');
    }
  }

  // Set zoom level
  Future<void> setZoomLevel(double zoom) async {
    if (!_isInitialized || _controller == null) return;

    try {
      final maxZoom = await _controller!.getMaxZoomLevel();
      final minZoom = await _controller!.getMinZoomLevel();
      final clampedZoom = zoom.clamp(minZoom, maxZoom);
      await _controller!.setZoomLevel(clampedZoom);
    } catch (e) {
      throw CameraException('Failed to set zoom level: $e');
    }
  }

  // Get current zoom level
  Future<double> getZoomLevel() async {
    if (!_isInitialized || _controller == null) return 1.0;

    try {
      // Note: getZoomLevel() might not be available in all camera versions
      // Return default zoom level for now
      return 1.0;
    } catch (e) {
      return 1.0;
    }
  }

  // Get max zoom level
  Future<double> getMaxZoomLevel() async {
    if (!_isInitialized || _controller == null) return 1.0;
    
    try {
      return await _controller!.getMaxZoomLevel();
    } catch (e) {
      return 1.0;
    }
  }

  // Convert CameraImage to bytes for processing
  Uint8List convertCameraImageToBytes(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      return allBytes.done().buffer.asUint8List();
    } catch (e) {
      throw CameraException('Failed to convert camera image: $e');
    }
  }

  // Save image to gallery
  Future<File> saveImageToGallery(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'snap_translate_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${directory.path}/$fileName');
      return savedImage;
    } catch (e) {
      throw CameraException('Failed to save image: $e');
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: AppConstants.maxImageWidth.toDouble(),
        maxHeight: AppConstants.maxImageHeight.toDouble(),
        imageQuality: 85,
      );
      
      return image != null ? File(image.path) : null;
    } catch (e) {
      throw CameraException('Failed to pick image from gallery: $e');
    }
  }

  // Get camera preview widget
  Widget getCameraPreview() {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return CameraPreview(_controller!);
  }

  // Check if camera is available
  bool get isAvailable => _isInitialized && _controller != null && _controller!.value.isInitialized;

  // Check if camera is recording
  bool get isRecording => _isRecording;

  // Get current camera description
  CameraDescription? get currentCamera => 
      _cameras.isNotEmpty ? _cameras[_currentCameraIndex] : null;

  // Get camera controller
  CameraController? get controller => _controller;

  // Get available cameras count
  int get availableCamerasCount => _cameras.length;

  // Check if front camera is available
  bool get hasFrontCamera => _cameras.any((camera) => camera.lensDirection == CameraLensDirection.front);

  // Check if back camera is available
  bool get hasBackCamera => _cameras.any((camera) => camera.lensDirection == CameraLensDirection.back);

  // Get current flash mode
  FlashMode get currentFlashMode => _controller?.value.flashMode ?? FlashMode.off;

  // Check if flash is available
  bool get hasFlash => currentCamera?.lensDirection == CameraLensDirection.back;

  // Dispose camera resources
  Future<void> dispose() async {
    try {
      await stopImageStream();
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _isRecording = false;
    } catch (e) {
      // Ignore disposal errors
    }
  }

  // Pause camera
  Future<void> pausePreview() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.pausePreview();
      } catch (e) {
        // Ignore pause errors
      }
    }
  }

  // Resume camera
  Future<void> resumePreview() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.resumePreview();
      } catch (e) {
        // Ignore resume errors
      }
    }
  }
}

// Camera Exception
class CameraException implements Exception {
  final String message;
  const CameraException(this.message);
  
  @override
  String toString() => 'CameraException: $message';
}
