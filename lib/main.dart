import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/service_iap.dart';
import 'providers/provider_ad.dart';
import 'providers/provider_settings.dart';
import 'screens/screen_main_tab.dart';

void main() {
  runApp(const DashcamApp());
}

class DashcamApp extends StatelessWidget {
  const DashcamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => IAPService()),
        ChangeNotifierProxyProvider<IAPService, AdProvider>(
          create: (ctx) => AdProvider(ctx.read<IAPService>()),
          update: (_, iap, previous) => previous ?? AdProvider(iap),
        ),
      ],
      child: MaterialApp(
        title: 'Dashcam App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const MainTabScreen(),
      ),
    );
  }
}