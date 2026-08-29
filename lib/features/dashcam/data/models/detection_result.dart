import 'dart:ui';

/// Đại diện cho kết quả nhận diện phương tiện từ AI/ML model
class DetectionResult {
  final String label;
  final double confidence;
  final Rect boundingBox;
  final int? trackId;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    this.trackId,
  });

  /// Chuyển đổi dữ liệu sang dạng Map (để debug hoặc truyền dữ liệu)
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'confidence': confidence,
      'boundingBox': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
      },
      'trackId': trackId,
    };
  }

  /// Khởi tạo đối tượng từ Map/JSON
  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    final box = json['boundingBox'] as Map<String, dynamic>;
    return DetectionResult(
      label: json['label'] as String? ?? 'Vehicle',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      boundingBox: Rect.fromLTWH(
        (box['left'] as num).toDouble(),
        (box['top'] as num).toDouble(),
        (box['width'] as num).toDouble(),
        (box['height'] as num).toDouble(),
      ),
      trackId: json['trackId'] as int?,
    );
  }
}