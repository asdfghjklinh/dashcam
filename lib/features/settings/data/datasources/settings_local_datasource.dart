import 'package:shared_preferences/shared_preferences.dart';

class SettingsLocalDataSource {
  static const String _keySoundAlert = 'sound_alert_enabled';
  static const String _keyWarningThreshold = 'warning_threshold';

  // Lấy trạng thái Cảnh báo âm thanh (Mặc định: true)
  Future<bool> getSoundAlertEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySoundAlert) ?? true;
  }

  // Lưu trạng thái Cảnh báo âm thanh
  Future<void> setSoundAlertEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundAlert, enabled);
  }

  // Lấy Ngưỡng khoảng cách cảnh báo (Mặc định: 15.0m)
  Future<double> getWarningThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyWarningThreshold) ?? 15.0;
  }

  // Lưu Ngưỡng khoảng cách cảnh báo
  Future<void> setWarningThreshold(double threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyWarningThreshold, threshold);
  }
}