import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dashcam/features/settings/presentation/controllers/settings_controller.dart';
import 'package:dashcam/features/dashcam/presentation/controllers/dashcam_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final dashcamController = context.watch<DashcamController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt Ứng dụng'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Dynamic Overlay Toggle
          SwitchListTile(
            title: const Text('Hiển thị khoảng cách cảnh báo'),
            subtitle: const Text('Hiện các ô nhận diện phương tiện trên camera'),
            value: dashcamController.showDistanceOverlay,
            onChanged: (bool value) {
              dashcamController.toggleDistanceOverlay();
            },
          ),
          const Divider(),

          // Sound Alert Toggle
          SwitchListTile(
            title: const Text('Cảnh báo âm thanh'),
            subtitle: const Text('Phát âm thanh khi khoảng cách quá gần'),
            value: settingsController.enableSoundAlert,
            onChanged: (bool value) {
              settingsController.toggleSoundAlert(value);
            },
          ),
          const Divider(),

          // Warning Distance Threshold Slider
          ListTile(
            title: const Text('Khoảng cách cảnh báo an toàn'),
            subtitle: Text('${settingsController.warningDistanceThreshold.toInt()} mét'),
          ),
          Slider(
            value: settingsController.warningDistanceThreshold,
            min: 5.0,
            max: 30.0,
            divisions: 5,
            label: '${settingsController.warningDistanceThreshold.toInt()}m',
            onChanged: (double value) {
              settingsController.setWarningThreshold(value);
            },
          ),
        ],
      ),
    );
  }
}