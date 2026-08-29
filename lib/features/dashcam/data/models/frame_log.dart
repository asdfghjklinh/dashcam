import 'dart:ui';
import 'package:dashcam/features/dashcam/data/models/vehicle_distance.dart';

class FrameLog {
  final Duration timestamp;
  final double speedKmH;
  final double latitude;
  final double longitude;
  final List<VehicleDistance> vehicles;

  FrameLog({
    required this.timestamp,
    required this.speedKmH,
    required this.latitude,
    required this.longitude,
    required this.vehicles,
  });
}