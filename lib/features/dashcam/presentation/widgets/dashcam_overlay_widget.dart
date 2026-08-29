import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashcamOverlayWidget extends StatelessWidget {
  final double speedKmH;
  final double latitude;
  final double longitude;
  final DateTime currentDateTime;
  final bool isPortrait;

  const DashcamOverlayWidget({
    super.key,
    required this.speedKmH,
    required this.latitude,
    required this.longitude,
    required this.currentDateTime,
    required this.isPortrait,
  });

  @override
  Widget build(BuildContext context) {
    // Thời gian cập nhật trực tiếp từ Controller
    final String timeStr = DateFormat('MM-dd-yyyy HH:mm:ss').format(currentDateTime);
    final String speedStr = "${speedKmH.toInt()}km/h";
    final String locationStr =
        "${longitude.toStringAsFixed(3)}° 46.116'E, ${latitude.toStringAsFixed(3)}° 2.541'N";
    const String appName = "DashCam_ADAS";

    const textStyleSmall = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: 'monospace',
      shadows: [
        Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black87),
      ],
    );

    const textStyleBold = TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
      fontFamily: 'monospace',
      shadows: [
        Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black87),
      ],
    );

    return Stack(
      children: [
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: isPortrait
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(appName, style: textStyleBold),
              const SizedBox(height: 2),
              Text(speedStr, style: textStyleBold),
              const SizedBox(height: 2),
              Text(timeStr, style: textStyleSmall),
              const SizedBox(height: 2),
              Text(locationStr, style: textStyleSmall),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(appName, style: textStyleBold),
                  const SizedBox(height: 2),
                  Text(timeStr, style: textStyleSmall),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(speedStr, style: textStyleBold),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(locationStr, style: textStyleSmall),
              ),
            ],
          ),
        ),
      ],
    );
  }
}