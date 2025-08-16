import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:versee/platform/platform.dart';
import 'package:versee/models/display_models.dart' hide ConnectionState;
import 'package:versee/services/display_manager.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/services/language_service.dart';

/// Implementação cross-platform do DisplayManager para web
/// Usa abstração de plataforma para compatibilidade com mobile
class CrossPlatformWebDisplayManager extends BaseDisplayManager {
  Timer? _connectionCheckTimer;
  Timer? _discoveryTimer;
  final Map<String, dynamic> _displayStates = {};
  LanguageService? _languageService;
  
  static const String _projectionUrl = '/projection';
  static const String _savedDisplaysKey = 'cross_platform_web_saved_displays';
  
  void setLanguageService(LanguageService languageService) {
    _languageService = languageService;
  }

  @override
  Future<void> initialize() async {
    debugLog('🌐 Inicializando CrossPlatformWebDisplayManager');
    
    try {
      // Verificar capabilities da plataforma
      await _checkPlatformCapabilities();
      
      // Carregar displays salvos
      await _loadSavedDisplays();
      
      // Configurar listeners para comunicação cross-tab (apenas web)
      if (PlatformUtils.isWeb) {
        _setupCommunication();
      }
      
      // Iniciar discovery automático
      _startBackgroundDiscovery();
      
      debugLog('✅ CrossPlatformWebDisplayManager inicializado com sucesso');
    } catch (e) {
      debugLog('❌ Erro ao inicializar CrossPlatformWebDisplayManager: $e');
      throw DisplayManagerException(
        'Falha ao inicializar cross-platform web display manager', 
        originalError: e
      );
    }
  }

  Future<void> _checkPlatformCapabilities() async {
    final capabilities = <String, bool>{};
    
    capabilities['multipleWindows'] = PlatformUtils.supportsMultipleWindows;
    capabilities['fullscreen'] = PlatformUtils.supportsFullscreen;
    capabilities['broadcastChannel'] = PlatformUtils.supportsBroadcastChannel;
    capabilities['physicalDisplays'] = PlatformUtils.supportsPhysicalDisplays;
    capabilities['wirelessCasting'] = PlatformUtils.supportsWirelessCasting;
    
    if (PlatformUtils.isWeb) {
      final browserCaps = PlatformUtils.getBrowserCapabilities();
      capabilities.addAll(browserCaps);
    }
    
    debugLog('🔍 Platform capabilities: $capabilities');
  }

  void _setupCommunication() {
    if (!PlatformUtils.isWeb) return;
    
    try {
      // Configurar listener para eventos de display
      PlatformUtils.setupDisplayListeners((event) {
        _handleDisplayEvent(event);
      });
      
      debugLog('💬 Comunicação cross-tab configurada');
    } catch (e) {
      debugLog('❌ Erro ao configurar comunicação: $e');
    }
  }

  void _handleDisplayEvent(Map<String, dynamic> event) {
    try {
      final type = event['type'] as String?;
      
      switch (type) {
        case 'display_ready':
          final displayId = event['displayId'] as String?;
          if (displayId != null) {
            updateDisplayState(displayId, DisplayConnectionState.connected);
          }
          break;
          
        case 'display_error':
          final displayId = event['displayId'] as String?;
          final message = event['message'] as String?;
          if (displayId != null) {
            updateDisplayState(displayId, DisplayConnectionState.error, message: message);
          }
          break;
          
        case 'presentation_event':
          _handlePresentationEvent(event);
          break;
      }
    } catch (e) {
      debugLog('❌ Erro ao processar evento de display: $e');
    }
  }

  void _handlePresentationEvent(Map<String, dynamic> event) {
    debugLog('🎬 Evento de apresentação recebido: ${event['event']}');
  }

