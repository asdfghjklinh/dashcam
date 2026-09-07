import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/gps_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/camera_preview_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🟢 Ép ứng dụng Flutter luôn nằm ở chiều đứng duy nhất
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GpsProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const DashcamApp(),
    ),
  );
}

class DashcamApp extends StatelessWidget {
  const DashcamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Dashcam App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CameraPreviewScreen(),
    );
  }
}