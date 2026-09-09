import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/provider_settings.dart';
import '../widgets/widget_camera_preview.dart';
import '../widgets/widget_banner_ad.dart';
import 'screen_video_player.dart';

class DashcamHomeScreen extends StatefulWidget {
  const DashcamHomeScreen({super.key});

  @override
  State<DashcamHomeScreen> createState() => _DashcamHomeScreenState();
}

class _DashcamHomeScreenState extends State<DashcamHomeScreen> {
  late Future<Map<String, List<FileSystemEntity>>> _videosGroupedFuture;
  bool _isFullscreenMode = false;

  @override
  void initState() {
    super.initState();
    _refreshVideoList();
  }

  void _refreshVideoList() {
    setState(() {
      _videosGroupedFuture = _fetchAndGroupVideos();
    });
  }

  Future<Map<String, List<FileSystemEntity>>> _fetchAndGroupVideos() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String videoDir = '${appDocDir.path}/DashcamVideos';
    final Directory dir = Directory(videoDir);

    if (!await dir.exists()) {
      return {};
    }

    final List<FileSystemEntity> files = dir.listSync();
    final List<FileSystemEntity> videoFiles = files.where((file) {
      return file.path.endsWith('.mp4') || file.path.endsWith('.mov');
    }).toList();

    videoFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    final Map<String, List<FileSystemEntity>> grouped = {};
    for (var file in videoFiles) {
      final DateTime modifiedTime = file.statSync().modified;
      final String groupKey = DateFormat('yyyy-MM-dd HH:00').format(modifiedTime);

      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(file);
    }

    return grouped;
  }

  /// Xử lý bật / tắt Fullscreen an toàn không khởi tạo lại Native Camera
  Future<void> _toggleFullscreen(bool isLandscapeSetting) async {
    setState(() {
      _isFullscreenMode = !_isFullscreenMode;
    });

    if (_isFullscreenMode && isLandscapeSetting) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isLandscapeSettings = settings.isLandscape;
    final isCollapsed = settings.isPortraitCollapsed;

    // CHẾ ĐỘ FULLSCREEN OVERLAY
    if (_isFullscreenMode) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _toggleFullscreen(isLandscapeSettings);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: isLandscapeSettings
                ? Row(
              children: [
                const RotatedBox(quarterTurns: 1, child: BannerAdWidget()),
                Expanded(
                  child: CameraPreviewWidget(
                    onVideoSaved: _refreshVideoList,
                    isFullscreen: true,
                    onToggleFullscreen: () => _toggleFullscreen(isLandscapeSettings),
                  ),
                ),
                const RotatedBox(quarterTurns: 1, child: BannerAdWidget()),
              ],
            )
                : Column(
              children: [
                const BannerAdWidget(),
                Expanded(
                  child: CameraPreviewWidget(
                    onVideoSaved: _refreshVideoList,
                    isFullscreen: true,
                    onToggleFullscreen: () => _toggleFullscreen(isLandscapeSettings),
                  ),
                ),
                const BannerAdWidget(),
              ],
            ),
          ),
        ),
      );
    }

    // CHẾ ĐỘ MÀN HÌNH CHÍNH THƯỜNG
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashcam'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshVideoList,
            tooltip: 'Tải lại thư viện',
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isDeviceLandscape = orientation == Orientation.landscape;

          if (isDeviceLandscape) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  CameraPreviewWidget(
                    onVideoSaved: _refreshVideoList,
                    isFullscreen: false,
                    onToggleFullscreen: () => _toggleFullscreen(isLandscapeSettings),
                  ),
                  _buildAlbumSection(),
                  const BannerAdWidget(),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (isLandscapeSettings || isCollapsed)
                CameraPreviewWidget(
                  onVideoSaved: _refreshVideoList,
                  isFullscreen: false,
                  onToggleFullscreen: () => _toggleFullscreen(isLandscapeSettings),
                )
              else
                Expanded(
                  flex: 5,
                  child: CameraPreviewWidget(
                    onVideoSaved: _refreshVideoList,
                    isFullscreen: false,
                    onToggleFullscreen: () => _toggleFullscreen(isLandscapeSettings),
                  ),
                ),

              if (!isLandscapeSettings)
                InkWell(
                  onTap: () => settings.togglePortraitCollapse(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    child: Icon(
                      isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      color: Colors.grey[400],
                      size: 28,
                    ),
                  ),
                ),

              Expanded(
                flex: isLandscapeSettings || isCollapsed ? 1 : 4,
                child: _buildAlbumSection(),
              ),

              const BannerAdWidget(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlbumSection() {
    return FutureBuilder<Map<String, List<FileSystemEntity>>>(
      future: _videosGroupedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi tải danh sách video: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final groupedVideos = snapshot.data ?? {};

        if (groupedVideos.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Chưa có video hành trình nào được ghi.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView(
            shrinkWrap: true,
            children: groupedVideos.entries.map((entry) {
              return _buildTimeGroup(context, entry.key, entry.value);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTimeGroup(BuildContext context, String timeHeader, List<FileSystemEntity> videoFiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Text(
            timeHeader,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.6,
          ),
          itemCount: videoFiles.length,
          itemBuilder: (context, index) {
            final file = videoFiles[index];
            final DateTime modifiedTime = file.statSync().modified;
            final String displayTime = DateFormat('HH:mm').format(modifiedTime);

            return Material(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(videoPath: file.path),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_fill, size: 18, color: Colors.black54),
                    const SizedBox(height: 2),
                    Text(
                      displayTime,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}