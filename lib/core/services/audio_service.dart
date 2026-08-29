import 'package:audioplayers/audioplayers.dart';
import '../constants/distance_thresholds.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  DateTime? _lastAlertTime;

  Future<void> init() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> updateWarningAlert({
    required WarningLevel level,
    required bool alertOnYellow,
  }) async {
    if (level == WarningLevel.safe) return;
    if (level == WarningLevel.warning && !alertOnYellow) return;

    DateTime now = DateTime.now();
    if (_lastAlertTime != null && now.difference(_lastAlertTime!).inMilliseconds < 1500) {
      return; // Giới hạn phát còi tối đa 1.5s/lần
    }
    _lastAlertTime = now;

    try {
      if (level == WarningLevel.danger) {
        await _audioPlayer.play(AssetSource('sounds/alert_red.mp3'));
      } else if (level == WarningLevel.warning) {
        await _audioPlayer.play(AssetSource('sounds/warning_yellow.mp3'));
      }
    } catch (e) {
      print("Lỗi âm thanh: $e");
    }
  }

  void dispose() => _audioPlayer.dispose();
}