  @override
  Future<List<ExternalDisplay>> scanForDisplays({Duration? timeout}) async {
    debugLog('🔍 Escaneando displays...');
    
    final displays = <ExternalDisplay>[];
    
    try {
      // 1. Display principal (sempre disponível)
      displays.add(ExternalDisplay(
        id: 'main_window',
        name: _getLocalizedString('mainDisplay', 'Tela Principal'),
        type: DisplayType.webWindow,
        state: DisplayConnectionState.connected,
        capabilities: [
          DisplayCapability.images,
          DisplayCapability.video,
          DisplayCapability.audio,
          DisplayCapability.slideSync,
          DisplayCapability.remoteControl,
        ],
        metadata: {
          'isMainWindow': true,
          'url': PlatformUtils.getCurrentUrl(),
        },
      ));

      // 2. Aba/janela secundária (web)
      if (PlatformUtils.supportsMultipleWindows) {
        displays.add(ExternalDisplay(
          id: 'secondary_tab',
          name: _getLocalizedString('secondaryTab', 'Aba Secundária'),
          type: DisplayType.webWindow,
          state: _displayStates['secondary_tab']?['isOpen'] == true 
              ? DisplayConnectionState.connected 
              : DisplayConnectionState.detected,
          capabilities: [
            DisplayCapability.images,
            DisplayCapability.video,
            DisplayCapability.audio,
            DisplayCapability.slideSync,
            DisplayCapability.remoteControl,
          ],
          metadata: {
            'requiresPopupPermission': true,
            'canFullscreen': PlatformUtils.supportsFullscreen,
          },
        ));
      }

      // 3. Monitor secundário físico (se suportado)
      if (PlatformUtils.supportsPhysicalDisplays) {
        final screenDimensions = PlatformUtils.screenDimensions;
        
        // Heurística simples para detectar possível monitor secundário
        if (screenDimensions['width']! > 2560) { // Resolução alta pode indicar multi-monitor
          displays.add(ExternalDisplay(
            id: 'secondary_monitor',
            name: _getLocalizedString('secondaryMonitor', 'Monitor Secundário'),
            type: DisplayType.webWindow,
            state: DisplayConnectionState.detected,
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
              'isPhysical': true,
              'detectionMethod': 'heuristic',
            },
          ));
        }
      }

      updateAvailableDisplays(displays);
      debugLog('✅ Encontrados ${displays.length} displays');
      
    } catch (e) {
      debugLog('❌ Erro durante scan de displays: $e');
    }
    
