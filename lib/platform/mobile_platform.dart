import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_interface.dart';

/// Implementação mobile da PlatformInterface  
/// Usa Method Channels para comunicação com código nativo Android/iOS
class MobilePlatform implements PlatformInterface {
  static const MethodChannel _platformChannel = MethodChannel('versee/platform');
  static const MethodChannel _displayChannel = MethodChannel('versee/display_manager');
  
  Function(Map<String, dynamic>)? _onDisplayEvent;
  StreamSubscription<dynamic>? _displayEventSubscription;

  @override
  String getCurrentUrl() {
    // Mobile apps não têm URL tradicional, retornar rota base
    return '/';
  }

  @override
  bool openWindow(String url, {Map<String, dynamic>? options}) {
    // No mobile, "abrir janela" significa navegar para uma nova tela
    // Isso seria implementado via navegação do Flutter, não abertura de janela
    return false; // Mobile não suporta múltiplas janelas independentes
  }

  @override
  bool get supportsMultipleWindows => false; // Mobile não suporta múltiplas janelas

  @override
  bool get supportsFullscreen => true; // Mobile pode usar fullscreen

  @override
  bool get supportsBroadcastChannel => false; // Não há BroadcastChannel nativo

  @override
  String get userAgent {
    return Platform.isAndroid 
        ? 'VERSEE Android ${Platform.operatingSystemVersion}'
        : 'VERSEE iOS ${Platform.operatingSystemVersion}';
  }

  @override
  bool get supportsPhysicalDisplays => true; // Mobile suporta displays externos

  @override
  bool get supportsWirelessCasting => true; // Mobile suporta Chromecast/AirPlay

  Map<String, int> _screenDimensions = {'width': 1080, 'height': 1920, 'availWidth': 1080, 'availHeight': 1920};
  
  @override
  Map<String, int> get screenDimensions => _screenDimensions;

  @override
  Future<dynamic> executeNativeCode(String code, {Map<String, dynamic>? params}) async {
    try {
      if (Platform.isAndroid) {
        return await _platformChannel.invokeMethod('executeNativeCode', {
          'code': code,
          'params': params,
          'platform': 'android',
        });
      } else if (Platform.isIOS) {
        return await _platformChannel.invokeMethod('executeNativeCode', {
          'code': code,
          'params': params,
          'platform': 'ios',
        });
      }
      throw UnsupportedError('Platform not supported: ${Platform.operatingSystem}');
    } catch (e) {
      throw Exception('Erro ao executar código nativo: $e');
    }
  }

  @override
  void setupDisplayListeners(Function(Map<String, dynamic>) onDisplayEvent) {
    _onDisplayEvent = onDisplayEvent;
    
    try {
      // Configurar method call handler para eventos de display
      _displayChannel.setMethodCallHandler(_handleDisplayEvent);
      
      // Solicitar ao código nativo para começar a monitorar displays
      _displayChannel.invokeMethod('startDisplayMonitoring');
      
    } catch (e) {
      // Falha silenciosa se method channel não estiver configurado
    }
  }

