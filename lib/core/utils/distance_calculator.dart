import 'kalman_filter.dart';

class DistanceCalculator {
  static const double carPlateWidth = 0.47;   // Chiều rộng biển ô tô (470mm)
  static const double bikePlateWidth = 0.19;  // Chiều rộng biển xe máy (190mm)
  static const double defaultFocalLengthPx = 800.0; // Tiêu cự giả định của Camera

  final KalmanFilter1D _kalmanFilter = KalmanFilter1D();

  /// Tính khoảng cách thô (mét) từ Bounding Box Pixel
  double calculateRawDistance({
    required double boundingBoxWidthPx,
    required double imageWidthPx,
    bool isCarPlate = true,
  }) {
    if (boundingBoxWidthPx <= 0) return 0.0;

    double realWidth = isCarPlate ? carPlateWidth : bikePlateWidth;
    return (realWidth * defaultFocalLengthPx) / boundingBoxWidthPx;
  }

  /// Tính khoảng cách qua lọc Kalman và làm tròn theo Step
  double getSmoothedStepDistance({required double rawDistance}) {
    if (rawDistance <= 0) return 0.0;
    double filtered = _kalmanFilter.filter(rawDistance);
    return roundToStep(filtered);
  }

  /// Hàm làm tròn theo bước nhảy
  static double roundToStep(double distance) {
    if (distance <= 0) return 0.0;
    if (distance < 30) {
      return (distance / 2).round() * 2.0;   // Dưới 30m: Nhảy step ±2m
    } else if (distance < 60) {
      return (distance / 5).round() * 5.0;   // Từ 30 - 60m: Nhảy step ±5m
    } else {
      return (distance / 10).round() * 10.0; // Trên 60m: Nhảy step ±10m
    }
  }

  void resetFilter() => _kalmanFilter.reset();
}