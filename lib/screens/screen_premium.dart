import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/service_iap.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IAPService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nâng cấp Premium')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iap.isPremium ? Icons.verified : Icons.workspace_premium,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              iap.isPremium ? 'Bạn đang sử dụng bản Premium!' : 'Mua Premium để xóa toàn bộ Quảng cáo',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (!iap.isPremium)
              ElevatedButton(
                onPressed: () => context.read<IAPService>().buyPremium(),
                child: const Text('Mua ngay (IAP)'),
              ),
          ],
        ),
      ),
    );
  }
}