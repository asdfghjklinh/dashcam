import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  Future<void> playWarningSound() async {
    debugPrint("🔊 Cảnh báo: Khái niệm phát âm thanh cảnh báo khoảng cách xe!");
  }

  Future<void> playSpeedAlert() async {
    debugPrint("🔊 Cảnh báo: Bạn đang vượt quá tốc độ cho phép!");
  }
}