import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/provider_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Chế độ khung hình quay'),
            subtitle: Text(settings.isLandscape ? 'Video Ngang (16:9)' : 'Video Dọc (9:16)'),
            trailing: Switch(
              value: settings.isLandscape,
              onChanged: (val) {
                settings.setOrientationMode(
                  val ? VideoOrientationMode.landscape : VideoOrientationMode.portrait,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}