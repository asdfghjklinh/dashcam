import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dashcam/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:dashcam/features/settings/presentation/controllers/settings_controller.dart';
import 'package:dashcam/features/dashcam/presentation/controllers/dashcam_controller.dart';
import 'package:dashcam/features/dashcam/presentation/views/dashcam_screen.dart';
import 'package:dashcam/features/settings/presentation/views/settings_screen.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Local DataSource cho Settings
  final settingsLocalDataSource = SettingsLocalDataSource();

  // 2. Truyền dataSource vào constructor của SettingsController
  final settingsController = SettingsController(settingsLocalDataSource);

  // 3. ÉP NATIVE KHỞI TẠO CHANNEL SỰ KIỆN (Tránh lỗi MissingPluginException)
  try {
    await FFmpegKitConfig.init();
    debugPrint("FFmpegKit Native Channel đã kết nối thành công!");
  } catch (e) {
    debugPrint("Lỗi khởi tạo FFmpegKit Config: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsController),
        ChangeNotifierProvider(
          create: (_) => DashcamController()..initialize(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashcam ADAS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashcamScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}