import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._(); static final instance=AdsService._(); bool _initialized=false;
  // Google-provided test IDs. Replace with your own IDs before production release.
  static const _androidBanner='ca-app-pub-3940256099942544/6300978111';
  static const _iosBanner='ca-app-pub-3940256099942544/2934735716';
  static const _androidInterstitial='ca-app-pub-3940256099942544/1033173712';
  static const _iosInterstitial='ca-app-pub-3940256099942544/4411468910';
  Future<void> initialize() async { if(kIsWeb)return; try { await MobileAds.instance.initialize(); _initialized=true; } catch (_) { _initialized=false; } }
  String get bannerId=>Platform.isIOS?_iosBanner:_androidBanner;
  String get interstitialId=>Platform.isIOS?_iosInterstitial:_androidInterstitial;
  bool get ready=>_initialized;
  BannerAd createBanner({required void Function() onLoaded,required void Function(LoadAdError) onFailed})=>BannerAd(adUnitId:bannerId,size:AdSize.banner,request:const AdRequest(),listener:BannerAdListener(onAdLoaded:(_)=>onLoaded(),onAdFailedToLoad:(ad,error){ad.dispose();onFailed(error);}));
  Future<void> showInterstitialIfReady({required void Function() onFinished}) async {
    if(!_initialized){onFinished();return;}
    InterstitialAd.load(adUnitId:interstitialId,request:const AdRequest(),adLoadCallback:InterstitialAdLoadCallback(onAdLoaded:(ad){ad.fullScreenContentCallback=FullScreenContentCallback(onAdDismissedFullScreenContent:(a){a.dispose();onFinished();},onAdFailedToShowFullScreenContent:(a,_) {a.dispose();onFinished();});ad.show();},onAdFailedToLoad:(_){onFinished();}));
  }
}
