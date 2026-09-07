import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  double _warningDistanceThreshold = 5.0; // Mặc định cảnh báo khi < 5m
  bool _isSoundEnabled = true;

  double get warningDistanceThreshold => _warningDistanceThreshold;
  bool get isSoundEnabled => _isSoundEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _warningDistanceThreshold = prefs.getDouble('warning_distance') ?? 5.0;
    _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
    notifyListeners();
  }

  Future<void> setWarningDistance(double value) async {
    _warningDistanceThreshold = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('warning_distance', value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
    notifyListeners();
  }
}