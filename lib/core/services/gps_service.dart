import 'dart:async';
import 'package:geolocator/geolocator.dart';

class GpsService {
  StreamSubscription<Position>? _positionStreamSub;
  double _currentSpeedKmH = 0.0;
  double _totalDistanceMeters = 0.0;
  Position? _lastPosition;

  double get currentSpeedKmH => _currentSpeedKmH;
  double get totalDistanceMeters => _totalDistanceMeters;

  Future<void> startLocationUpdates({
    required Function(double speed, double distance) onUpdate,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('GPS chưa bật.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Quyền GPS bị từ chối.');
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Cập nhật mỗi 10m di chuyển để tiết kiệm pin
    );

    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _currentSpeedKmH = (position.speed < 0) ? 0.0 : (position.speed * 3.6);

      if (_lastPosition != null) {
        double delta = Geolocator.distanceBetween(
          _lastPosition!.latitude, _lastPosition!.longitude,
          position.latitude, position.longitude,
        );
        _totalDistanceMeters += delta;
      }
      _lastPosition = position;
      onUpdate(_currentSpeedKmH, _totalDistanceMeters);
    });
  }

  void stopLocationUpdates() => _positionStreamSub?.cancel();
}