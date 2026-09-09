// lib/providers/provider_ad.dart
import 'package:flutter/material.dart';
import 'package:dashcam/core/services/service_iap.dart';

class AdProvider extends ChangeNotifier {
  final IAPService iapService;

  AdProvider(this.iapService) {
    iapService.addListener(notifyListeners);
  }

  bool get showAds => !iapService.isPremium;

  @override
  void dispose() {
    iapService.removeListener(notifyListeners);
    super.dispose();
  }
}