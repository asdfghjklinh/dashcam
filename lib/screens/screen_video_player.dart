import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({
    super.key,
    required this.videoPath,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    _controller = VideoPlayerController.file(File(widget.videoPath));
    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
    } catch (e) {
      print("Lỗi mở file video: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.videoPath.split('/').last,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              _buildControlsOverlay(),
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.black26,
                ),
              ),
            ],
          ),
        )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: Center(
        child: AnimatedOpacity(
          opacity: _controller.value.isPlaying ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            color: Colors.black38,
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 64.0,
            ),
          ),
        ),
      ),
    );
  }
}