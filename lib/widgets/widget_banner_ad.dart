import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/provider_ad.dart';

class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final showAds = context.watch<AdProvider>().showAds;
    if (!showAds) return const SizedBox.shrink();

    return Container(
      height: 50,
      color: Colors.grey[400],
      alignment: Alignment.center,
      child: const Text('banner ad', style: TextStyle(color: Colors.black54, fontSize: 16)),
    );
  }
}