import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

/// Centralised ad management for Guitar Educator.
///
/// Uses **test ad unit IDs** during development.
/// Replace with real IDs from AdMob console before production release.
class AdService {
  // ── Singleton ──
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  bool _initialised = false;

  // ── Test Ad Unit IDs (Google-provided) ──
  // Replace these with real IDs when AdMob account is approved.
  static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  // ── Interstitial ad state ──
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  static const _maxInterstitialAttempts = 3;

  // ── Frequency cap: show interstitial every N practice completions ──
  int _practiceCompleteCount = 0;
  static const _interstitialFrequency = 3; // show every 3 completions

  // ── Initialise ──
  Future<void> init() async {
    if (_initialised) return;
    await MobileAds.instance.initialize();
    _initialised = true;
    _loadInterstitial();
    debugPrint('[AdService] MobileAds initialised');
  }

  // ── Banner Ad ──
  /// Creates a new adaptive banner ad. Caller must dispose it.
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _testBannerId,
      size: AdSize.banner, // 320x50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint('[AdService] Banner loaded'),
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdService] Banner failed: $error');
          ad.dispose();
        },
      ),
    );
  }

  // ── Interstitial Ad ──
  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _testInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          debugPrint('[AdService] Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadAttempts++;
          _interstitialAd = null;
          debugPrint('[AdService] Interstitial failed: $error');
          if (_interstitialLoadAttempts < _maxInterstitialAttempts) {
            _loadInterstitial();
          }
        },
      ),
    );
  }

  /// Call this when a practice session or quiz completes.
  /// Shows an interstitial every [_interstitialFrequency] completions.
  void onPracticeComplete() {
    _practiceCompleteCount++;
    if (_practiceCompleteCount % _interstitialFrequency == 0) {
      showInterstitial();
    }
  }

  /// Force show interstitial (e.g., after tuning complete).
  void showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitial();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      _loadInterstitial();
    }
  }
}
