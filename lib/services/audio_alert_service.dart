import 'package:audioplayers/audioplayers.dart';

class AudioAlertService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  Future<void> playWarningSound() async {
    if (_isPlaying) return;
    _isPlaying = true;
    try {
      await _audioPlayer.play(AssetSource('sounds/warning.mp3'));
      _audioPlayer.onPlayerComplete.first.then((_) {
        _isPlaying = false;
      });
    } catch (e) {
      _isPlaying = false;
      print("Lỗi phát âm thanh: $e");
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}