import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dashcam/features/dashcam/data/models/frame_log.dart';

class VideoWatermarkService {
  /// Render các thông số mô phỏng chuẩn giao diện DashCam_ADAS vào Video MP4
  static Future<String?> processVideoWithDynamicOverlay({
    required String rawVideoPath,
    required bool isPortrait,
    required List<FrameLog> logs,
  }) async {
    if (logs.isEmpty) return rawVideoPath;

    final Directory tempDir = await getTemporaryDirectory();
    final String srtPath = '${tempDir.path}/overlay_subtitles.srt';
    final String outputPath = rawVideoPath.replaceAll('.mp4', '_watermarked.mp4');

    // 1. SINH FILE PHỤ ĐỀ DYNAMIC MÔ PHỎNG DashCam_ADAS
    final File srtFile = File(srtPath);
    final StringBuffer srtContent = StringBuffer();

    for (int i = 0; i < logs.length - 1; i++) {
      final current = logs[i];
      final next = logs[i + 1];

      final startTimeStr = _formatDurationForSRT(current.timestamp);
      final endTimeStr = _formatDurationForSRT(next.timestamp);

      final String timeStr = DateFormat('MM-dd-yyyy HH:mm:ss').format(DateTime.now());
      final String speedStr = "${current.speedKmH.toInt()}km/h";
      final String locStr = "${current.longitude.toStringAsFixed(3)}° 46.116'E, ${current.latitude.toStringAsFixed(3)}° 2.541'N";

      String lineText = "";
      if (isPortrait) {
        // Dọc: Tên app -> Tốc độ -> Thời gian -> Tọa độ
        lineText = "DashCam_ADAS\n$speedStr\n$timeStr\n$locStr";
      } else {
        // Ngang: Giống ảnh mẫu DashCam_ADAS
        lineText = "DashCam_ADAS\n$timeStr               $speedStr               $locStr";
      }

      srtContent.writeln('${i + 1}');
      srtContent.writeln('$startTimeStr --> $endTimeStr');
      srtContent.writeln(lineText);
      srtContent.writeln();
    }

    await srtFile.writeAsString(srtContent.toString());

    // 2. LỆNH FFMPEG VẼ TEXT VÀ KHOẢNG CÁCH KHUNG XANH LÁ
    List<String> filterGraphList = [];

    // Chữ màu trắng (&H00FFFFFF), bóng mờ màu đen chìm bên dưới (BorderStyle=1, Shadow=1)
    final String escapedSrtPath = srtPath.replaceAll('\\', '/').replaceAll(':', '\\:');
    final String subStyle = isPortrait
        ? "Alignment=1,MarginL=20,MarginV=20,FontSize=16,PrimaryColour=&H00FFFFFF,BorderStyle=1,Shadow=1"
        : "Alignment=1,MarginL=20,MarginV=15,FontSize=16,PrimaryColour=&H00FFFFFF,BorderStyle=1,Shadow=1";

    filterGraphList.add("subtitles='$escapedSrtPath':force_style='$subStyle'");

    // Vẽ Bounding Box xanh lá + Khoảng cách theo từng frame log
    for (int i = 0; i < logs.length - 1; i++) {
      final log = logs[i];
      final startSec = log.timestamp.inMilliseconds / 1000.0;
      final endSec = logs[i + 1].timestamp.inMilliseconds / 1000.0;

      for (final vehicle in log.vehicles) {
        final rect = vehicle.boundingBox;
        final int x = rect.left.toInt();
        final int y = rect.top.toInt();
        final int w = rect.width.toInt();
        final int h = rect.height.toInt();
        final String distStr = "${vehicle.distanceMeters.toStringAsFixed(1)}m";

        // Bounding box màu xanh lá mỏng 2px
        filterGraphList.add(
          "drawbox=x=$x:y=$y:w=$w:h=$h:color=green@0.8:t=2:enable='between(t,$startSec,$endSec)'",
        );

        // Nhãn khoảng cách xanh lá chữ đen phía trên góc box
        filterGraphList.add(
          "drawtext=text='$distStr':x=$x:y=${y - 20 > 0 ? y - 20 : y}:fontsize=14:fontcolor=black:box=1:boxcolor=green@0.8:enable='between(t,$startSec,$endSec)'",
        );
      }
    }

    final String vfCommand = filterGraphList.join(',');
    final String ffmpegCommand =
        "-i $rawVideoPath -vf \"$vfCommand\" -c:a copy -preset ultrafast $outputPath";

    final session = await FFmpegKit.execute(ffmpegCommand);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      if (await srtFile.exists()) await srtFile.delete();
      return outputPath;
    } else {
      return rawVideoPath;
    }
  }

  static String _formatDurationForSRT(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final millis = threeDigits(duration.inMilliseconds.remainder(1000));
    return "$hours:$minutes:$seconds,$millis";
  }
}