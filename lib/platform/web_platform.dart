import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_interface.dart';

/// Implementação web da PlatformInterface
/// Usa APIs do browser como html.window, BroadcastChannel, etc.
class WebPlatform implements PlatformInterface {
  html.BroadcastChannel? _broadcastChannel;
  StreamSubscription<html.MessageEvent>? _displayEventSubscription;
  Function(Map<String, dynamic>)? _onDisplayEvent;

  @override
  String getCurrentUrl() {
    return html.window.location.href;
  }

  @override
  bool openWindow(String url, {Map<String, dynamic>? options}) {
    try {
      final features = <String>[];
      
      if (options != null) {
        if (options['width'] != null) features.add('width=${options['width']}');
        if (options['height'] != null) features.add('height=${options['height']}');
        if (options['left'] != null) features.add('left=${options['left']}');
        if (options['top'] != null) features.add('top=${options['top']}');
      }
      
      // Adicionar configurações padrão para janela de projeção
      features.addAll([
        'scrollbars=no',
        'toolbar=no',
        'menubar=no',
        'location=no',
        'directories=no',
        'status=no',
      ]);

      final window = html.window.open(url, 'versee_projection', features.join(','));
      return window != null && !window.closed!;
    } catch (e) {
      return false;
    }
  }

  @override
  bool get supportsMultipleWindows => true;

  @override
  bool get supportsFullscreen {
    try {
      return html.document.documentElement?.requestFullscreen != null;
    } catch (e) {
      return false;
    }
  }

  @override
  bool get supportsBroadcastChannel {
    try {
      return js_util.hasProperty(html.window, 'BroadcastChannel');
    } catch (e) {
      return false;
    }
  }

  @override
  String get userAgent {
    try {
      return html.window.navigator.userAgent ?? 'Unknown';
    } catch (e) {
      return 'Flutter Web';
    }
  }

  @override
  bool get supportsPhysicalDisplays {
    // Web pode detectar múltiplos monitores via Screen API (experimental)
    try {
      return html.window.screen != null && 
             js_util.hasProperty(html.window.screen!, 'getScreens');
    } catch (e) {
      return false;
    }
  }

  @override
  bool get supportsWirelessCasting => false; // Web não suporta casting nativo

  @override
  Map<String, int> get screenDimensions {
    try {
      return {
        'width': html.window.screen?.width ?? 1920,
        'height': html.window.screen?.height ?? 1080,
        'availWidth': html.window.screen?.available?.width?.round() ?? 1920,
        'availHeight': html.window.screen?.available?.height?.round() ?? 1080,
      };
    } catch (e) {
      return {'width': 1920, 'height': 1080, 'availWidth': 1920, 'availHeight': 1080};
    }
  }

  @override
  Future<dynamic> executeNativeCode(String code, {Map<String, dynamic>? params}) async {
    try {
      // No web, executar JavaScript
      if (params != null) {
        // Passar parâmetros para o contexto JavaScript
        for (final entry in params.entries) {
          js.context[entry.key] = entry.value;
        }
      }
      
      return js.context.callMethod('eval', [code]);
    } catch (e) {
      throw Exception('Erro ao executar código JavaScript: $e');
    }
  }

  @override
  void setupDisplayListeners(Function(Map<String, dynamic>) onDisplayEvent) {
    _onDisplayEvent = onDisplayEvent;
    
    try {
      if (supportsBroadcastChannel) {
        _broadcastChannel = html.BroadcastChannel('versee-display-events');
        _displayEventSubscription = _broadcastChannel!.onMessage.listen((event) {
          try {
            final data = event.data;
            if (data is Map) {
              _onDisplayEvent!(Map<String, dynamic>.from(data));
            }
          } catch (e) {
            // Ignore malformed messages
          }
        });
      }
      
      // Listener para mudanças de resolução/orientação
      html.window.addEventListener('resize', (event) {
        _onDisplayEvent!({
          'type': 'screen_change',
          'dimensions': screenDimensions,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      });
      
    } catch (e) {
      // Falha silenciosa se BroadcastChannel não estiver disponível
    }
  }

  @override
  void removeDisplayListeners() {
    try {
      _displayEventSubscription?.cancel();
      _broadcastChannel?.close();
      _displayEventSubscription = null;
      _broadcastChannel = null;
      _onDisplayEvent = null;
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  @override
  Future<bool> checkNetworkConnectivity() async {
    try {
      return html.window.navigator.onLine ?? true;
    } catch (e) {
      return true; // Assume connected on error
    }
  }

  @override
  Future<void> saveLocalData(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      // Fallback to localStorage
      html.window.localStorage[key] = value;
    }
  }

  @override
  Future<String?> loadLocalData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      // Fallback to localStorage
      return html.window.localStorage[key];
    }
  }

  @override
  Future<void> removeLocalData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      // Fallback to localStorage
      html.window.localStorage.remove(key);
    }
  }

  /// Métodos específicos para web

  /// Envia evento via BroadcastChannel
  void sendBroadcastMessage(Map<String, dynamic> message) {
    try {
      if (_broadcastChannel != null) {
        _broadcastChannel!.postMessage(message);
      }
    } catch (e) {
      // Ignore send failures
    }
  }

  /// Obtém capabilities específicas do browser
  Map<String, bool> getBrowserCapabilities() {
    return {
      'fullscreen': supportsFullscreen,
      'broadcastChannel': supportsBroadcastChannel,
      'multipleWindows': supportsMultipleWindows,
      'physicalDisplays': supportsPhysicalDisplays,
      'serviceWorker': html.window.navigator.serviceWorker != null,
      'webRTC': js_util.hasProperty(html.window, 'RTCPeerConnection'),
      'webGL': _checkWebGLSupport(),
    };
  }

  bool _checkWebGLSupport() {
    try {
      final canvas = html.CanvasElement();
      final context = canvas.getContext('webgl') ?? canvas.getContext('experimental-webgl');
      return context != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtém informações detalhadas da tela
  Map<String, dynamic> getDetailedScreenInfo() {
    try {
      final screen = html.window.screen;
      return {
        'width': screen?.width,
        'height': screen?.height,
        'availWidth': screen?.available?.width,
        'availHeight': screen?.available?.height,
        'colorDepth': screen?.colorDepth,
        'pixelDepth': screen?.pixelDepth,
        'orientation': screen?.orientation?.type,
        'devicePixelRatio': html.window.devicePixelRatio,
      };
    } catch (e) {
      return {};
    }
  }

  void dispose() {
    removeDisplayListeners();
  }
}

/// Factory function para criar a implementação web
PlatformInterface createPlatform() {
  return WebPlatform();
}