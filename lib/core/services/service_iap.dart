// lib/core/services/service_iap.dart
import 'package:flutter/material.dart';

class IAPService extends ChangeNotifier {
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  void buyPremium() {
    _isPremium = true;
    notifyListeners();
  }
}

