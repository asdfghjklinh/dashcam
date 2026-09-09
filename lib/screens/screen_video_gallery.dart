import 'package:flutter/material.dart';
import 'screen_video_player.dart';

class VideoGalleryScreen extends StatelessWidget {
  const VideoGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thư viện Video')),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          final videoTitle = "Video_2026_09_0${index + 1}.mp4";
          return ListTile(
            leading: const Icon(Icons.video_file, color: Colors.blue, size: 36),
            title: Text(videoTitle),
            subtitle: Text('Đã quay vào: 0${index + 1}/09/2026'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(videoPath: videoTitle),
                ),
              );
            },
          );
        },
      ),
    );
  }
}