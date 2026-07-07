import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _initialized = false;

  String get _interstitialUnitId {
    if (kDebugMode) {
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    if (Platform.isIOS) return 'ca-app-pub-3836600923144289/3105853092';
    return 'ca-app-pub-3836600923144289/2211573828';
  }

  String get _rewardedUnitId {
    if (kDebugMode) {
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
      return 'ca-app-pub-3940256099942544/5224354917';
    }
    if (Platform.isIOS) return 'ca-app-pub-3836600923144289/8278288726';
    return 'ca-app-pub-3836600923144289/2261499116';
  }

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      unawaited(preloadInterstitial());
      unawaited(preloadRewarded());
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> preloadInterstitial() async {
    if (!_initialized) return;
    await InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  Future<void> showInterstitialAfterPost() async {
    final ad = _interstitialAd;
    if (ad == null) return;
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(preloadInterstitial());
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        unawaited(preloadInterstitial());
      },
    );
    await ad.show();
  }

  Future<void> preloadRewarded() async {
    if (!_initialized) return;
    await RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }

  Future<bool> showRewardedForPin() async {
    final ad = _rewardedAd;
    if (ad == null) return true;

    final completer = Completer<bool>();
    var rewarded = false;
    _rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(preloadRewarded());
        if (!completer.isCompleted) completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        unawaited(preloadRewarded());
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    await ad.show(
      onUserEarnedReward: (adWithoutView, rewardItem) {
        rewarded = true;
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => rewarded,
    );
  }
}

final adsServiceProvider = Provider<AdsService>((ref) {
  return AdsService();
});
