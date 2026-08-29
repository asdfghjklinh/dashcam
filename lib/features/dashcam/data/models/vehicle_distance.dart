import 'dart:ui';
// Import enum WarningLevel từ thư mục core
import 'package:dashcam/core/constants/distance_thresholds.dart';

/// Lớp đại diện cho thông tin khoảng cách phương tiện
class VehicleDistance {
  final Rect boundingBox;
  final double distanceMeters;
  final WarningLevel warningLevel;

  VehicleDistance({
    required this.boundingBox,
    required this.distanceMeters,
    required this.warningLevel,
  });

  /// Đã bổ sung getter 'label' để tương thích nếu UI/Controller cần hiển thị chuỗi cảnh báo
  String get warningLabel {
    switch (warningLevel) {
      case WarningLevel.danger:
        return 'DANGER';
      case WarningLevel.warning:
        return 'WARNING';
      case WarningLevel.safe:
      default:
        return 'SAFE';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'boundingBox': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
      },
      'distanceMeters': distanceMeters,
      'warningLevel': warningLevel.name,
    };
  }

  /// Hàm tính toán khoảng cách dựa trên mô hình Pin-hole Camera
  ///
  /// [boundingBoxHeight]: Chiều cao box phương tiện nhận diện được (pixel)
  /// [imageHeight]: Chiều cao ảnh gốc từ camera (pixel)
  /// [focalLength]: Tiêu cự camera (mặc định 800px)
  /// [realVehicleHeight]: Chiều cao thực tế trung bình của xe (mặc định 1.5m)
  static double calculateDistance({
    required double boundingBoxHeight,
    required double imageHeight,
    double focalLength = 800.0,
    double realVehicleHeight = 1.5,
  }) {
    if (boundingBoxHeight <= 0) return double.infinity;

    // Công thức Pin-hole camera model: D = (f * H) / h
    final double distance = (focalLength * realVehicleHeight) / boundingBoxHeight;

    // Làm tròn 2 chữ số thập phân
    return double.parse(distance.toStringAsFixed(2));
  }
}