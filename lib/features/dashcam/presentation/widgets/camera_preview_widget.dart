import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dashcam/features/dashcam/presentation/controllers/dashcam_controller.dart';

class CameraPreviewWidget extends StatelessWidget {
  const CameraPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashcamController>();

    if (!controller.isCameraReady) {
      return const ColoredBox(color: Colors.black);
    }

    final cameraController = controller.cameraController!;

    // 1. Kiểm tra hướng xoay của màn hình hiện tại
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    // 2. Lấy tỷ lệ khung hình gốc từ Camera (thường là 16/9 hoặc 4/3)
    double cameraAspectRatio = cameraController.value.aspectRatio;

    // Khi ở màn hình Dọc, tỷ lệ xem phải đảo ngược (ví dụ 9/16) để vật thể đứng thẳng đúng chiều
    if (isPortrait) {
      cameraAspectRatio = 1 / cameraAspectRatio;
    }

    // 3. Sử dụng LayoutBuilder + ClipRect để phóng tràn màn hình (BoxFit.cover) giống hệt iOS Camera Native
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedOverflowBox(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            child: FittedBox(
              fit: BoxFit.cover, // Đảm bảo luôn tràn Full màn hình, không méo hình
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth / cameraAspectRatio,
                child: CameraPreview(cameraController),
              ),
            ),
          );
        },
      ),
    );
  }
}