import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/dashcam_native_controller.dart';
import '../providers/provider_settings.dart';

class CameraPreviewWidget extends StatefulWidget {
  final VoidCallback? onVideoSaved;
  final bool isFullscreen;
  final VoidCallback? onToggleFullscreen;

  const CameraPreviewWidget({
    super.key,
    this.onVideoSaved,
    this.isFullscreen = false,
    this.onToggleFullscreen,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  final DashcamNativeController _nativeController = DashcamNativeController();
  int? _textureId;
  bool _isRecording = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndInit();
  }

  Future<void> _requestPermissionsAndInit() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.locationWhenInUse,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]?.isGranted == true) {
      final id = await _nativeController.initialize();
      if (mounted) {
        setState(() {
          _textureId = id;
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String videoDir = '${appDocDir.path}/DashcamVideos';
      await Directory(videoDir).create(recursive: true);

      final String timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String filePath = '$videoDir/Dashcam_$timeStamp.mp4';

      final success = await _nativeController.startRecording(filePath);
      if (success && mounted) {
        setState(() => _isRecording = true);
      }
    } else {
      final success = await _nativeController.stopRecording();
      if (success && mounted) {
        setState(() => _isRecording = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu video hành trình thành công!')),
        );

        widget.onVideoSaved?.call();
      }
    }
  }

  @override
  void dispose() {
    _nativeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isLandscape = settings.isLandscape;
    final isCollapsed = settings.isPortraitCollapsed;
    final double cameraAspectRatio = isLandscape ? (16 / 9) : (9 / 16);

    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: AspectRatio(
        aspectRatio: widget.isFullscreen
            ? (isLandscape ? (16 / 9) : (9 / 16))
            : ((isLandscape || isCollapsed) ? (16 / 9) : cameraAspectRatio),
        child: Container(
          color: Colors.grey[900],
          child: Stack(
            children: [
              // Luồng Camera Real-time
              Center(
                child: _isInitialized && _textureId != null
                    ? Texture(textureId: _textureId!)
                    : const CircularProgressIndicator(color: Colors.white),
              ),

              // Thanh điều khiển Overlay
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Khoảng trắng cân bằng bên trái (36px tương đương size icon)
                    const SizedBox(width: 36),

                    // Nút Quay iPhone nằm chính giữa
                    IPhoneRecordButton(
                      isRecording: _isRecording,
                      onTap: _toggleRecording,
                    ),

                    // Nút Fullscreen / Thu nhỏ dịch sát về mép phải (cách xa nút Quay)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        widget.isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: widget.onToggleFullscreen,
                      tooltip: widget.isFullscreen ? 'Thu nhỏ' : 'Toàn màn hình',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IPhoneRecordButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onTap;

  const IPhoneRecordButton({
    super.key,
    required this.isRecording,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: isRecording ? 18 : 38,
            height: isRecording ? 18 : 38,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(isRecording ? 4 : 19),
            ),
          ),
        ),
      ),
    );
  }
}