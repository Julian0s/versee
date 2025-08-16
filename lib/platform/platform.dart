/// Platform abstraction entry point
/// Usa conditional imports para selecionar a implementação correta automaticamente
import 'package:flutter/foundation.dart';
import 'platform_interface.dart';

// Conditional imports com implementação de factory
import 'web_platform.dart' if (dart.library.io) 'mobile_platform.dart';

/// Singleton para acessar funcionalidades específicas de plataforma
class PlatformUtils {
  static PlatformInterface? _instance;
  
  /// Obtém a instância da plataforma atual
  static PlatformInterface get instance {
    _instance ??= _createPlatform();
    return _instance!;
  }
  
  /// Cria a implementação correta baseada na plataforma
  static PlatformInterface _createPlatform() {
    if (kIsWeb) {
      debugPrint('🌐 Inicializando WebPlatform');
    } else {
      debugPrint('📱 Inicializando MobilePlatform');
    }
    // Usar factory function do arquivo importado condicionalmente
    return createPlatform();
  }
  
  /// Reinicia a plataforma (útil para testes)
  static void reset() {
    if (_instance != null) {
      if (kIsWeb) {
        (_instance as dynamic).dispose();
      } else {
        (_instance as dynamic).dispose();
      }
      _instance = null;
    }
  }
  
  /// Métodos de conveniência que delegam para a implementação atual
  
  static String getCurrentUrl() => instance.getCurrentUrl();
  
  static bool openWindow(String url, {Map<String, dynamic>? options}) =>
      instance.openWindow(url, options: options);
  
  static bool get supportsMultipleWindows => instance.supportsMultipleWindows;
  
  static bool get supportsFullscreen => instance.supportsFullscreen;
  
  static bool get supportsBroadcastChannel => instance.supportsBroadcastChannel;
  
  static String get userAgent => instance.userAgent;
  
  static bool get supportsPhysicalDisplays => instance.supportsPhysicalDisplays;
  
  static bool get supportsWirelessCasting => instance.supportsWirelessCasting;
  
  static Map<String, int> get screenDimensions => instance.screenDimensions;
  
  static Future<dynamic> executeNativeCode(String code, {Map<String, dynamic>? params}) =>
      instance.executeNativeCode(code, params: params);
  
  static void setupDisplayListeners(Function(Map<String, dynamic>) onDisplayEvent) =>
      instance.setupDisplayListeners(onDisplayEvent);
  
  static void removeDisplayListeners() => instance.removeDisplayListeners();
  
  static Future<bool> checkNetworkConnectivity() => instance.checkNetworkConnectivity();
  
  static Future<void> saveLocalData(String key, String value) =>
      instance.saveLocalData(key, value);
  
  static Future<String?> loadLocalData(String key) => instance.loadLocalData(key);
  
  static Future<void> removeLocalData(String key) => instance.removeLocalData(key);
  
  /// Métodos específicos para web (safe casting)
  
  static void sendBroadcastMessage(Map<String, dynamic> message) {
    if (kIsWeb) {
      (_instance as dynamic).sendBroadcastMessage(message);
    }
  }
  
  static Map<String, bool> getBrowserCapabilities() {
    if (kIsWeb) {
      return (_instance as dynamic).getBrowserCapabilities();
    }
    return {};
  }
  
  static Map<String, dynamic> getDetailedScreenInfo() {
    if (kIsWeb) {
      return (_instance as dynamic).getDetailedScreenInfo();
    }
    return {};
  }
  
  /// Métodos específicos para mobile (safe casting)
  
  static Future<List<Map<String, dynamic>>> scanChromecastDevices() {
    if (!kIsWeb) {
      return (_instance as dynamic).scanChromecastDevices();
    }
    return Future.value([]);
  }
  
  static Future<List<Map<String, dynamic>>> scanAirPlayDevices() {
    if (!kIsWeb) {
      return (_instance as dynamic).scanAirPlayDevices();
    }
    return Future.value([]);
  }
  
  static Future<bool> connectToChromecast(String deviceId, {String? appId}) {
    if (!kIsWeb) {
      return (_instance as dynamic).connectToChromecast(deviceId, appId: appId);
    }
    return Future.value(false);
  }
  
  static Future<bool> connectToAirPlay(String identifier) {
    if (!kIsWeb) {
      return (_instance as dynamic).connectToAirPlay(identifier);
    }
    return Future.value(false);
  }
  
  static Future<bool> disconnectFromCasting() {
    if (!kIsWeb) {
      return (_instance as dynamic).disconnectFromCasting();
    }
    return Future.value(false);
  }
  
  static Future<List<Map<String, dynamic>>> getPhysicalDisplays() {
    if (!kIsWeb) {
      return (_instance as dynamic).getPhysicalDisplays();
    }
    return Future.value([]);
  }
  
  static Future<bool> testDisplayConnection(String displayId) {
    if (!kIsWeb) {
      return (_instance as dynamic).testDisplayConnection(displayId);
    }
    return Future.value(false);
  }
  
  static Future<Map<String, dynamic>> getPlatformDiagnosticInfo() {
    if (!kIsWeb) {
      return (_instance as dynamic).getPlatformDiagnosticInfo();
    } else if (kIsWeb) {
      return Future.value({
        'platform': 'web',
        'userAgent': userAgent,
        'capabilities': getBrowserCapabilities(),
        'screenInfo': getDetailedScreenInfo(),
      });
    }
    return Future.value({'platform': 'unknown'});
  }
  
  static Map<String, bool> getMobileCapabilities() {
    if (!kIsWeb) {
      return (_instance as dynamic).getMobileCapabilities();
    }
    return {};
  }
  
  /// Helpers para verificar plataforma atual
  
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;
  static bool get isAndroid => !kIsWeb;
  static bool get isIOS => !kIsWeb;
  
  /// Debug info
  static Map<String, dynamic> getDebugInfo() {
    return {
      'platform': kIsWeb ? 'web' : 'mobile',
      'implementationType': _instance.runtimeType.toString(),
      'capabilities': {
        'multipleWindows': supportsMultipleWindows,
        'fullscreen': supportsFullscreen,
        'broadcastChannel': supportsBroadcastChannel,
        'physicalDisplays': supportsPhysicalDisplays,
        'wirelessCasting': supportsWirelessCasting,
      },
      'screenDimensions': screenDimensions,
      'userAgent': userAgent,
    };
  }
}