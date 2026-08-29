import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dashcam/features/dashcam/presentation/controllers/dashcam_controller.dart';
import 'package:dashcam/features/dashcam/data/models/vehicle_distance.dart';
import 'package:dashcam/core/constants/distance_thresholds.dart';

class DistanceOverlayWidget extends StatelessWidget {
  const DistanceOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashcamController>();
    final List<VehicleDistance> vehicles = controller.detectedVehicles;

    // Lấy kích thước ảnh preview từ camera controller
    final Size previewSize = controller.cameraController?.value.previewSize ?? const Size(1, 1);

    return CustomPaint(
      size: Size.infinite,
      painter: _DistanceOverlayPainter(
        vehicles: vehicles,
        imageSize: previewSize,
      ),
    );
  }
}

class _DistanceOverlayPainter extends CustomPainter {
  final List<VehicleDistance> vehicles;
  final Size imageSize;

  _DistanceOverlayPainter({
    required this.vehicles,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width == 0 || imageSize.height == 0) return;

    // Tỉ lệ scale giữa kích thước khung ảnh camera và kích thước màn hình hiển thị
    final double scaleX = size.width / imageSize.height;
    final double scaleY = size.height / imageSize.width;

    for (final vehicle in vehicles) {
      final rect = Rect.fromLTRB(
        vehicle.boundingBox.left * scaleX,
        vehicle.boundingBox.top * scaleY,
        vehicle.boundingBox.right * scaleX,
        vehicle.boundingBox.bottom * scaleY,
      );

      final Color color = _getColorByWarningLevel(vehicle.warningLevel);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      // 1. Vẽ Bounding Box xung quanh phương tiện
      canvas.drawRect(rect, paint);

      // 2. Vẽ nhãn hiển thị khoảng cách mét
      final textSpan = TextSpan(
        text: '${vehicle.distanceMeters.toStringAsFixed(1)}m',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: color.withOpacity(0.85),
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        rect.left,
        (rect.top - 20) < 0 ? rect.top : rect.top - 20,
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  Color _getColorByWarningLevel(WarningLevel level) {
    switch (level) {
      case WarningLevel.danger:
        return Colors.redAccent;
      case WarningLevel.warning:
        return Colors.amber;
      case WarningLevel.safe:
      default:
        return Colors.greenAccent;
    }
  }

  @override
  bool shouldRepaint(covariant _DistanceOverlayPainter oldDelegate) {
    return oldDelegate.vehicles != vehicles || oldDelegate.imageSize != imageSize;
  }
}