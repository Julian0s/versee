import 'package:flutter/foundation.dart';

/// Platform configuration to handle web vs mobile differences
class PlatformConfig {
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  
  /// Check if web-specific features should be enabled
  static bool get enableWebFeatures => kIsWeb;
  
  /// Check if mobile-specific features should be enabled  
  static bool get enableMobileFeatures => !kIsWeb;
}