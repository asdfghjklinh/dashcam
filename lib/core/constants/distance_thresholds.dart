/// Enum đại diện cho các mức độ cảnh báo khoảng cách
enum WarningLevel {
  safe,
  warning,
  danger,
}

class DistanceThresholds {
  /// Xác định khoảng cách tối thiểu an toàn dựa trên tốc độ xe (km/h)
  static double getMinSafeDistance(double speedKmH) {
    if (speedKmH <= 60) {
      return 35.0; // Tốc độ dưới 60km/h -> Khoảng cách an toàn ~35m
    } else if (speedKmH <= 80) {
      return 55.0; // Tốc độ 60 - 80 km/h -> Khoảng cách tối thiểu 55m
    } else if (speedKmH <= 100) {
      return 70.0; // Tốc độ 80 - 100 km/h -> Khoảng cách tối thiểu 70m
    } else {
      return 100.0; // Tốc độ > 100 km/h -> Khoảng cách tối thiểu 100m
    }
  }

  /// Phân loại mức độ cảnh báo
  static WarningLevel evaluateLevel({
    required double actualDistance,
    required double speedKmH,
  }) {
    double safeDistance = getMinSafeDistance(speedKmH);

    if (actualDistance >= safeDistance) {
      return WarningLevel.safe;
    } else if (actualDistance >= safeDistance * 0.6) {
      return WarningLevel.warning; // Từ 60% đến 100% khoảng cách an toàn -> Vàng
    } else {
      return WarningLevel.danger;  // Dưới 60% khoảng cách an toàn -> Đỏ
    }
  }
}