  Future<dynamic> _handleDisplayEvent(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onDisplayConnected':
          _onDisplayEvent?.call({
            'type': 'display_connected',
            'displayData': call.arguments,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          break;
          
        case 'onDisplayDisconnected':
          _onDisplayEvent?.call({
            'type': 'display_disconnected',
            'displayId': call.arguments,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          break;
          
        case 'onCastDeviceFound':
          _onDisplayEvent?.call({
            'type': 'cast_device_found',
            'deviceData': call.arguments,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          break;
          
        case 'onCastDeviceLost':
          _onDisplayEvent?.call({
            'type': 'cast_device_lost',
            'deviceId': call.arguments,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          break;
          
        case 'onScreenOrientationChanged':
          _onDisplayEvent?.call({
            'type': 'screen_orientation_changed',
            'orientation': call.arguments,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          break;
          
        default:
          // Evento desconhecido, ignorar
          break;
      }
    } catch (e) {
      // Ignore event processing errors
    }
  }

  @override
  void removeDisplayListeners() {
    try {
      _displayChannel.setMethodCallHandler(null);
      _displayChannel.invokeMethod('stopDisplayMonitoring');
      _displayEventSubscription?.cancel();
      _displayEventSubscription = null;
      _onDisplayEvent = null;
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  @override
  Future<bool> checkNetworkConnectivity() async {
    try {
      final result = await _platformChannel.invokeMethod('checkNetworkConnectivity');
      return result as bool? ?? false;
    } catch (e) {
      // Fallback: tentar fazer uma verificação simples
      try {
        final result = await InternetAddress.lookup('google.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (e) {
        return false;
      }
    }
  }

  @override
  Future<void> saveLocalData(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      throw Exception('Erro ao salvar dados locais: $e');
    }
  }

  @override
  Future<String?> loadLocalData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> removeLocalData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      // Ignore removal errors
    }
  }

  /// Métodos específicos para mobile

  /// Escanear por dispositivos Chromecast (Android)
  Future<List<Map<String, dynamic>>> scanChromecastDevices() async {
    if (!Platform.isAndroid) return [];
    
    try {
      final result = await _displayChannel.invokeMethod('scanChromecastDevices');
      return List<Map<String, dynamic>>.from(result ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Escanear por dispositivos AirPlay (iOS)
  Future<List<Map<String, dynamic>>> scanAirPlayDevices() async {
    if (!Platform.isIOS) return [];
    
    try {
      final result = await _displayChannel.invokeMethod('scanAirPlayDevices');
      return List<Map<String, dynamic>>.from(result ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Conectar a dispositivo Chromecast
  Future<bool> connectToChromecast(String deviceId, {String? appId}) async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _displayChannel.invokeMethod('connectToChromecast', {
        'deviceId': deviceId,
        'appId': appId ?? 'CC1AD845', // Default receiver app ID
      });
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Conectar a dispositivo AirPlay
  Future<bool> connectToAirPlay(String identifier) async {
    if (!Platform.isIOS) return false;
    
    try {
      final result = await _displayChannel.invokeMethod('connectToAirPlay', {
        'identifier': identifier,
      });
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Desconectar de dispositivo de casting
  Future<bool> disconnectFromCasting() async {
    try {
      if (Platform.isAndroid) {
        final result = await _displayChannel.invokeMethod('disconnectChromecast');
        return result as bool? ?? false;
      } else if (Platform.isIOS) {
        final result = await _displayChannel.invokeMethod('disconnectAirPlay');
        return result as bool? ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obter displays físicos conectados
  Future<List<Map<String, dynamic>>> getPhysicalDisplays() async {
    try {
      final result = await _displayChannel.invokeMethod('getPhysicalDisplays');
      return List<Map<String, dynamic>>.from(result ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Testar conexão com display
  Future<bool> testDisplayConnection(String displayId) async {
    try {
      final result = await _displayChannel.invokeMethod('testDisplayConnection', {
        'displayId': displayId,
      });
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Obter informações de diagnóstico da plataforma
  Future<Map<String, dynamic>> getPlatformDiagnosticInfo() async {
    try {
      final result = await _platformChannel.invokeMethod('getDiagnosticInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      return {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'error': e.toString(),
      };
    }
  }

  /// Obter capabilities da plataforma mobile
  Map<String, bool> getMobileCapabilities() {
    return {
      'physicalDisplays': supportsPhysicalDisplays,
      'wirelessCasting': supportsWirelessCasting,
      'chromecast': Platform.isAndroid,
      'airplay': Platform.isIOS,
      'fullscreen': supportsFullscreen,
      'nativeIntegration': true,
      'methodChannels': true,
    };
  }

  /// Inicializar platform-specific features
  Future<void> initialize() async {
    try {
      // Configurar listeners
      setupDisplayListeners((event) {
        // Default empty handler - será sobrescrito quando necessário
      });
      
      // Obter informações da tela
      await _updateScreenDimensions();
      
    } catch (e) {
      // Initialization failures são não-críticos
    }
  }

  Future<void> _updateScreenDimensions() async {
    try {
      final result = await _platformChannel.invokeMethod('getScreenDimensions');
      if (result is Map<String, dynamic>) {
        _screenDimensions = {
          'width': (result['width'] ?? 1080) as int,
          'height': (result['height'] ?? 1920) as int,
          'availWidth': (result['width'] ?? 1080) as int,
          'availHeight': (result['height'] ?? 1920) as int,
        };
      }
    } catch (e) {
      // Use default values - já inicializados
    }
  }

  void dispose() {
    removeDisplayListeners();
  }
}

/// Factory function para criar a implementação mobile
PlatformInterface createPlatform() {
  final mobilePlatform = MobilePlatform();
  // Inicializar features mobile-specific de forma assíncrona
  mobilePlatform.initialize();
  return mobilePlatform;
}