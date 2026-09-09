import 'package:flutter/material.dart';

class GPSData {
  final double latitude;
  final double longitude;
  final double speed; // km/h
  final DateTime timestamp;

  GPSData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.timestamp,
  });
}

class GPSProvider extends ChangeNotifier {
  GPSData _currentData = GPSData(
    latitude: 21.028511,
    longitude: 105.804817,
    speed: 0.0,
    timestamp: DateTime.now(),
  );

  final List<GPSData> _routeHistory = [];

  GPSData get currentData => _currentData;
  List<GPSData> get routeHistory => _routeHistory;

  void updateLocation(double lat, double lng, double speed) {
    _currentData = GPSData(
      latitude: lat,
      longitude: lng,
      speed: speed,
      timestamp: DateTime.now(),
    );

    // Lưu lại lịch sử để vẽ bản đồ lộ trình trong tương lai
    _routeHistory.add(_currentData);
    notifyListeners();
  }

  void clearHistory() {
    _routeHistory.clear();
    notifyListeners();
  }
}