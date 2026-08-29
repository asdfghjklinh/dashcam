import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:geolocator/geolocator.dart';

import 'package:dashcam/features/dashcam/data/models/vehicle_distance.dart';
import 'package:dashcam/core/constants/distance_thresholds.dart';

class DashcamController extends ChangeNotifier {
  CameraController? _cameraController;
  ObjectDetector? _objectDetector;
  StreamSubscription<Position>? _positionStreamSubscription;

  bool _isInitializing = false;
  bool _isProcessingImage = false;
  bool _isRecording = false;

  // State Variables
  List<VehicleDistance> _detectedVehicles = [];
  double _currentSpeedKmH = 0.0;
  double _totalDistanceMeters = 0.0;
  Position? _lastPosition;
  bool _showDistanceOverlay = true;

  // Getters
  CameraController? get cameraController => _cameraController;
  List<VehicleDistance> get detectedVehicles => _detectedVehicles;
  double get currentSpeedKmH => _currentSpeedKmH;
  double get totalDistanceMeters => _totalDistanceMeters;
  double get totalDistanceM => _totalDistanceMeters;
  bool get showDistanceOverlay => _showDistanceOverlay;
  bool get isRecording => _isRecording;

  bool get isInitialized =>
      _cameraController != null &&
          _cameraController!.value.isInitialized &&
          !_isInitializing;

  bool get isCameraReady => isInitialized;

  /// Khởi tạo camera ban đầu
  Future<void> initialize() async {
    await _initObjectDetector();
    await _initLocationService();
    await _initCamera();
  }

  Future<void> _initObjectDetector() async {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  /// Khởi tạo Camera
  Future<void> _initCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // Cho phép UI hệ thống xoay tự do theo hướng cầm máy của người dùng
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final newController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: true,
          imageFormatGroup: ImageFormatGroup.nv21,
        );

        await newController.initialize();
        _cameraController = newController;
        _startImageStream();
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo Camera: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Bắt đầu ghi hình: Khóa hướng file Output Video theo góc cầm máy lúc bấm
  Future<void> startRecording(DeviceOrientation currentOrientation) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isRecording) {
      return;
    }

    try {
      await _cameraController!.lockCaptureOrientation(currentOrientation);
      await _cameraController!.startVideoRecording();
      _isRecording = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi bắt đầu ghi hình: $e');
    }
  }

  /// Dừng ghi hình và mở khóa hướng camera
  Future<XFile?> stopRecording() async {
    if (_cameraController == null || !_isRecording) return null;

    try {
      final file = await _cameraController!.stopVideoRecording();
      await _cameraController!.unlockCaptureOrientation();
      _isRecording = false;
      notifyListeners();
      return file;
    } catch (e) {
      debugPrint('Lỗi dừng ghi hình: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessingImage || _objectDetector == null) return;
      _isProcessingImage = true;

      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage != null) {
          final detectedObjects = await _objectDetector!.processImage(inputImage);
          _processDistances(detectedObjects, image.width, image.height);
        }
      } catch (e) {
        debugPrint('Lỗi ML Kit: $e');
      } finally {
        _isProcessingImage = false;
      }
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final sensorOrientation = _cameraController!.description.sensorOrientation;
    InputImageRotation? imageRotation =
    InputImageRotationValue.fromRawValue(sensorOrientation);
    if (imageRotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || format != InputImageFormat.nv21) return null;

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _processDistances(
      List<DetectedObject> objects,
      int imageWidth,
      int imageHeight,
      ) {
    final List<VehicleDistance> updatedVehicles = [];
    final double imageArea = (imageWidth * imageHeight).toDouble();

    for (final obj in objects) {
      final boundingBox = obj.boundingBox;
      final double boxArea = boundingBox.width * boundingBox.height;
      final double areaRatio = boxArea / imageArea;

      double estimatedDistance = 0.0;
      if (areaRatio > 0) {
        estimatedDistance = (1.5 / areaRatio).clamp(2.0, 120.0);
      }

      final warningLevel = DistanceThresholds.evaluateLevel(
        actualDistance: estimatedDistance,
        speedKmH: _currentSpeedKmH,
      );

      updatedVehicles.add(
        VehicleDistance(
          boundingBox: boundingBox,
          distanceMeters: estimatedDistance,
          warningLevel: warningLevel,
        ),
      );
    }

    _detectedVehicles = updatedVehicles;
    notifyListeners();
  }

  Future<void> _initLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (_lastPosition != null) {
        final double distanceInMeters = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        _totalDistanceMeters += distanceInMeters;
      }

      _lastPosition = position;
      _currentSpeedKmH = (position.speed * 3.6).clamp(0.0, 300.0);
      notifyListeners();
    });
  }

  void toggleDistanceOverlay() {
    _showDistanceOverlay = !_showDistanceOverlay;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _objectDetector?.close();
    _cameraController?.dispose();
    super.dispose();
  }
}