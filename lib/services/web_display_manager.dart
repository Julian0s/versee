import 'dart:async';
import 'package:flutter/foundation.dart';
// Web-specific imports with conditional compilation
import 'dart:js_interop' if (dart.library.io) 'dart:core';
import 'dart:js_util' as js_util if (dart.library.io) 'dart:core';
// import 'dart:html' as web if (dart.library.io) 'dart:core';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versee/models/display_models.dart';
import 'package:versee/services/display_manager.dart';
import 'package:versee/services/playlist_service.dart';

/// Implementação web do DisplayManager usando múltiplas janelas do browser
class WebDisplayManager extends BaseDisplayManager {
  dynamic _projectionWindow;
  dynamic _broadcastChannel;
  Timer? _connectionCheckTimer;
  Timer? _discoveryTimer;
  
  static const String _channelName = 'versee-presentation';
  static const String _projectionUrl = '/projection';
  static const String _savedDisplaysKey = 'web_saved_displays';

  @override
  Future<void> initialize() async {
    debugLog('Inicializando WebDisplayManager');
    
    try {
      // Configurar BroadcastChannel para comunicação entre janelas
      if (kIsWeb && js_util.hasProperty(web.window, 'BroadcastChannel')) {
        _broadcastChannel = js_util.callConstructor(js_util.getProperty(web.window, 'BroadcastChannel'), [_channelName]);
        _broadcastChannel!.addEventListener('message', _handleBroadcastMessage.toJS);
      }
      
      // Verificar se há displays salvos
      await _loadSavedDisplays();
      
      // Iniciar discovery automático
      _startBackgroundDiscovery();
      
      debugLog('WebDisplayManager inicializado com sucesso');
    } catch (e) {
      debugLog('Erro ao inicializar WebDisplayManager: $e');
      throw DisplayManagerException('Falha ao inicializar web display manager', originalError: e);
    }
  }

  @override
  Future<List<ExternalDisplay>> scanForDisplays({Duration? timeout}) async {
    debugLog('Escaneando displays web...');
    
    final displays = <ExternalDisplay>[];
    
    try {
      // Display principal (janela atual)
      displays.add(ExternalDisplay(
        id: 'main_window',
        name: 'Janela Principal',
        type: DisplayType.webWindow,
        state: ConnectionState.connected,
        capabilities: [
          DisplayCapability.images,
          DisplayCapability.video,
          DisplayCapability.audio,
          DisplayCapability.slideSync,
          DisplayCapability.remoteControl,
        ],
        metadata: {
          'isMainWindow': true,
          'url': html.window.location.href,
        },
      ));

      // Verificar se há suporte a múltiplos monitores (Screen API experimental)
      if (kIsWeb && js_util.hasProperty(web.window.screen, 'getScreens')) {
        try {
          debugLog('Screen API detectada - múltiplos monitores podem estar disponíveis');
          
          displays.add(ExternalDisplay(
            id: 'secondary_monitor',
            name: 'Monitor Secundário',
            type: DisplayType.webWindow,
            state: ConnectionState.detected,
            capabilities: [
              DisplayCapability.images,
              DisplayCapability.video,
              DisplayCapability.audio,
              DisplayCapability.slideSync,
              DisplayCapability.remoteControl,
              DisplayCapability.highQuality,
            ],
            metadata: {
              'requiresUserAction': true,
              'isSecondaryMonitor': true,
            },
          ));
        } catch (e) {
          debugLog('Screen API não disponível ou com erro: $e');
        }
      }

      // Display de janela popup (sempre disponível)
      displays.add(ExternalDisplay(
        id: 'popup_window',
        name: 'Janela de Projeção',
        type: DisplayType.webWindow,
        state: _projectionWindow?.closed == false 
            ? ConnectionState.connected 
            : ConnectionState.detected,
        capabilities: [
          DisplayCapability.images,
          DisplayCapability.video,
          DisplayCapability.audio,
          DisplayCapability.slideSync,
          DisplayCapability.remoteControl,
        ],
        metadata: {
          'requiresPopupPermission': true,
          'canFullscreen': true,
        },
      ));

      updateAvailableDisplays(displays);
      debugLog('Encontrados ${displays.length} displays web');
      
    } catch (e) {
      debugLog('Erro durante scan de displays: $e');
    }
    
    return displays;
  }

