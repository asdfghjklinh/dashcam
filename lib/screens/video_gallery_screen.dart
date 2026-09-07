import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'video_player_screen.dart';

class VideoGalleryScreen extends StatefulWidget {
  const VideoGalleryScreen({super.key});

  @override
  State<VideoGalleryScreen> createState() => _VideoGalleryScreenState();
}

class _VideoGalleryScreenState extends State<VideoGalleryScreen> {
  List<FileSystemEntity> _videoFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String videoDir = '${appDocDir.path}/DashcamVideos';
    final directory = Directory(videoDir);

    if (await directory.exists()) {
      final files = directory.listSync().where((item) => item.path.endsWith('.mp4')).toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      setState(() {
        _videoFiles = files;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Danh sách Video Hành trình")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videoFiles.isEmpty
          ? const Center(child: Text("Chưa có video nào được ghi."))
          : ListView.builder(
        itemCount: _videoFiles.length,
        itemBuilder: (context, index) {
          final file = File(_videoFiles[index].path);
          final fileName = file.path.split('/').last;

          return ListTile(
            leading: const Icon(Icons.video_file, color: Colors.blue, size: 40),
            title: Text(fileName, style: const TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.play_arrow),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(videoPath: file.path),
                ),
              );
            },
          );
        },
      ),
    );
  }
}