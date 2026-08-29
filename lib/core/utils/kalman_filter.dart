class KalmanFilter1D {
  double _q; // Process noise
  double _r; // Measurement noise
  double _x = 0; // Value estimate
  double _p = 1; // Estimation error
  double _k = 0; // Kalman gain
  bool _isInitialized = false;

  KalmanFilter1D({double processNoise = 0.1, double measurementNoise = 1.5})
      : _q = processNoise,
        _r = measurementNoise;

  double filter(double measurement) {
    if (!_isInitialized) {
      _x = measurement;
      _isInitialized = true;
      return _x;
    }

    _p = _p + _q;
    _k = _p / (_p + _r);
    _x = _x + _k * (measurement - _x);
    _p = (1 - _k) * _p;

    return _x;
  }

  void reset() {
    _isInitialized = false;
    _p = 1;
  }
}