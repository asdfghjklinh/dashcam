import 'package:flutter/foundation.dart';
import 'package:dashcam/features/settings/data/datasources/settings_local_datasource.dart';

class SettingsController extends ChangeNotifier {
  final SettingsLocalDataSource _dataSource;

  // Ví dụ các cài đặt còn lại (nếu có)
  bool _enableSoundAlert = true;
  double _warningDistanceThreshold = 15.0; // mét

  SettingsController(this._dataSource) {
    _loadSettings();
  }

  // Getters
  bool get enableSoundAlert => _enableSoundAlert;
  double get warningDistanceThreshold => _warningDistanceThreshold;

  Future<void> _loadSettings() async {
    _enableSoundAlert = await _dataSource.getSoundAlertEnabled();
    _warningDistanceThreshold = await _dataSource.getWarningThreshold();
    notifyListeners();
  }

  Future<void> toggleSoundAlert(bool value) async {
    _enableSoundAlert = value;
    await _dataSource.setSoundAlertEnabled(value);
    notifyListeners();
  }

  Future<void> setWarningThreshold(double value) async {
    _warningDistanceThreshold = value;
    await _dataSource.setWarningThreshold(value);
    notifyListeners();
  }
}