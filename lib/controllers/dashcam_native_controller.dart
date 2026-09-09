import 'package:flutter/services.dart';

class DashcamNativeController {
  static const MethodChannel _channel = MethodChannel('com.app.dashcam/recorder');

  int? textureId;

  /// Khởi tạo Camera, AI Engine và CoreImage Renderer ở Native
  Future<int?> initialize() async {
    try {
      textureId = await _channel.invokeMethod<int>('initializeCamera');
      return textureId;
    } on PlatformException catch (e) {
      print("Lỗi khởi tạo Native Dashcam: ${e.message}");
      return null;
    }
  }

  /// Bắt đầu ghi hình GPU Real-time trực tiếp ra file MP4
  Future<bool> startRecording(String savePath) async {
    try {
      final bool? success = await _channel.invokeMethod('startRecording', {
        'path': savePath,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      print("Lỗi bắt đầu ghi hình: ${e.message}");
      return false;
    }
  }

  /// Dừng ghi hình (File MP4 hoàn chỉnh ngay lập tức)
  Future<bool> stopRecording() async {
    try {
      final bool? success = await _channel.invokeMethod('stopRecording');
      return success ?? false;
    } on PlatformException catch (e) {
      print("Lỗi dừng ghi hình: ${e.message}");
      return false;
    }
  }

  /// Giải phóng tài nguyên Native khi thoát màn hình
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
    } on PlatformException catch (e) {
      print("Lỗi dispose Native: ${e.message}");
    }
  }
}