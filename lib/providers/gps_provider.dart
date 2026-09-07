import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GpsProvider with ChangeNotifier {
  double _currentSpeedKmH = 0.0;
  double _latitude = 0.0;
  double _longitude = 0.0;
  StreamSubscription<Position>? _positionStream;

  double get currentSpeedKmH => _currentSpeedKmH;
  double get latitude => _latitude;
  double get longitude => _longitude;

  void startTracking(Function(double speed, double lat, double lng) onLocationUpdate) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      // Chuyển m/s sang km/h
      _currentSpeedKmH = position.speed > 0 ? position.speed * 3.6 : 0.0;
      _latitude = position.latitude;
      _longitude = position.longitude;

      onLocationUpdate(_currentSpeedKmH, _latitude, _longitude);
      notifyListeners();
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}