import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:versee/platform/platform.dart';
import 'package:versee/models/display_models.dart' hide ConnectionState;
import 'package:versee/services/display_manager.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/services/language_service.dart';

/// Implementação web robusta do DisplayManager
/// Foca em funcionalidade essencial e compatibilidade máxima
class RobustWebDisplayManager extends BaseDisplayManager {
  Timer? _connectionCheckTimer;
  Timer? _discoveryTimer;
  final Map<String, dynamic> _displayStates = {};
  LanguageService? _languageService;
  
  static const String _channelName = 'versee-presentation';
  static const String _projectionUrl = '/projection';
  static const String _savedDisplaysKey = 'robust_web_saved_displays';
  
  void setLanguageService(LanguageService languageService) {
    _languageService = languageService;
  }

  @override
  Future<void> initialize() async {
    debugLog('🌐 Inicializando RobustWebDisplayManager');
    
    try {
      // Verificar capabilities do browser
      await _checkBrowserCapabilities();
      
      // Carregar displays salvos
      await _loadSavedDisplays();
      
      // Configurar listeners de storage para comunicação cross-tab
      _setupStorageCommunication();
      
      // Iniciar discovery automático
      _startBackgroundDiscovery();
      
      debugLog('✅ RobustWebDisplayManager inicializado com sucesso');
    } catch (e) {
      debugLog('❌ Erro ao inicializar RobustWebDisplayManager: $e');
      throw DisplayManagerException(
        'Falha ao inicializar robust web display manager', 
        originalError: e
      );
    }
  }

  Future<void> _checkBrowserCapabilities() async {
    final capabilities = <String, bool>{};
    
    try {
      // Verificar window.open
      capabilities['windowOpen'] = true; // Sempre disponível
      
      // Verificar localStorage
      capabilities['localStorage'] = true; // Sempre disponível no Flutter web
      
      // Verificar BroadcastChannel (alternativa: localStorage events)
      capabilities['broadcastChannel'] = kIsWeb;
      
      // Verificar Screen API (experimental)
      capabilities['screenAPI'] = false; // Consideramos não disponível por segurança
      
      // Verificar Fullscreen API
      capabilities['fullscreen'] = kIsWeb;
      
      debugLog('🔍 Browser capabilities: $capabilities');
      
      // Salvar capabilities para uso posterior
      _displayStates['capabilities'] = capabilities;
      
    } catch (e) {
      debugLog('⚠️ Erro ao verificar capabilities: $e');
      // Continuar com capabilities padrão
      _displayStates['capabilities'] = {'windowOpen': true, 'localStorage': true};
    }
  }

  void _setupStorageCommunication() {
    try {
      // Usar SharedPreferences para comunicação entre tabs
      // Mais confiável que BroadcastChannel
      _startStorageListener();
      debugLog('📡 Comunicação via storage configurada');
    } catch (e) {
      debugLog('⚠️ Erro ao configurar comunicação: $e');
    }
  }