    return displays;
  }

  @override
  Future<bool> connectToDisplay(String displayId, {DisplayConnectionConfig? config}) async {
    debugLog('🔗 Conectando ao display: $displayId');
    
    try {
      final display = availableDisplays.firstWhere((d) => d.id == displayId);
      
      switch (displayId) {
        case 'main_window':
          setConnectedDisplay(display.copyWith(state: DisplayConnectionState.connected));
          debugLog('✅ Conectado à tela principal');
          return true;
          
        case 'secondary_tab':
        case 'secondary_monitor':
          return await _openProjectionWindow(display, config);
          
        default:
          throw DisplayManagerException('Display ID desconhecido: $displayId');
      }
    } catch (e) {
      debugLog('❌ Erro ao conectar ao display $displayId: $e');
      updateDisplayState(displayId, DisplayConnectionState.error, message: e.toString());
      return false;
    }
  }

  Future<bool> _openProjectionWindow(ExternalDisplay display, DisplayConnectionConfig? config) async {
    try {
      // Construir URL de projeção
      final baseUrl = _getCurrentBaseUrl();
      final projectionUrl = '$baseUrl$_projectionUrl?display=${display.id}&mode=projection';
      
      // Opções para abrir janela
      final options = <String, dynamic>{
        'width': 1920,
        'height': 1080,
        'left': 100,
        'top': 100,
      };

      // Se é monitor secundário, tentar posicionar na tela secundária
      if (display.id == 'secondary_monitor') {
        final screenDimensions = PlatformUtils.screenDimensions;
        options['left'] = screenDimensions['width']!; // Posicionar no monitor da direita
        options['top'] = 0;
      }

      // Abrir janela/tab
      final success = PlatformUtils.openWindow(projectionUrl, options: options);
      
      if (success) {
        // Atualizar estado
        updateDisplayState(display.id, DisplayConnectionState.connecting);
        setConnectedDisplay(display.copyWith(state: DisplayConnectionState.connecting));
        
        // Armazenar estado da janela
        _displayStates[display.id] = {
          'isOpen': true,
          'url': projectionUrl,
          'openedAt': DateTime.now().millisecondsSinceEpoch,
        };
        
        // Aguardar confirmação de conexão
        await _waitForWindowReady(display.id);
        
        updateDisplayState(display.id, DisplayConnectionState.connected);
        setConnectedDisplay(display.copyWith(state: DisplayConnectionState.connected));
        
        debugLog('✅ Janela de projeção aberta com sucesso');
        return true;
      } else {
        throw DisplayManagerException('Falha ao abrir janela - popup pode estar bloqueado');
      }
      
    } catch (e) {
      debugLog('❌ Erro ao abrir janela de projeção: $e');
      updateDisplayState(display.id, DisplayConnectionState.error, message: e.toString());
      return false;
    }
  }

  Future<void> _waitForWindowReady(String displayId) async {
    final completer = Completer<void>();
    late StreamSubscription subscription;
    
    subscription = displayStateStream.listen((event) {
      if (event.display.id == displayId && 
          (event.newState == DisplayConnectionState.connected || 
           event.newState == DisplayConnectionState.error)) {
        subscription.cancel();
        if (event.newState == DisplayConnectionState.connected) {
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

  String _getCurrentBaseUrl() {
    try {
      final currentUrl = PlatformUtils.getCurrentUrl();
      final uri = Uri.parse(currentUrl);
      return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
    } catch (e) {
      debugLog('❌ Erro ao obter URL base: $e');
      return 'http://localhost:8080'; // Fallback para desenvolvimento
    }
  }

  @override
  Future<void> disconnect() async {
    debugLog('🔌 Desconectando display');
    
    try {
      // Limpar estados das janelas
      _displayStates.clear();
      
      setConnectedDisplay(null);
      setPresentationState(false);
      
      debugLog('✅ Display desconectado com sucesso');
    } catch (e) {
      debugLog('❌ Erro ao desconectar: $e');
    }
  }

  @override
  Future<bool> startPresentation(PresentationItem item) async {
    if (!hasConnectedDisplay) {
      throw DisplayManagerException('Nenhum display conectado');
    }
    
    try {
      debugLog('🎬 Iniciando apresentação: ${item.title}');
      
      // Enviar dados para janela de projeção
      await _sendToProjectionWindow({
        'type': 'start_presentation',
        'item': _serializePresentationItem(item),
        'settings': {
          'fontSize': fontSize,
          'textColor': textColor.value,
          'backgroundColor': backgroundColor.value,
          'textAlignment': textAlignment.index,
        },
      });
      
      setPresentationState(true, item: item);
      updateDisplayState(connectedDisplay!.id, DisplayConnectionState.presenting);
      
      debugLog('✅ Apresentação iniciada com sucesso');
      return true;
      
    } catch (e) {
      debugLog('❌ Erro ao iniciar apresentação: $e');
      throw DisplayManagerException('Falha ao iniciar apresentação', originalError: e);
    }
  }

  @override
  Future<void> stopPresentation() async {
    debugLog('⏹️ Parando apresentação');
    
    try {
      await _sendToProjectionWindow({'type': 'stop_presentation'});
      setPresentationState(false);
      
      if (hasConnectedDisplay) {
        updateDisplayState(connectedDisplay!.id, DisplayConnectionState.connected);
      }
      
      debugLog('✅ Apresentação parada com sucesso');
    } catch (e) {
      debugLog('❌ Erro ao parar apresentação: $e');
    }
  }

  @override
  Future<void> updatePresentation(PresentationItem item) async {
    if (!isPresenting) return;
    
    try {
      await _sendToProjectionWindow({
        'type': 'update_presentation',
        'item': _serializePresentationItem(item),
      });
      
      setPresentationState(true, item: item);
      debugLog('🔄 Apresentação atualizada');
    } catch (e) {
      debugLog('❌ Erro ao atualizar apresentação: $e');
    }
  }

  @override
  Future<void> toggleBlackScreen(bool active) async {
    await super.toggleBlackScreen(active);
    
    await _sendToProjectionWindow({
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
    
    await _sendToProjectionWindow({
      'type': 'update_settings',
      'settings': {
        'fontSize': this.fontSize,
        'textColor': this.textColor.value,
        'backgroundColor': this.backgroundColor.value,
        'textAlignment': this.textAlignment.index,
      },
    });
  }

  Future<void> _sendToProjectionWindow(Map<String, dynamic> message) async {
    try {
      message['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      message['source'] = 'main_window';
      
      // Usar storage para comunicação cross-tab
      await PlatformUtils.saveLocalData('versee_display_message', jsonEncode(message));
      
      // Se estiver na web, também enviar via BroadcastChannel
      if (PlatformUtils.isWeb && PlatformUtils.supportsBroadcastChannel) {
        PlatformUtils.sendBroadcastMessage(message);
      }
      
    } catch (e) {
      debugLog('❌ Erro ao enviar mensagem para janela: $e');
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
      final savedData = await PlatformUtils.loadLocalData(_savedDisplaysKey);
      if (savedData != null) {
        // TODO: Implementar deserialização de displays salvos
        debugLog('📂 Displays salvos carregados');
      }
    } catch (e) {
      debugLog('❌ Erro ao carregar displays salvos: $e');
    }
  }

  @override
  Future<void> saveDisplayConfig(DisplayConnectionConfig config) async {
    try {
      final key = 'display_config_${config.displayId}';
      final configJson = jsonEncode(config.toMap());
      await PlatformUtils.saveLocalData(key, configJson);
      debugLog('💾 Configuração salva para display ${config.displayId}');
    } catch (e) {
      debugLog('❌ Erro ao salvar configuração: $e');
    }
  }

  @override
  Future<DisplayConnectionConfig?> loadDisplayConfig(String displayId) async {
    try {
      final key = 'display_config_$displayId';
      final data = await PlatformUtils.loadLocalData(key);
      if (data != null) {
        final configMap = jsonDecode(data) as Map<String, dynamic>;
        return DisplayConnectionConfig.fromMap(configMap);
      }
    } catch (e) {
      debugLog('❌ Erro ao carregar configuração: $e');
    }
    return null;
  }

  @override
  Future<void> removeDisplayConfig(String displayId) async {
    try {
      final key = 'display_config_$displayId';
      await PlatformUtils.removeLocalData(key);
      debugLog('🗑️ Configuração removida para display $displayId');
    } catch (e) {
      debugLog('❌ Erro ao remover configuração: $e');
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
      debugLog('🧪 Testando conexão com display $displayId');
      
      if (displayId == 'main_window') {
        return true;
      }
      
      if (_displayStates[displayId]?['isOpen'] == true) {
        return true;
      }
      
      return false;
    } catch (e) {
      debugLog('❌ Erro ao testar conexão: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final platformInfo = await PlatformUtils.getPlatformDiagnosticInfo();
    
    return {
      'manager': 'CrossPlatformWebDisplayManager',
      'connectedDisplayId': connectedDisplay?.id,
      'isPresenting': isPresenting,
      'availableDisplaysCount': availableDisplays.length,
      'openWindows': _displayStates.length,
      'platformInfo': platformInfo,
      ...PlatformUtils.getDebugInfo(),
    };
  }

  @override
  Future<void> reset() async {
    debugLog('🔄 Resetando CrossPlatformWebDisplayManager');
    
    await disconnect();
    _connectionCheckTimer?.cancel();
    _discoveryTimer?.cancel();
    
    if (PlatformUtils.isWeb) {
      PlatformUtils.removeDisplayListeners();
    }
    
    await initialize();
  }

  String _getLocalizedString(String key, String fallback) {
    if (_languageService != null) {
      // TODO: Usar sistema de localização quando disponível
      return fallback;
    }
    return fallback;
  }

  @override
  void dispose() {
    debugLog('🗑️ Disposing CrossPlatformWebDisplayManager');
    
    _connectionCheckTimer?.cancel();
    _discoveryTimer?.cancel();
    
    if (PlatformUtils.isWeb) {
      PlatformUtils.removeDisplayListeners();
    }
    
    super.dispose();
  }
}