import 'package:flutter/foundation.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isAdLoaded = false;

  void initialize() {
    debugPrint("AdService initialized.");
  }

  void loadOpenAppAd() {
    debugPrint("Loading Open App Ad...");
  }

  void showOpenAppAdIfAvailable() {
    debugPrint("Showing Open App Ad...");
  }

  void loadInterstitialAd() {
    debugPrint("Loading Interstitial Ad...");
  }

  void showInterstitialAd({required Function onAdDismissed}) {
    debugPrint("Showing Interstitial Ad...");
    onAdDismissed();
  }

  void loadRewardedAd() {
    debugPrint("Loading Rewarded Ad...");
  }

  void showRewardedAd({required Function(int amount) onUserEarnedReward}) {
    debugPrint("Showing Rewarded Ad...");
    onUserEarnedReward(10); // Thưởng mẫu 10 xu/điểm
  }
}