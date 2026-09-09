import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/provider_settings.dart';
import '../widgets/widget_banner_ad.dart';
import '../widgets/widget_camera_preview.dart';

class FullscreenScreen extends StatefulWidget {
  const FullscreenScreen({super.key});

  @override
  State<FullscreenScreen> createState() => _FullscreenScreenState();
}

class _FullscreenScreenState extends State<FullscreenScreen> {
  late bool isLandscape;

  @override
  void initState() {
    super.initState();
    isLandscape = context.read<SettingsProvider>().isLandscape;

    // Ép xoay màn hình thiết bị nếu cài đặt đang ở chế độ Ngang (Landscape)
    if (isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<void> _handleBack(BuildContext context) async {
    // Tra lại định dạng Dọc chuẩn cho thiết bị khi thoát Fullscreen
    if (isLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
        ),
      ),
    );
  }

  /// Giao diện Fullscreen Dọc (Portrait)
  Widget _buildPortraitLayout() {
    return Column(
      children: [
        const BannerAdWidget(),
        Expanded(
          child: Stack(
            children: [
              // 1. Luồng Camera Preview hiển thị tràn màn hình
              const Positioned.fill(
                child: CameraPreviewWidget(),
              ),

              // 2. Nút bấm Thu nhỏ (Thoát Fullscreen) ở góc trên
              _buildExitFullscreenButton(),
            ],
          ),
        ),
        const BannerAdWidget(),
      ],
    );
  }

  /// Giao diện Fullscreen Ngang (Landscape)
  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        const RotatedBox(quarterTurns: 1, child: BannerAdWidget()),
        Expanded(
          child: Stack(
            children: [
              // 1. Luồng Camera Preview hiển thị tràn màn hình
              const Positioned.fill(
                child: CameraPreviewWidget(),
              ),

              // 2. Nút bấm Thu nhỏ (Thoát Fullscreen) ở góc trên
              _buildExitFullscreenButton(),
            ],
          ),
        ),
        const RotatedBox(quarterTurns: 1, child: BannerAdWidget()),
      ],
    );
  }

  /// Nút thu nhỏ Fullscreen overlay lên Preview Camera
  Widget _buildExitFullscreenButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: Material(
        color: Colors.black45,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 28),
          onPressed: () => _handleBack(context),
          tooltip: 'Thu nhỏ',
        ),
      ),
    );
  }
}