  @override
  Future<bool> connectToDisplay(String displayId, {DisplayConnectionConfig? config}) async {
    debugLog('Conectando ao display: $displayId');
    
    try {
      final display = availableDisplays.firstWhere((d) => d.id == displayId);
      
      switch (displayId) {
        case 'main_window':
          setConnectedDisplay(display.copyWith(state: ConnectionState.connected));
          debugLog('Conectado à janela principal');
          return true;
          
        case 'popup_window':
        case 'secondary_monitor':
          return await _openProjectionWindow(display, config);
          
        default:
          throw DisplayManagerException('Display ID desconhecido: $displayId');
      }
    } catch (e) {
      debugLog('Erro ao conectar ao display $displayId: $e');
      updateDisplayState(displayId, ConnectionState.error, message: e.toString());
      return false;
    }
  }

  Future<bool> _openProjectionWindow(ExternalDisplay display, DisplayConnectionConfig? config) async {
    try {
      // Fechar janela anterior se existir
      if (_projectionWindow != null && !_projectionWindow!.closed!) {
        _projectionWindow!.close();
      }

      // Configurações da janela
      final features = [
        'width=1920',
        'height=1080',
        'left=100',
        'top=100',
        'scrollbars=no',
        'toolbar=no',
        'menubar=no',
        'location=no',
        'directories=no',
        'status=no',
      ].join(',');

      // Abrir nova janela
      final baseUrl = html.window.location.origin;
      final projectionUrl = '$baseUrl$_projectionUrl?display=${display.id}';
      
      _projectionWindow = html.window.open(projectionUrl, 'versee_projection', features);
      
      if (_projectionWindow == null || _projectionWindow!.closed!) {
        throw DisplayManagerException('Falha ao abrir janela - popup pode estar bloqueado');
      }

      // Configurar comunicação
      _setupWindowCommunication();
      
      // Atualizar estado
      updateDisplayState(display.id, ConnectionState.connecting);
      setConnectedDisplay(display.copyWith(state: ConnectionState.connecting));
      
      // Aguardar confirmação de conexão
      await _waitForWindowReady();
      
      updateDisplayState(display.id, ConnectionState.connected);
      setConnectedDisplay(display.copyWith(state: ConnectionState.connected));
      
      debugLog('Janela de projeção aberta com sucesso');
      return true;
      
    } catch (e) {
      debugLog('Erro ao abrir janela de projeção: $e');
      updateDisplayState(display.id, ConnectionState.error, message: e.toString());
      return false;
    }
  }