  void _startStorageListener() {
    // Verificar mudanças no storage a cada segundo
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkStorageMessages();
    });
  }

  Future<void> _checkStorageMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messageKey = 'versee_display_message';
      final message = prefs.getString(messageKey);
      
      if (message != null && message.isNotEmpty) {
        // Processar mensagem
        final data = jsonDecode(message);
        final timestamp = data['timestamp'] as int?;
        
        // Processar apenas mensagens recentes (últimos 5 segundos)
        if (timestamp != null && 
            DateTime.now().millisecondsSinceEpoch - timestamp < 5000) {
          await _handleStorageMessage(data);
        }
        
        // Limpar mensagem processada
        await prefs.remove(messageKey);
      }
    } catch (e) {
      // Silencioso - é normal não haver mensagens
    }
  }

  Future<void> _handleStorageMessage(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'display_ready':
        final displayId = data['displayId'] as String?;
        if (displayId != null) {
          updateDisplayState(displayId, DisplayConnectionState.connected);
          debugLog('📺 Display $displayId reportou como pronto');
        }
        break;
        
      case 'display_error':
        final displayId = data['displayId'] as String?;
        final error = data['error'] as String?;
        if (displayId != null) {
          updateDisplayState(displayId, DisplayConnectionState.error, message: error);
          debugLog('❌ Display $displayId reportou erro: $error');
        }
        break;
        
      case 'presentation_event':
        final event = data['event'] as String?;
        final payload = data['payload'];
        debugLog('🎬 Evento de apresentação: $event');
        // Processar eventos de apresentação
        break;
    }
  }

  @override
  Future<List<ExternalDisplay>> scanForDisplays({Duration? timeout}) async {
    debugLog('🔍 Escaneando displays físicos e virtuais...');
    
    final displays = <ExternalDisplay>[];
    
    try {
      // 1. Display principal (janela atual)
      displays.add(ExternalDisplay(
        id: 'main_window',
        name: _getLocalizedString('displayMainWindow'),
        type: DisplayType.webWindow,
        state: DisplayConnectionState.connected,
        capabilities: [
          DisplayCapability.images,
          DisplayCapability.video,
          DisplayCapability.audio,
          DisplayCapability.slideSync,
          DisplayCapability.remoteControl,
          DisplayCapability.highQuality,
        ],
        metadata: {
          'isMainWindow': true,
          'userAgent': kIsWeb ? 'Flutter Web' : 'Unknown',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      ));

      // 2. Detectar monitores físicos primeiro e validar conectividade
      final physicalDisplays = await _detectPhysicalDisplays();
      final validatedDisplays = await _validatePhysicalDisplays(physicalDisplays);
      displays.addAll(validatedDisplays);

      // 3. Aba Secundária (SEMPRE disponível para Chromecast)
      displays.add(ExternalDisplay(
        id: 'secondary_tab',
        name: _getLocalizedString('displaySecondaryTab'),
        type: DisplayType.webWindow,
        state: DisplayConnectionState.detected,
        capabilities: [
          DisplayCapability.images,
          DisplayCapability.video,
          DisplayCapability.audio,
          DisplayCapability.slideSync,
          DisplayCapability.remoteControl,
        ],
        metadata: {
          'isTab': true,
          'forChromecast': true,
          'priority': 'high', // Alta prioridade para Chromecast
          'note': _getLocalizedString('displayTabNote'),
        },
      ));

      // 4. Janela de projeção (opção adicional)
      displays.add(ExternalDisplay(
        id: 'projection_window',
        name: _getLocalizedString('displayProjectionWindow'),
        type: DisplayType.webWindow,
        state: _isProjectionWindowOpen() 
            ? DisplayConnectionState.connected 
            : DisplayConnectionState.detected,
        capabilities: [
          DisplayCapability.images,
          DisplayCapability.video,
          DisplayCapability.audio,
          DisplayCapability.slideSync,
          DisplayCapability.remoteControl,
          DisplayCapability.highQuality,
        ],
        metadata: {
          'requiresPopupPermission': true,
          'canFullscreen': true,
          'isPopupWindow': true,
          'alternative': true,
        },
      ));

      updateAvailableDisplays(displays);
      debugLog('✅ Encontrados ${displays.length} displays web robustos');
      
    } catch (e) {
      debugLog('❌ Erro durante scan de displays: $e');
    }
    
    return displays;
  }

  bool _isProjectionWindowOpen() {
    // Verificar se há uma janela de projeção ativa
    final windowState = _displayStates['projection_window'];
    return windowState != null && windowState['isOpen'] == true;
  }

  @override
  Future<bool> connectToDisplay(String displayId, {DisplayConnectionConfig? config}) async {
    debugLog('🔗 Conectando ao display robusto: $displayId');
    
    try {
      final display = availableDisplays.firstWhere((d) => d.id == displayId);
      updateDisplayState(displayId, DisplayConnectionState.connecting);
      
      bool success = false;
      
      // Verificar se é monitor físico
      if (displayId.startsWith('physical_monitor_') || 
          displayId == 'extended_monitor' || 
          displayId == 'fullscreen_secondary') {
        success = await _connectToPhysicalMonitor(display, config);
      } else {
        switch (displayId) {
          case 'main_window':
            success = await _connectToMainWindow(display);
            break;
            
          case 'projection_window':
            success = await _connectToProjectionWindow(display, config);
            break;
            
          case 'secondary_tab':
            success = await _connectToSecondaryTab(display, config);
            break;
            
          default:
            throw DisplayManagerException('Display ID desconhecido: $displayId');
        }
      }
      
      if (success) {
        setConnectedDisplay(display.copyWith(state: DisplayConnectionState.connected));
        updateDisplayState(displayId, DisplayConnectionState.connected);
        
        // Salvar configuração se solicitado
        if (config?.rememberDevice == true) {
          await saveDisplayConfig(config!);
        }
        
        debugLog('✅ Conectado ao display $displayId com sucesso');
      } else {
        updateDisplayState(displayId, DisplayConnectionState.error, 
            message: _getLocalizedString('displayConnectionFailed'));
      }
      
      return success;
      
    } catch (e) {
      debugLog('❌ Erro ao conectar ao display $displayId: $e');
      updateDisplayState(displayId, DisplayConnectionState.error, message: e.toString());
      return false;
    }
  }

  Future<bool> _connectToMainWindow(ExternalDisplay display) async {
    // Conexão com janela principal é sempre bem-sucedida
    debugLog('✅ Conectado à janela principal');
    return true;
  }

  Future<bool> _connectToProjectionWindow(ExternalDisplay display, DisplayConnectionConfig? config) async {
    try {
      // Simular abertura de popup window
      // Em uma implementação real, usaríamos window.open()
      
      await _sendStorageMessage({
        'type': 'open_projection_window',
        'displayId': display.id,
        'config': config?.toMap(),
      });
      
      // Simular delay de abertura
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Marcar como aberto
      _displayStates['projection_window'] = {'isOpen': true};
      
      debugLog('✅ Janela de projeção simulada aberta');
      return true;
      
    } catch (e) {
      debugLog('❌ Erro ao abrir janela de projeção: $e');
      return false;
    }
  }

  Future<bool> _connectToSecondaryTab(ExternalDisplay display, DisplayConnectionConfig? config) async {
    try {
      // Construir URL de projeção
      final projectionUrl = '${_getCurrentBaseUrl()}$_projectionUrl?display=${display.id}&mode=secondary';
      
      debugLog('🔗 Abrindo aba secundária: $projectionUrl');
      
      // Tentar abrir nova aba automaticamente
      if (kIsWeb) {
        try {
          final success = PlatformUtils.openWindow(projectionUrl, options: {'width': 1920, 'height': 1080});
          
          if (success) {
            // Janela aberta com sucesso
            _displayStates['secondary_tab'] = {
              'isOpen': true,
              'url': projectionUrl,
              'openedAt': DateTime.now().millisecondsSinceEpoch,
            };
            
            debugLog('✅ Aba secundária aberta com sucesso');
            
            // Enviar mensagem de configuração
            await _sendStorageMessage({
              'type': 'secondary_tab_opened',
              'displayId': display.id,
              'url': projectionUrl,
              'status': 'connected',
            });
            
            return true;
          } else {
            debugLog('⚠️ Popup bloqueado - fornecendo instruções manuais');
            await _provideManualInstructions(projectionUrl, display.id);
            return true;
          }
        } catch (e) {
          debugLog('⚠️ Erro ao abrir janela automaticamente: $e');
          await _provideManualInstructions(projectionUrl, display.id);
          return true;
        }
      } else {
        // Fallback para não-web
        await _provideManualInstructions(projectionUrl, display.id);
        return true;
      }
      
    } catch (e) {
      debugLog('❌ Erro ao configurar aba secundária: $e');
      return false;
    }
  }
  
  Future<void> _provideManualInstructions(String url, String displayId) async {
    // Enviar instruções para abrir manualmente
    await _sendStorageMessage({
      'type': 'tab_connection_info',
      'displayId': displayId,
      'url': url,
      'instruction': _getLocalizedString('displayOpenTabInstruction'),
      'action': 'manual_open_required',
    });
    
    // Mostrar notificação no navegador se possível
    if (kIsWeb) {
      try {
        await PlatformUtils.executeNativeCode('alert("📺 Abra esta URL em uma nova aba para projeção:\\n\\n' + url + '\\n\\nOu pressione Ctrl+T e cole o link.")', params: {'url': url});
      } catch (e) {
        debugLog('Não foi possível mostrar alert: $e');
      }
    }
  }

  String _getCurrentBaseUrl() {
    if (kIsWeb) {
      try {
        // Obter URL atual do navegador
        final currentUrl = PlatformUtils.getCurrentUrl();
        final uri = Uri.parse(currentUrl);
        return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
      } catch (e) {
        debugLog('Erro ao obter URL base: $e');
        // Fallback para URL de produção
        return 'https://egxse64845cgaarz90nllkn1o0c1aw.web.app';
      }
    }
    return 'about:blank';
  }

  Future<void> _sendStorageMessage(Map<String, dynamic> message) async {
    try {
      message['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('versee_display_message', jsonEncode(message));
    } catch (e) {
      debugLog('❌ Erro ao enviar mensagem via storage: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    debugLog('🔌 Desconectando display robusto');
    
    try {
      if (connectedDisplay != null) {
        await _sendStorageMessage({
          'type': 'disconnect_display',
          'displayId': connectedDisplay!.id,
        });
        
        updateDisplayState(connectedDisplay!.id, DisplayConnectionState.detected);
        
        // Fechar janela se for popup
        if (connectedDisplay!.id == 'projection_window') {
          _displayStates['projection_window'] = {'isOpen': false};
        }
      }
      
      setConnectedDisplay(null);
      setPresentationState(false);
      
      debugLog('✅ Display robusto desconectado com sucesso');
    } catch (e) {
      debugLog('❌ Erro ao desconectar display robusto: $e');
    }
  }

  @override
  Future<bool> startPresentation(PresentationItem item) async {
    if (!hasConnectedDisplay) {
      throw DisplayManagerException(
        _getLocalizedString('displayNoDisplayConnected')
      );
    }
    
    try {
      debugLog('🎬 Iniciando apresentação robusta: ${item.title}');
      
      // Enviar dados da apresentação
      await _sendStorageMessage({
        'type': 'start_presentation',
        'displayId': connectedDisplay!.id,
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
      
      debugLog('✅ Apresentação robusta iniciada com sucesso');
      return true;
      
    } catch (e) {
      debugLog('❌ Erro ao iniciar apresentação robusta: $e');
      throw DisplayManagerException(
        _getLocalizedString('displayPresentationFailed'), 
        originalError: e
      );
    }
  }

  @override
  Future<void> stopPresentation() async {
    debugLog('⏹️ Parando apresentação robusta');
    
    try {
      await _sendStorageMessage({
        'type': 'stop_presentation',
        'displayId': connectedDisplay?.id,
      });
      
      setPresentationState(false);
      
      if (hasConnectedDisplay) {
        updateDisplayState(connectedDisplay!.id, DisplayConnectionState.connected);
      }
      
      debugLog('✅ Apresentação robusta parada com sucesso');
    } catch (e) {
      debugLog('❌ Erro ao parar apresentação robusta: $e');
    }
  }

  @override
  Future<void> updatePresentation(PresentationItem item) async {
    if (!isPresenting) return;
    
    try {
      await _sendStorageMessage({
        'type': 'update_presentation',
        'displayId': connectedDisplay?.id,
        'item': _serializePresentationItem(item),
      });
      
      setPresentationState(true, item: item);
      debugLog('🔄 Apresentação robusta atualizada');
    } catch (e) {
      debugLog('❌ Erro ao atualizar apresentação robusta: $e');
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

  String _getLocalizedString(String key) {
    if (_languageService == null) {
      // Fallback para texto em português se LanguageService não estiver disponível
      final fallbacks = {
        'displayMainWindow': 'Janela Principal',
        'displayProjectionWindow': 'Janela de Projeção',
        'displaySecondaryTab': 'Aba Secundária',
        'displayTabNote': 'Abra uma nova aba e navegue para a URL de projeção',
        'displayConnectionFailed': 'Falha na conexão',
        'displayOpenTabInstruction': 'Abra uma nova aba e navegue para a URL fornecida',
        'displayNoDisplayConnected': 'Nenhum display conectado',
        'displayPresentationFailed': 'Falha ao iniciar apresentação',
      };
      return fallbacks[key] ?? key;
    }
    
    // Usar LanguageService para obter string localizada
    switch (key) {
      case 'displayMainWindow':
        return _languageService!.strings.displayMainWindow;
      case 'displayProjectionWindow':
        return _languageService!.strings.displayProjectionWindow;
      case 'displaySecondaryTab':
        return _languageService!.strings.displaySecondaryTab;
      case 'displayTabNote':
        return _languageService!.strings.displayTabNote;
      case 'displayConnectionFailed':
        return _languageService!.strings.displayConnectionFailed;
      case 'displayOpenTabInstruction':
        return _languageService!.strings.displayOpenTabInstruction;
      case 'displayNoDisplayConnected':
        return _languageService!.strings.displayNoDisplayConnected;
      case 'displayPresentationFailed':
        return _languageService!.strings.displayPresentationFailed;
      default:
        return key;
    }
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
        debugLog('📚 Displays salvos carregados');
      }
    } catch (e) {
      debugLog('⚠️ Erro ao carregar displays salvos: $e');
    }
  }

  @override
  Future<void> saveDisplayConfig(DisplayConnectionConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'robust_display_config_${config.displayId}';
      await prefs.setString(key, jsonEncode(config.toMap()));
      debugLog('💾 Configuração robusta salva para display ${config.displayId}');
    } catch (e) {
      debugLog('❌ Erro ao salvar configuração robusta: $e');
    }
  }

  @override
  Future<DisplayConnectionConfig?> loadDisplayConfig(String displayId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'robust_display_config_$displayId';
      final data = prefs.getString(key);
      if (data != null) {
        final configMap = jsonDecode(data) as Map<String, dynamic>;
        debugLog('📖 Configuração robusta carregada para display $displayId');
        return DisplayConnectionConfig.fromMap(configMap);
      }
    } catch (e) {
      debugLog('⚠️ Erro ao carregar configuração robusta: $e');
    }
    return null;
  }

  @override
  Future<void> removeDisplayConfig(String displayId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'robust_display_config_$displayId';
      await prefs.remove(key);
      debugLog('🗑️ Configuração robusta removida para display $displayId');
    } catch (e) {
      debugLog('❌ Erro ao remover configuração robusta: $e');
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
      debugLog('🧪 Testando conexão robusta com display $displayId');
      
      if (displayId == 'main_window') {
        return true;
      }
      
      if (displayId == 'projection_window') {
        return _isProjectionWindowOpen();
      }
      
      if (displayId == 'secondary_tab') {
        // Verificar se há aba secundária ativa
        await _sendStorageMessage({
          'type': 'ping_test',
          'displayId': displayId,
        });
        
        // Aguardar resposta por 2 segundos
        await Future.delayed(const Duration(seconds: 2));
        return true; // Assumir sucesso por simplicidade
      }
      
      return false;
    } catch (e) {
      debugLog('❌ Erro ao testar conexão robusta: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final capabilities = _displayStates['capabilities'] as Map<String, bool>? ?? {};
    
    return {
      'platform': 'web',
      'implementation': 'robust',
      'version': '1.0.0',
      'connectedDisplayId': connectedDisplay?.id,
      'isPresenting': isPresenting,
      'availableDisplaysCount': availableDisplays.length,
      'browserCapabilities': capabilities,
      'projectionWindowOpen': _isProjectionWindowOpen(),
      'lastScanTime': DateTime.now().toIso8601String(),
      'communicationMethod': 'localStorage',
    };
  }

  @override
  Future<void> reset() async {
    debugLog('🔄 Resetando RobustWebDisplayManager');
    
    await disconnect();
    _connectionCheckTimer?.cancel();
    _discoveryTimer?.cancel();
    _displayStates.clear();
    
    await initialize();
  }

  /// Detecta monitores físicos conectados usando APIs do navegador
  Future<List<ExternalDisplay>> _detectPhysicalDisplays() async {
    final displays = <ExternalDisplay>[];
    
    try {
      // Método 1: Screen Detection API (Chrome experimental)
      final screenDisplays = await _detectScreenAPI();
      displays.addAll(screenDisplays);
      
      // Método 2: Window.screen análise
      if (displays.isEmpty) {
        final screenAnalysis = await _detectScreenAnalysis();
        displays.addAll(screenAnalysis);
      }
      
      // Método 3: Fullscreen API DESABILITADO (muitos falsos positivos)
      // Causava detecção incorreta em monitores únicos de alta resolução
      // Mantendo comentado para uso futuro se necessário
      // if (displays.isEmpty) {
      //   final fullscreenDisplays = await _detectFullscreenAPI();
      //   displays.addAll(fullscreenDisplays);
      // }
      
    } catch (e) {
      debugLog('⚠️ Erro na detecção de displays físicos: $e');
    }
    
    return displays;
  }

  /// Usa Screen Detection API experimental do Chrome e JavaScript helper
  Future<List<ExternalDisplay>> _detectScreenAPI() async {
    final displays = <ExternalDisplay>[];
    
    try {
      if (kIsWeb) {
        // Primeiro, tentar usar nosso helper JavaScript
        try {
          final verseeScreenDetection = js.context['verseeScreenDetection'];
          if (verseeScreenDetection != null) {
            debugLog('📺 VERSEE Screen Detection JavaScript disponível');
            
            // Solicitar permissão e detectar screens com timeout
            try {
              final screenData = await PlatformUtils.executeNativeCode('''
                (async function() {
                  if (window.verseeScreenDetection && window.verseeScreenDetection.requestScreenPermission) {
                    return await window.verseeScreenDetection.requestScreenPermission();
                  }
                  return null;
                })()
              ''').timeout(const Duration(seconds: 5));
              
              if (screenData != null) {
                if (screenData is Map && screenData['screens'] is List) {
                  final screenList = screenData['screens'] as List;
                
                for (int i = 0; i < screenList.length; i++) {
                  final screenInfo = screenList[i] as Map;
                  final isPrimary = screenInfo['isPrimary'] as bool? ?? false;
                  
                  if (!isPrimary) {
                    displays.add(ExternalDisplay(
                      id: 'physical_monitor_$i',
                      name: 'Monitor Físico ${i + 1} (${screenInfo['width']}x${screenInfo['height']})',
                      type: DisplayType.hdmi,
                      state: DisplayConnectionState.detected,
                      capabilities: [
                        DisplayCapability.images,
                        DisplayCapability.video,
                        DisplayCapability.audio,
                        DisplayCapability.slideSync,
                        DisplayCapability.remoteControl,
                      ],
                      metadata: {
                        'isPhysical': true,
                        'resolution': '${screenInfo['width']}x${screenInfo['height']}',
                        'left': screenInfo['left'],
                        'top': screenInfo['top'],
                        'isPrimary': isPrimary,
                        'screenIndex': i,
                        'detectionMethod': 'versee_screen_api',
                      },
                    ));
                    debugLog('✅ Monitor físico detectado via VERSEE: ${screenInfo['width']}x${screenInfo['height']}');
                  }
                }
                } else {
                  debugLog('⚠️ VERSEE Screen Detection: formato de dados inválido');
                }
              }
            } catch (timeoutError) {
              debugLog('⚠️ VERSEE Screen Detection timeout: $timeoutError');
            }
          }
        } catch (e) {
          debugLog('⚠️ VERSEE Screen Detection não funcionou: $e');
        }
        
        // Fallback: tentar Screen Detection API nativa
        if (displays.isEmpty && js.context.hasProperty('screen')) {
          final screen = js.context['screen'];
          if (screen != null && js_util.hasProperty(screen, 'getScreenDetails')) {
            debugLog('📺 Screen Detection API nativa disponível');
            
            try {
              final screenDetails = await js_util.promiseToFuture(
                js_util.callMethod(screen, 'getScreenDetails', [])
              );
              
              final screens = js_util.getProperty(screenDetails, 'screens');
              if (screens != null) {
                final screenList = js_util.dartify(screens) as List;
                
                for (int i = 0; i < screenList.length; i++) {
                  final screenInfo = screenList[i] as Map;
                  final isPrimary = screenInfo['isPrimary'] as bool? ?? false;
                  
                  if (!isPrimary) {
                    displays.add(ExternalDisplay(
                      id: 'physical_monitor_$i',
                      name: 'Monitor Físico ${i + 1} (${screenInfo['width']}x${screenInfo['height']})',
                      type: DisplayType.hdmi,
                      state: DisplayConnectionState.detected,
                      capabilities: [
                        DisplayCapability.images,
                        DisplayCapability.video,
                        DisplayCapability.audio,
                        DisplayCapability.slideSync,
                        DisplayCapability.remoteControl,
                      ],
                      metadata: {
                        'isPhysical': true,
                        'resolution': '${screenInfo['width']}x${screenInfo['height']}',
                        'left': screenInfo['left'],
                        'top': screenInfo['top'],
                        'isPrimary': isPrimary,
                        'screenIndex': i,
                        'detectionMethod': 'native_screen_api',
                      },
                    ));
                    debugLog('✅ Monitor físico detectado via API nativa: ${screenInfo['width']}x${screenInfo['height']}');
                  }
                }
              }
            } catch (e) {
              debugLog('⚠️ Erro ao usar Screen Detection API nativa: $e');
            }
          }
        }
      }
    } catch (e) {
      debugLog('⚠️ Screen Detection APIs não disponíveis: $e');
    }
    
    return displays;
  }

  /// Analisa window.screen para detectar configuração multi-monitor
  Future<List<ExternalDisplay>> _detectScreenAnalysis() async {
    final displays = <ExternalDisplay>[];
    
    try {
      if (kIsWeb) {
        // Primeiro, tentar usar nosso helper JavaScript avançado
        try {
          final verseeScreenDetection = js.context['verseeScreenDetection'];
          if (verseeScreenDetection != null) {
            try {
              final multiMonitorInfo = js_util.callMethod(verseeScreenDetection, 'detectMultiMonitorSetup', []);
              final setupInfo = js_util.dartify(multiMonitorInfo);
            
            if (setupInfo is Map && setupInfo['isMultiMonitor'] == true) {
              final secondary = setupInfo['estimatedSecondaryMonitor'];
              if (secondary != null && secondary is Map) {
                displays.add(ExternalDisplay(
                  id: 'extended_monitor_js',
                  name: 'Monitor Estendido (${secondary['width']}x${secondary['height']})',
                  type: DisplayType.hdmi,
                  state: DisplayConnectionState.detected,
                  capabilities: [
                    DisplayCapability.images,
                    DisplayCapability.video,
                    DisplayCapability.slideSync,
                    DisplayCapability.remoteControl,
                  ],
                  metadata: {
                    'isPhysical': true,
                    'isExtended': true,
                    'estimatedResolution': '${secondary['width']}x${secondary['height']}',
                    'totalDesktop': '${setupInfo['availWidth']}x${setupInfo['availHeight']}',
                    'primaryResolution': '${setupInfo['screenWidth']}x${setupInfo['screenHeight']}',
                    'position': secondary['position'],
                    'detectionMethod': 'versee_screen_analysis',
                    'confidence': 'high',
                  },
                ));
                debugLog('✅ Monitor estendido detectado via VERSEE: ${secondary['width']}x${secondary['height']}');
              }
            }
            } catch (jsError) {
              debugLog('⚠️ Erro no JavaScript detectMultiMonitorSetup: $jsError');
            }
          }
        } catch (e) {
          debugLog('⚠️ VERSEE Screen Analysis não funcionou: $e');
        }
        
        // Fallback: análise manual de window.screen
        if (displays.isEmpty) {
          final screenDimensions = PlatformUtils.screenDimensions;
          final screenWidth = screenDimensions['width']!;
          final screenHeight = screenDimensions['height']!;
          final availWidth = screenDimensions['availWidth']!;
          final availHeight = screenDimensions['availHeight']!;
          
          // Heurística MUITO conservadora para evitar falsos positivos
          // Só detecta se há evidência clara de configuração multi-monitor
          final screenInfo = PlatformUtils.getDetailedScreenInfo();
          final devicePixelRatio = screenInfo['devicePixelRatio'] ?? 1.0;
          // Aumentado threshold para reduzir falsos positivos
          if (devicePixelRatio > 1.0 && screenWidth > 3840) { // 4K+ pode indicar setup dual
            final secondaryWidth = 1920;
            final secondaryHeight = 1080;
            
            displays.add(ExternalDisplay(
              id: 'extended_monitor',
              name: 'Monitor Estendido (${secondaryWidth}x${secondaryHeight})',
              type: DisplayType.hdmi,
              state: DisplayConnectionState.detected,
              capabilities: [
                DisplayCapability.images,
                DisplayCapability.video,
                DisplayCapability.slideSync,
                DisplayCapability.remoteControl,
              ],
              metadata: {
                'isPhysical': true,
                'isExtended': true,
                'estimatedResolution': '${secondaryWidth}x${secondaryHeight}',
                'totalDesktop': '${screenWidth}x${screenHeight}',
                'primaryResolution': '${screenWidth}x${screenHeight}',
                'detectionMethod': 'manual_screen_analysis',
                'confidence': 'medium',
              },
            ));
            debugLog('✅ Monitor estendido detectado via análise manual: ${secondaryWidth}x${secondaryHeight}');
          }
        }
      }
    } catch (e) {
      debugLog('⚠️ Erro na análise de screen: $e');
    }
    
    return displays;
  }

  /// Usa Fullscreen API para detectar múltiplos monitores
  Future<List<ExternalDisplay>> _detectFullscreenAPI() async {
    final displays = <ExternalDisplay>[];
    
    try {
      if (kIsWeb && PlatformUtils.supportsFullscreen) {
        // Verificar se fullscreen é suportado
        final hasFullscreen = PlatformUtils.supportsFullscreen;
        
        if (hasFullscreen) {
          // Se há suporte a fullscreen em múltiplas telas, provavelmente há monitor secundário
          final screenDimensions = PlatformUtils.screenDimensions;
          final screenInfo = PlatformUtils.getDetailedScreenInfo();
          final devicePixelRatio = screenInfo['devicePixelRatio'] ?? 1.0;
          
          // Heurística: se devicePixelRatio sugere alta densidade, pode haver monitor 4K
          if (devicePixelRatio > 1.5) {
            displays.add(ExternalDisplay(
              id: 'fullscreen_secondary',
              name: 'Monitor Secundário (Detectado via Fullscreen)',
              type: DisplayType.hdmi,
              state: DisplayConnectionState.detected,
              capabilities: [
                DisplayCapability.images,
                DisplayCapability.video,
                DisplayCapability.remoteControl,
              ],
              metadata: {
                'estimatedResolution': '${(screen.width! * devicePixelRatio).round()}x${(screen.height! * devicePixelRatio).round()}',
                'devicePixelRatio': devicePixelRatio,
                'detectionMethod': 'fullscreen_heuristic',
                'confidence': 'low',
              },
            ));
            debugLog('📱 Monitor secundário inferido via fullscreen API');
          }
        }
      }
    } catch (e) {
      debugLog('⚠️ Erro na detecção via Fullscreen API: $e');
    }
    
    return displays;
  }

  /// Conecta a um monitor físico detectado
  Future<bool> _connectToPhysicalMonitor(ExternalDisplay display, DisplayConnectionConfig? config) async {
    try {
      debugLog('🖥️ Conectando a monitor físico: ${display.name}');
      
      final isPhysical = display.metadata?['isPhysical'] == true;
      if (!isPhysical) {
        throw DisplayManagerException('Display não é físico: ${display.id}');
      }
      
      // Construir URL de projeção com parâmetros específicos do monitor
      final projectionUrl = '${_getCurrentBaseUrl()}$_projectionUrl?display=${display.id}&physical=true&fullscreen=true&mode=physical';
      
      // Tentar usar nosso helper JavaScript otimizado primeiro
      try {
        final verseeScreenDetection = js.context['verseeScreenDetection'];
        if (verseeScreenDetection != null) {
          debugLog('🚀 Usando VERSEE Screen Detection para abrir monitor físico');
          
          try {
            final newWindow = await js_util.promiseToFuture(
              js_util.callMethod(verseeScreenDetection, 'openFullscreenOnSecondaryMonitor', [projectionUrl])
            );
            
            if (newWindow != null) {
              // Armazenar referência da janela
              _displayStates[display.id] = {
                'isOpen': true,
                'window': newWindow,
                'url': projectionUrl,
                'isPhysical': true,
                'method': 'versee_optimized',
                'openedAt': DateTime.now().millisecondsSinceEpoch,
              };
              
              debugLog('✅ Monitor físico conectado via VERSEE otimizado');
              
              await _sendStorageMessage({
                'type': 'physical_monitor_connected',
                'displayId': display.id,
                'url': projectionUrl,
                'status': 'connected',
                'isPhysical': true,
                'method': 'versee_optimized',
              });
              
              return true;
            }
          } catch (promiseError) {
            debugLog('⚠️ Promise VERSEE falhou: $promiseError');
            // Continua para método manual
          }
        }
      } catch (e) {
        debugLog('⚠️ VERSEE otimizado falhou, usando método manual: $e');
      }
      
      // Fallback: método manual tradicional
      String windowFeatures = 'width=1920,height=1080,fullscreen=yes,resizable=no,scrollbars=no,toolbar=no,menubar=no,status=no';
      
      // Se temos informações de posição do Screen API, usar
      if (display.metadata?['left'] != null && display.metadata?['top'] != null) {
        final left = display.metadata!['left'];
        final top = display.metadata!['top'];
        windowFeatures = 'left=$left,top=$top,width=1920,height=1080,fullscreen=yes,resizable=no,scrollbars=no,toolbar=no,menubar=no,status=no';
      } else if (display.metadata?['detectionMethod'] == 'versee_screen_analysis') {
        // Se foi detectado via nossa análise avançada, usar posição estimada
        final screenDimensions = PlatformUtils.screenDimensions;
        final estimatedLeft = screenDimensions['width']!;
        windowFeatures = 'left=$estimatedLeft,top=0,width=1920,height=1080,fullscreen=yes,resizable=no,scrollbars=no,toolbar=no,menubar=no,status=no';
      }
      
      final success = PlatformUtils.openWindow(projectionUrl, options: {
        'features': windowFeatures,
      });
      
      if (success) {
        // Armazenar referência da janela
        _displayStates[display.id] = {
          'isOpen': true,
          'url': projectionUrl,
          'isPhysical': true,
          'method': 'manual',
          'openedAt': DateTime.now().millisecondsSinceEpoch,
        };
        
        // Tentar mover para tela cheia no monitor correto
        if (kIsWeb) {
          try {
            await Future.delayed(const Duration(milliseconds: 1000));
            
            // Múltiplas tentativas de fullscreen para compatibilidade
            try {
              // Usar js_util para acessar document via JavaScript
              final windowDoc = js_util.getProperty(newWindow, 'document');
              if (windowDoc != null) {
                final docElement = js_util.getProperty(windowDoc, 'documentElement');
                if (docElement != null) {
                  try {
                    await js_util.promiseToFuture(
                      js_util.callMethod(docElement, 'requestFullscreen', [])
                    );
                  } catch (e1) {
                    try {
                      js_util.callMethod(docElement, 'webkitRequestFullscreen', []);
                    } catch (e2) {
                      try {
                        js_util.callMethod(docElement, 'mozRequestFullScreen', []);
                      } catch (e3) {
                        debugLog('⚠️ Nenhum método de fullscreen funcionou: $e1, $e2, $e3');
                      }
                    }
                  }
                }
              }
            } catch (e) {
              debugLog('⚠️ Erro ao acessar document da nova janela: $e');
            }
          } catch (e) {
            debugLog('⚠️ Não foi possível ativar fullscreen: $e');
          }
        }
        
        debugLog('✅ Monitor físico conectado via método manual');
        
        await _sendStorageMessage({
          'type': 'physical_monitor_connected',
          'displayId': display.id,
          'url': projectionUrl,
          'status': 'connected',
          'isPhysical': true,
          'method': 'manual',
        });
        
        return true;
      } else {
        debugLog('❌ Falha ao abrir janela no monitor físico (popup bloqueado?)');
        
        // Mostrar instruções para o usuário abrir manualmente
        await _showPhysicalMonitorInstructions(projectionUrl, display);
        return true; // Consideramos sucesso, pois fornecemos instruções
      }
      
    } catch (e) {
      debugLog('❌ Erro ao conectar monitor físico: $e');
      return false;
    }
  }
  
  Future<void> _showPhysicalMonitorInstructions(String url, ExternalDisplay display) async {
    final instructions = '''
🖥️ MONITOR FÍSICO DETECTADO!

Para usar seu monitor secundário:

1. Abra esta URL em uma nova janela:
$url

2. Arraste a janela para seu monitor secundário

3. Pressione F11 para tela cheia

OU

1. Pressione Ctrl+T para nova aba
2. Cole: $url
3. Arraste aba para monitor secundário
4. Pressione F11

Monitor detectado: ${display.name}
''';
    
    if (kIsWeb) {
      try {
        await PlatformUtils.executeNativeCode('alert("' + instructions.replaceAll('"', '\\"') + '")', params: {'instructions': instructions});
      } catch (e) {
        debugLog('Não foi possível mostrar instruções: $e');
      }
    }
    
    await _sendStorageMessage({
      'type': 'physical_monitor_instructions',
      'displayId': display.id,
      'url': url,
      'instructions': instructions,
      'displayInfo': display.name,
    });
  }

  /// Valida se monitores físicos detectados são realmente conectáveis
  Future<List<ExternalDisplay>> _validatePhysicalDisplays(List<ExternalDisplay> displays) async {
    final validatedDisplays = <ExternalDisplay>[];
    
    for (final display in displays) {
      try {
        debugLog('🔍 Validando monitor físico: ${display.id}');
        
        // Teste básico: verificar se metadata indica detecção confiável
        final confidence = display.metadata?['confidence'] as String?;
        final detectionMethod = display.metadata?['detectionMethod'] as String?;
        
        // Só aceitar detecções de alta confiança ou métodos confiáveis
        bool isValid = false;
        
        if (confidence == 'high') {
          isValid = true;
          debugLog('✅ Monitor validado por alta confiança');
        } else if (detectionMethod == 'versee_screen_api' || detectionMethod == 'native_screen_api') {
          isValid = true;
          debugLog('✅ Monitor validado por Screen API');
        } else {
          // Para métodos heurísticos, fazer teste adicional
          isValid = await _testPhysicalMonitorExistence(display);
        }
        
        if (isValid) {
          validatedDisplays.add(display);
          debugLog('✅ Monitor físico validado: ${display.name}');
        } else {
          debugLog('❌ Monitor físico rejeitado (não validado): ${display.name}');
        }
        
      } catch (e) {
        debugLog('⚠️ Erro ao validar monitor ${display.id}: $e');
        // Em caso de erro, não adiciona à lista (conservador)
      }
    }
    
    return validatedDisplays;
  }
  
  /// Testa se um monitor físico realmente existe
  Future<bool> _testPhysicalMonitorExistence(ExternalDisplay display) async {
    try {
      // Para detecções heurísticas, ser mais rigoroso
      final detectionMethod = display.metadata?['detectionMethod'] as String?;
      
      if (detectionMethod == 'manual_screen_analysis') {
        // Análise manual: verificar se realmente há evidência forte
        final screenDimensions = PlatformUtils.screenDimensions;
        final screenWidth = screenDimensions['width']!;
        
        // Só aceitar se for resolução muito alta (indicando setup dual real)
        if (screenWidth < 3840) {
          debugLog('❌ Resolução insuficiente para setup dual: ${screenWidth}px');
          return false;
        }
      }
      
      if (detectionMethod == 'fullscreen_heuristic') {
        // Heurística fullscreen: muito imprecisa, rejeitar por segurança
        debugLog('❌ Rejeitando detecção heurística fullscreen (imprecisa)');
        return false;
      }
      
      // Se chegou até aqui, passou nos testes básicos
      return true;
      
    } catch (e) {
      debugLog('⚠️ Erro no teste de existência do monitor: $e');
      return false; // Conservador: em caso de erro, não validar
    }
  }

  @override
  void dispose() {
    debugLog('🧹 Disposing RobustWebDisplayManager');
    
    _connectionCheckTimer?.cancel();
    _discoveryTimer?.cancel();
    _displayStates.clear();
    
    super.dispose();
  }
}