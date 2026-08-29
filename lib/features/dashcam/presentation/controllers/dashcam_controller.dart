import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dashcam/features/dashcam/data/models/frame_log.dart';
import 'package:dashcam/features/dashcam/data/models/vehicle_distance.dart';
import 'package:dashcam/core/services/video_watermark_service.dart';

class DashcamController extends ChangeNotifier {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isCameraReady = false;
  bool _isRecording = false;
  bool _isRenderingVideo = false;
  bool _showDistanceOverlay = true;

  double _currentSpeedKmH = 0.0;
  Position? _lastPosition;
  DateTime _currentDateTime = DateTime.now();

  List<VehicleDistance> _detectedVehicles = [];

  StreamSubscription<Position>? _positionStream;
  Timer? _timerRealtime;

  final List<FrameLog> _frameLogs = [];
  DateTime? _recordStartTime;
  String? _rawVideoPath;
  String? _lastRecordedVideoPath;

  // GETTERS
  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  bool get isCameraReady => _isCameraReady;
  bool get isRecording => _isRecording;
  bool get isRenderingVideo => _isRenderingVideo;
  bool get showDistanceOverlay => _showDistanceOverlay;

  double get currentSpeedKmH => _currentSpeedKmH;
  Position? get lastPosition => _lastPosition;
  DateTime get currentDateTime => _currentDateTime;
  List<VehicleDistance> get detectedVehicles => _detectedVehicles;
  String? get lastRecordedVideoPath => _lastRecordedVideoPath;

  void toggleDistanceOverlay() {
    _showDistanceOverlay = !_showDistanceOverlay;
    notifyListeners();
  }

  void updateDetectedVehicles(List<VehicleDistance> vehicles) {
    _detectedVehicles = vehicles;
    notifyListeners();
  }

  /// Khởi tạo và Bật xin quyền hệ thống
  Future<void> initialize() async {
    // 1. CHỦ ĐỘNG XIN TẤT CẢ CÁC QUYỀN TRÊN MÀN HÌNH (POPUP HỆ THỐNG)
    await _requestAllPermissions();

    // 2. Khởi tạo Camera & Định vị GPS
    await _initCamera();
    await _startRealtimeTracking();

    _isInitialized = true;
    notifyListeners();
  }

  /// Hàm kích hoạt Popup xin quyền cho iOS và Android
  Future<void> _requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse,
      Permission.storage,
      Permission.photos, // iOS Photo Library / Android Media
    ].request();

    if (kDebugMode) {
      statuses.forEach((permission, status) {
        print("Trạng thái quyền $permission: $status");
      });

      // Xin quyền Thư viện ảnh / Storage
      var photoStatus = await Permission.photos.status;
      if (photoStatus.isDenied) {
        photoStatus = await Permission.photos.request();
      }

      // Nếu người dùng đã trót bấm Denied vĩnh viễn trước đó
      if (photoStatus.isPermanentlyDenied) {
        debugPrint("Quyền Photos bị từ chối vĩnh viễn. Mở Cài đặt hệ thống.");
        // Có thể gọi: openAppSettings(); nếu muốn nhắc người dùng bật thủ công
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      _isCameraReady = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi khởi tạo Camera: $e");
    }
  }

  Future<void> _startRealtimeTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    // 1. Cập nhật thời gian nhảy mỗi giây
    _timerRealtime?.cancel();
    _timerRealtime = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentDateTime = DateTime.now();

      if (_isRecording && _recordStartTime != null) {
        final elapsed = DateTime.now().difference(_recordStartTime!);
        _frameLogs.add(
          FrameLog(
            timestamp: elapsed,
            speedKmH: _currentSpeedKmH,
            latitude: _lastPosition?.latitude ?? 21.028,
            longitude: _lastPosition?.longitude ?? 105.834,
            vehicles: List.from(_detectedVehicles),
          ),
        );
      }

      notifyListeners();
    });

    // 2. Stream vị trí GPS
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      _lastPosition = position;
      _currentSpeedKmH = position.speed > 0 ? (position.speed * 3.6) : 0.0;
      notifyListeners();
    });
  }

  Future<void> startRecording(DeviceOrientation orientation, bool isPortrait) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      _frameLogs.clear();
      _recordStartTime = DateTime.now();
      await _cameraController!.startVideoRecording();
      _isRecording = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi bắt đầu quay video: $e");
    }
  }

  Future<String?> stopRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) return null;

    _isRecording = false;
    _isRenderingVideo = true;
    notifyListeners();

    try {
      final XFile rawFile = await _cameraController!.stopVideoRecording();
      _rawVideoPath = rawFile.path;

      if (_rawVideoPath != null) {
        // Render Watermark DashCam ADAS với FFmpeg (Được bọc try-catch an toàn)
        String? renderedPath;
        try {
          renderedPath = await VideoWatermarkService.processVideoWithDynamicOverlay(
            rawVideoPath: _rawVideoPath!,
            isPortrait: true,
            logs: _frameLogs,
          );
        } catch (ffmpegErr) {
          debugPrint("Lỗi FFmpeg Render (Dùng video gốc): $ffmpegErr");
          renderedPath = _rawVideoPath;
        }

        _lastRecordedVideoPath = renderedPath ?? _rawVideoPath;

        // Lưu video đã xử lý vào Thư viện ảnh
        if (_lastRecordedVideoPath != null) {
          try {
            final hasGalAccess = await Gal.hasAccess(toAlbum: true);
            if (!hasGalAccess) {
              await Gal.requestAccess(toAlbum: true);
            }
            await Gal.putVideo(_lastRecordedVideoPath!);
          } catch (galErr) {
            debugPrint("Lỗi khi lưu video vào Gallery: $galErr");
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi dừng video: $e");
    } finally {
      _isRenderingVideo = false;
      notifyListeners();
    }

    return _lastRecordedVideoPath;
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timerRealtime?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }
}