  void _setupWindowCommunication() {
    // Timer para verificar se a janela ainda está aberta
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_projectionWindow?.closed == true) {
        _handleWindowClosed();
        timer.cancel();
      }
    });
  }

  Future<void> _waitForWindowReady() async {
    final completer = Completer<void>();
    late StreamSubscription subscription;
    
    subscription = displayStateStream.listen((event) {
      if (event.newState == ConnectionState.connected || 
          event.newState == ConnectionState.error) {
        subscription.cancel();
        if (event.newState == ConnectionState.connected) {
          completer.complete();
        } else {
          completer.completeError(event.message ?? 'Falha na conexão');
        }
      }
    });
    
    // Timeout após 10 segundos
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError('Timeout na conexão com janela');
      }
    });
    
    return completer.future;
  }

  void _handleBroadcastMessage(html.MessageEvent event) {
    try {
      final data = event.data as Map<String, dynamic>;
      final type = data['type'] as String?;
      
      switch (type) {
        case 'window_ready':
          final displayId = data['displayId'] as String?;
          if (displayId != null) {
            updateDisplayState(displayId, ConnectionState.connected);
          }
          break;
          
        case 'window_error':
          final displayId = data['displayId'] as String?;
          final message = data['message'] as String?;
          if (displayId != null) {
            updateDisplayState(displayId, ConnectionState.error, message: message);
          }
          break;
          
        case 'presentation_event':
          _handlePresentationEvent(data);
          break;
      }
    } catch (e) {
      debugLog('Erro ao processar mensagem broadcast: $e');
    }
  }

  void _handlePresentationEvent(Map<String, dynamic> data) {
    // Handle presentation events from projection window
    debugLog('Evento de apresentação recebido: ${data['event']}');
  }

  void _handleWindowClosed() {
    debugLog('Janela de projeção fechada');
    
    if (connectedDisplay?.type == DisplayType.webWindow) {
      updateDisplayState(connectedDisplay!.id, ConnectionState.disconnected);
      setConnectedDisplay(null);
      setPresentationState(false);
    }
    
    _projectionWindow = null;
    _connectionCheckTimer?.cancel();
  }

  @override
  Future<void> disconnect() async {
    debugLog('Desconectando display');
    
    try {
      if (_projectionWindow != null && !_projectionWindow!.closed!) {
        _projectionWindow!.close();
      }
      
      _connectionCheckTimer?.cancel();
      setConnectedDisplay(null);
      setPresentationState(false);
      
      debugLog('Display desconectado com sucesso');
    } catch (e) {
      debugLog('Erro ao desconectar: $e');
    }
  }

  @override
  Future<bool> startPresentation(PresentationItem item) async {
    if (!hasConnectedDisplay) {
      throw DisplayManagerException('Nenhum display conectado');
    }
    
    try {
      debugLog('Iniciando apresentação: ${item.title}');
      
      // Enviar comando para janela de projeção
      _sendToProjectionWindow({
        'type': 'start_presentation',
        'item': _serializePresentationItem(item),
        'settings': {
          'fontSize': fontSize,
          'textColor': '#${textColor.value.toRadixString(16).padLeft(8, '0')}',
          'backgroundColor': '#${backgroundColor.value.toRadixString(16).padLeft(8, '0')}',
          'textAlignment': textAlignment.toString().split('.').last,
        },
      });
      
      setPresentationState(true, item: item);
      updateDisplayState(connectedDisplay!.id, ConnectionState.presenting);
      
      debugLog('Apresentação iniciada com sucesso');
      return true;
      
    } catch (e) {
      debugLog('Erro ao iniciar apresentação: $e');
      throw DisplayManagerException('Falha ao iniciar apresentação', originalError: e);
    }
  }

  @override
  Future<void> stopPresentation() async {
    debugLog('Parando apresentação');
    
    try {
      _sendToProjectionWindow({'type': 'stop_presentation'});
      setPresentationState(false);
      
      if (hasConnectedDisplay) {
        updateDisplayState(connectedDisplay!.id, ConnectionState.connected);
      }
      
      debugLog('Apresentação parada com sucesso');
    } catch (e) {
      debugLog('Erro ao parar apresentação: $e');
    }
  }

  @override
  Future<void> updatePresentation(PresentationItem item) async {
    if (!isPresenting) return;
    
    try {
      _sendToProjectionWindow({
        'type': 'update_presentation',
        'item': _serializePresentationItem(item),
      });
      
      setPresentationState(true, item: item);
      debugLog('Apresentação atualizada');
    } catch (e) {
      debugLog('Erro ao atualizar apresentação: $e');
    }
  }

  @override
  Future<void> toggleBlackScreen(bool active) async {
    await super.toggleBlackScreen(active);
    
    _sendToProjectionWindow({
      'type': 'toggle_black_screen',
      'active': active,
    });
  }

  @override
  Future<void> updatePresentationSettings({
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    TextAlign? textAlignment,
  }) async {
    await super.updatePresentationSettings(
      fontSize: fontSize,
      textColor: textColor,
      backgroundColor: backgroundColor,
      textAlignment: textAlignment,
    );
    
    _sendToProjectionWindow({
      'type': 'update_settings',
      'settings': {
        'fontSize': this.fontSize,
        'textColor': '#${this.textColor.value.toRadixString(16).padLeft(8, '0')}',
        'backgroundColor': '#${this.backgroundColor.value.toRadixString(16).padLeft(8, '0')}',
        'textAlignment': this.textAlignment.toString().split('.').last,
      },
    });
  }

  void _sendToProjectionWindow(Map<String, dynamic> message) {
    try {
      if (_broadcastChannel != null) {
        _broadcastChannel!.postMessage(message);
      }
    } catch (e) {
      debugLog('Erro ao enviar mensagem para janela: $e');
    }
  }

  Map<String, dynamic> _serializePresentationItem(PresentationItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'type': item.type.toString().split('.').last,
      'content': item.content,
      'metadata': item.metadata,
    };
  }

  void _startBackgroundDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      scanForDisplays();
    });
  }

  Future<void> _loadSavedDisplays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_savedDisplaysKey);
      if (savedData != null) {
        // TODO: Implementar deserialização de displays salvos
        debugLog('Displays salvos carregados');
      }
    } catch (e) {
      debugLog('Erro ao carregar displays salvos: $e');
    }
  }

  @override
  Future<void> saveDisplayConfig(DisplayConnectionConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'display_config_${config.displayId}';
      await prefs.setString(key, config.toMap().toString());
      debugLog('Configuração salva para display ${config.displayId}');
    } catch (e) {
      debugLog('Erro ao salvar configuração: $e');
    }
  }

  @override
  Future<DisplayConnectionConfig?> loadDisplayConfig(String displayId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'display_config_$displayId';
      final data = prefs.getString(key);
      if (data != null) {
        // TODO: Implementar deserialização
        debugLog('Configuração carregada para display $displayId');
      }
    } catch (e) {
      debugLog('Erro ao carregar configuração: $e');
    }
    return null;
  }

  @override
  Future<void> removeDisplayConfig(String displayId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'display_config_$displayId';
      await prefs.remove(key);
      debugLog('Configuração removida para display $displayId');
    } catch (e) {
      debugLog('Erro ao remover configuração: $e');
    }
  }

  @override
  Future<List<ExternalDisplay>> getSavedDisplays() async {
    // TODO: Implementar carregamento de displays salvos
    return [];
  }

  @override
  Future<List<DisplayCapability>> getDisplayCapabilities(String displayId) async {
    final display = availableDisplays.where((d) => d.id == displayId).firstOrNull;
    return display?.capabilities ?? [];
  }

  @override
  Future<bool> testConnection(String displayId) async {
    try {
      debugLog('Testando conexão com display $displayId');
      
      if (displayId == 'main_window') {
        return true;
      }
      
      if (displayId == 'popup_window' && _projectionWindow != null) {
        return !_projectionWindow!.closed!;
      }
      
      return false;
    } catch (e) {
      debugLog('Erro ao testar conexão: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    return {
      'platform': 'web',
      'hasProjectionWindow': _projectionWindow != null && !_projectionWindow!.closed!,
      'broadcastChannelSupported': _broadcastChannel != null,
      'connectedDisplayId': connectedDisplay?.id,
      'isPresenting': isPresenting,
      'availableDisplaysCount': availableDisplays.length,
      'screenApiSupported': js.context.hasProperty('screen') && 
                            js.context['screen'].hasProperty('getScreens'),
      'popupBlocked': false, // TODO: Detectar se popup está bloqueado
    };
  }

  @override
  Future<void> reset() async {
    debugLog('Resetando WebDisplayManager');
    
    await disconnect();
    _connectionCheckTimer?.cancel();
    _discoveryTimer?.cancel();
    _broadcastChannel?.close();
    
    await initialize();
  }

  @override
  void dispose() {
    debugLog('Disposing WebDisplayManager');
    
    _connectionCheckTimer?.cancel();
    _discoveryTimer?.cancel();
    _broadcastChannel?.close();
    
    if (_projectionWindow != null && !_projectionWindow!.closed!) {
      _projectionWindow!.close();
    }
    
    super.dispose();
  }
}