import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

import '../controllers/dashcam_native_controller.dart';
import 'video_gallery_screen.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
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
          const SnackBar(content: Text('Đã lưu video thành công!')),
        );
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
        children: [
          // 1. Luồng Camera GPU Preview từ Native
          Center(
            child: _textureId != null
                ? Texture(textureId: _textureId!)
                : const Text(
              "Không thể tải Texture Camera",
              style: TextStyle(color: Colors.white),
            ),
          ),

          // 2. Control Panel (Record Button phong cách iPhone & Gallery Button)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Thư viện video
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VideoGalleryScreen(),
                      ),
                    );
                  },
                ),

                // Nút Quay iPhone Nâng Cấp Animation
                IPhoneRecordButton(
                  isRecording: _isRecording,
                  onTap: _toggleRecording,
                ),

                // Spacer cân bằng bố cục
                const SizedBox(width: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút Quay Video phong cách iOS chuẩn
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
        width: 76,
        height: 76,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: isRecording ? 28 : 62,
            height: isRecording ? 28 : 62,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(isRecording ? 8 : 31),
            ),
          ),
        ),
      ),
    );
  }
}