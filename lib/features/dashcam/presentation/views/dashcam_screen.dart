import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dashcam/features/dashcam/presentation/controllers/dashcam_controller.dart';
import 'package:dashcam/features/dashcam/presentation/widgets/camera_preview_widget.dart';
import 'package:dashcam/features/dashcam/presentation/widgets/dashcam_overlay_widget.dart';
import 'package:dashcam/features/dashcam/presentation/views/video_player_screen.dart';

class DashcamScreen extends StatelessWidget {
  const DashcamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashcamController = context.watch<DashcamController>();
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Colors.black,
      body: !dashcamController.isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : Stack(
        children: [
          // 1. Live Preview Camera
          const Positioned.fill(child: CameraPreviewWidget()),

          // 2. Dashcam Overlay DashCam_ADAS REALTIME (Cập nhật liên tục từ Controller)
          Positioned.fill(
            child: DashcamOverlayWidget(
              speedKmH: dashcamController.currentSpeedKmH,
              latitude: dashcamController.lastPosition?.latitude ?? 21.028,
              longitude: dashcamController.lastPosition?.longitude ?? 105.834,
              currentDateTime: dashcamController.currentDateTime, // Realtime
              isPortrait: isPortrait,
            ),
          ),

          // 3. Nút Xem Video Đã Quay
          if (dashcamController.lastRecordedVideoPath != null)
            Positioned(
              top: 40,
              right: 20,
              child: FloatingActionButton.small(
                heroTag: "btn_play",
                backgroundColor: Colors.black54,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        videoPath: dashcamController.lastRecordedVideoPath!,
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
              ),
            ),

          // 4. Nút Bắt đầu / Dừng Quay
          Positioned(
            bottom: isPortrait ? 120 : 20,
            right: isPortrait ? 20 : 30,
            child: FloatingActionButton(
              heroTag: "btn_record",
              backgroundColor: dashcamController.isRecording ? Colors.red : Colors.white,
              onPressed: () async {
                if (dashcamController.isRecording) {
                  final savedPath = await dashcamController.stopRecording();
                  if (savedPath != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã lưu video vào Album hệ thống!')),
                    );
                  }
                } else {
                  await dashcamController.startRecording(
                    isPortrait ? DeviceOrientation.portraitUp : DeviceOrientation.landscapeLeft,
                    isPortrait,
                  );
                }
              },
              child: Icon(
                dashcamController.isRecording ? Icons.stop : Icons.videocam,
                color: dashcamController.isRecording ? Colors.white : Colors.red,
              ),
            ),
          ),

          // 5. Màn hình chờ Render Video
          if (dashcamController.isRenderingVideo)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.greenAccent),
                    SizedBox(height: 16),
                    Text(
                      'Đang đóng dấu thông số DashCam_ADAS và lưu vào Gallery...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}