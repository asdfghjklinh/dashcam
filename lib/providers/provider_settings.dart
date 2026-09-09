import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VideoOrientationMode { portrait, landscape }

class SettingsProvider extends ChangeNotifier {
  static const String _keyOrientation = 'video_orientation_mode';

  VideoOrientationMode _orientationMode = VideoOrientationMode.portrait;
  bool _isPortraitCollapsed = false;

  VideoOrientationMode get orientationMode => _orientationMode;
  bool get isLandscape => _orientationMode == VideoOrientationMode.landscape;
  bool get isPortraitCollapsed => _isPortraitCollapsed;

  SettingsProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyOrientation) ?? 0;
    _orientationMode = VideoOrientationMode.values[index];
    notifyListeners();
  }

  /// Hàm tương thích với màn hình ScreenSettings
  Future<void> setOrientationMode(VideoOrientationMode mode) async {
    _orientationMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyOrientation, mode.index);
  }

  Future<void> setLandscape(bool value) async {
    await setOrientationMode(
      value ? VideoOrientationMode.landscape : VideoOrientationMode.portrait,
    );
  }

  void togglePortraitCollapse() {
    _isPortraitCollapsed = !_isPortraitCollapsed;
    notifyListeners();
  }
}