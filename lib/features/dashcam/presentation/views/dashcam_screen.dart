import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dashcam/features/dashcam/presentation/controllers/dashcam_controller.dart';
import 'package:dashcam/features/dashcam/presentation/widgets/camera_preview_widget.dart';
import 'package:dashcam/features/dashcam/presentation/widgets/distance_overlay_widget.dart';
import 'package:dashcam/features/dashcam/presentation/widgets/speed_hud_widget.dart';

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
          ? const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      )
          : Stack(
        children: [
          // 1. Camera Preview Tràn Màn Hình Tỉ Lệ Chuẩn (Giống iOS Camera)
          const Positioned.fill(
            child: CameraPreviewWidget(),
          ),

          // 2. Overlays Nhận diện Bounding Box AI
          if (dashcamController.showDistanceOverlay)
            const Positioned.fill(
              child: DistanceOverlayWidget(),
            ),

          // 3. Nút Cài Đặt (Top Right)
          Positioned(
            top: 45,
            right: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ),
          ),

          // 4. HUD Tốc độ & Quãng đường
          Positioned(
            bottom: isPortrait ? 120 : 20,
            left: 16,
            right: isPortrait ? 16 : null,
            child: SpeedHudWidget(
              speedKmH: dashcamController.currentSpeedKmH,
              totalDistanceM: dashcamController.totalDistanceM,
              isPortrait: isPortrait,
            ),
          ),

          // 5. Nút Bắt đầu / Dừng Ghi hình
          Positioned(
            bottom: isPortrait ? 40 : 20,
            right: isPortrait ? null : 30,
            left: isPortrait ? 0 : null,
            child: isPortrait
                ? Center(child: _buildRecordButton(context, dashcamController, isPortrait))
                : _buildRecordButton(context, dashcamController, isPortrait),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton(
      BuildContext context, DashcamController dashcamController, bool isPortrait) {
    return FloatingActionButton(
      backgroundColor: dashcamController.isRecording ? Colors.red : Colors.white,
      onPressed: () async {
        if (dashcamController.isRecording) {
          await dashcamController.stopRecording();
        } else {
          DeviceOrientation recordOrientation = isPortrait
              ? DeviceOrientation.portraitUp
              : DeviceOrientation.landscapeLeft;

          await dashcamController.startRecording(recordOrientation);
        }
      },
      child: Icon(
        dashcamController.isRecording ? Icons.stop : Icons.videocam,
        color: dashcamController.isRecording ? Colors.white : Colors.red,
      ),
    );
  }
}