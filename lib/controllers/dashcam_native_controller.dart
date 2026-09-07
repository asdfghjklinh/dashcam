import 'package:flutter/services.dart';

class DashcamNativeController {
  static const MethodChannel _channel =
  MethodChannel('com.app.mycamapp/recorder');

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

  /// 🟢 Native iOS (CLLocationManager & Timer) đã tự động cập nhật
  /// Tốc độ, Tọa độ GPS và Thời gian real-time.
  /// Hàm này giữ lại dạng rỗng (no-op) để không gây lỗi nếu có Widget khác lỡ gọi tới.
  Future<void> updateTelemetry({
    required double speed,
    required double latitude,
    required double longitude,
  }) async {
    // Không gửi invokeMethod nữa vì Native tự xử lý 100%
    return;
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

  /// Dừng ghi hình (File mp4 hoàn chỉnh ngay lập tức)
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