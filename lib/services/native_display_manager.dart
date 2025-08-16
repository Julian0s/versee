import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versee/models/display_models.dart' hide ConnectionState;
import 'package:versee/services/display_manager.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/platform/platform.dart';

/// Implementação nativa do DisplayManager para Android e iOS
/// Usa method channels para comunicação com código nativo
class NativeDisplayManager extends BaseDisplayManager {
  Timer? _discoveryTimer;
  Timer? _connectionMonitorTimer;
  final Map<String, dynamic> _connectedDevices = {};
  
  static const String _savedDisplaysKey = 'native_saved_displays';

  @override
  Future<void> initialize() async {
    debugLog('📱 Inicializando NativeDisplayManager para ${Platform.operatingSystem}');
    
    try {
      // Configurar listeners para eventos de display
      PlatformUtils.setupDisplayListeners(_handleDisplayEvent);
      
      // Carregar displays salvos
      await _loadSavedDisplays();
      
      // Iniciar discovery automático
      _startBackgroundDiscovery();
      
      debugLog('✅ NativeDisplayManager inicializado com sucesso');
    } catch (e) {
      debugLog('❌ Erro ao inicializar NativeDisplayManager: $e');
      throw DisplayManagerException('Falha ao inicializar native display manager', originalError: e);
    }
  }

  Future<List<ExternalDisplay>> _getSavedDisplaysWithStatus() async {
    // TODO: Implementar carregamento com verificação de status
    return [];
  }

  @override
  Future<List<ExternalDisplay>> scanForDisplays({Duration? timeout}) async {
    debugLog('Escaneando displays nativos...');
    
    final displays = <ExternalDisplay>[];
    
    try {
      // 1. Displays físicos via presentation_displays
      final physicalDisplays = await _scanPhysicalDisplays();
      displays.addAll(physicalDisplays);
      
      // 2. Chromecast devices (Android)
      if (Platform.isAndroid) {
        final castDisplays = await _scanChromecastDevices();
        displays.addAll(castDisplays);
      }
      
      // 3. AirPlay devices (iOS)
      if (Platform.isIOS) {
        final airplayDisplays = await _scanAirPlayDevices();
        displays.addAll(airplayDisplays);
      }
      
      // 4. Dispositivos salvos/lembrados
      final savedDisplays = await _getSavedDisplaysWithStatus();
      for (final saved in savedDisplays) {
        if (!displays.any((d) => d.id == saved.id)) {
          displays.add(saved);
        }
      }
      
      updateAvailableDisplays(displays);
      debugLog('Encontrados ${displays.length} displays nativos');
      
    } catch (e) {
      debugLog('Erro durante scan de displays nativos: $e');
    }
    
    return displays;
  }

  Future<List<ExternalDisplay>> _scanPhysicalDisplays() async {
    try {
      final physicalDisplaysData = await PlatformUtils.getPhysicalDisplays();
      
      return physicalDisplaysData.map((displayData) {
        return ExternalDisplay(
          id: displayData['id'] ?? 'unknown',
          name: displayData['name'] ?? 'Display Físico',
          type: DisplayType.hdmi, // Assumir HDMI como padrão
          state: DisplayConnectionState.detected,
          capabilities: [
            DisplayCapability.images,
            DisplayCapability.video,
            DisplayCapability.highQuality,
          ],
          width: displayData['width'],
          height: displayData['height'],
          refreshRate: displayData['refreshRate']?.toDouble(),
          metadata: {
            'isPhysical': true,
            'platform': Platform.operatingSystem,
            'detectionMethod': 'native_api',
          },
        );
      }).toList();
    } catch (e) {
      debugLog('❌ Erro ao escanear displays físicos: $e');
      return [];
    }
  }

  Future<List<ExternalDisplay>> _scanChromecastDevices() async {
    try {
      final chromecastDevices = await PlatformUtils.scanChromecastDevices();
      
      return chromecastDevices.map((deviceData) {
        return ExternalDisplay(
          id: deviceData['id'] ?? 'chromecast_unknown',
          name: deviceData['name'] ?? 'Chromecast',
          type: DisplayType.chromecast,
          state: DisplayConnectionState.detected,
          capabilities: [
            DisplayCapability.images,
            DisplayCapability.video,
            DisplayCapability.audio,
            DisplayCapability.remoteControl,
          ],
          ipAddress: deviceData['ipAddress'],
          model: deviceData['model'],
          metadata: {
            'isChromecast': true,
            'deviceId': deviceData['deviceId'],
            'platform': 'android',
          },
        );
      }).toList();
    } catch (e) {
      debugLog('❌ Erro ao escanear Chromecast: $e');
      return [];
    }
  }

  Future<List<ExternalDisplay>> _scanAirPlayDevices() async {
    try {
      final airplayDevices = await PlatformUtils.scanAirPlayDevices();
      
      return airplayDevices.map((deviceData) {
        return ExternalDisplay(
          id: deviceData['id'] ?? 'airplay_unknown',
          name: deviceData['name'] ?? 'AirPlay Device',
          type: DisplayType.airplay,
          state: DisplayConnectionState.detected,
          capabilities: [
            DisplayCapability.images,
            DisplayCapability.video,
            DisplayCapability.audio,
            DisplayCapability.remoteControl,
          ],
          ipAddress: deviceData['ipAddress'],
          model: deviceData['model'],
          metadata: {
            'isAirPlay': true,
            'identifier': deviceData['identifier'],
            'platform': 'ios',
          },
        );
      }).toList();
    } catch (e) {
      debugLog('❌ Erro ao escanear AirPlay: $e');
      return [];
    }
  }

  void _handleDisplayEvent(Map<String, dynamic> event) {
    try {
      final type = event['type'] as String?;
      final displayId = event['displayId'] as String?;
      
      switch (type) {
        case 'display_connected':
          if (displayId != null) {
            debugLog('🔌 Display conectado: $displayId');
            updateDisplayState(displayId, DisplayConnectionState.connected);
          }
          break;
          
        case 'display_disconnected':
          if (displayId != null) {
            debugLog('🔌 Display desconectado: $displayId');
            updateDisplayState(displayId, DisplayConnectionState.disconnected);
          }
          break;
          
        case 'cast_device_found':
          debugLog('📡 Dispositivo de casting encontrado');
          // Trigger rescan para atualizar lista
          scanForDisplays();
          break;
          
        default:
          debugLog('📨 Evento de display desconhecido: $type');
      }
    } catch (e) {
      debugLog('❌ Erro ao processar evento de display: $e');
    }
  }

  @override
  Future<bool> connectToDisplay(String displayId, {DisplayConnectionConfig? config}) async {
    debugLog('🔗 Conectando ao display nativo: $displayId');
    
    try {
      final display = availableDisplays.firstWhere((d) => d.id == displayId);
      
      switch (display.type) {
        case DisplayType.hdmi:
        case DisplayType.usbC:
          return await _connectToPhysicalDisplay(display, config);
          
        case DisplayType.chromecast:
          return await _connectToChromecast(display, config);
          
        case DisplayType.airplay:
          return await _connectToAirPlay(display, config);
          
        default:
          throw DisplayManagerException('Tipo de display não suportado: ${display.type}');
      }
    } catch (e) {
      debugLog('❌ Erro ao conectar ao display $displayId: $e');
      updateDisplayState(displayId, DisplayConnectionState.error, message: e.toString());
      return false;
    }
  }

  Future<bool> _connectToPhysicalDisplay(ExternalDisplay display, DisplayConnectionConfig? config) async {
    try {
      final success = await PlatformUtils.testDisplayConnection(display.id);
      
      if (success) {
        updateDisplayState(display.id, DisplayConnectionState.connected);
        setConnectedDisplay(display.copyWith(state: DisplayConnectionState.connected));
        _connectedDevices[display.id] = {'type': 'physical', 'connectedAt': DateTime.now()};
        
        debugLog('✅ Conectado ao display físico: ${display.name}');
        return true;
      } else {
        throw DisplayManagerException('Display físico não está disponível');
      }
    } catch (e) {
      debugLog('❌ Erro ao conectar display físico: $e');
      return false;
    }
  }

  Future<bool> _connectToChromecast(ExternalDisplay display, DisplayConnectionConfig? config) async {
    try {
      final deviceId = display.metadata?['deviceId'] as String?;
      final appId = config?.customSettings['appId'] as String? ?? 'CC1AD845';
      
      final success = await PlatformUtils.connectToChromecast(deviceId ?? display.id, appId: appId);
      
      if (success) {
        updateDisplayState(display.id, DisplayConnectionState.connected);
        setConnectedDisplay(display.copyWith(state: DisplayConnectionState.connected));
        _connectedDevices[display.id] = {'type': 'chromecast', 'connectedAt': DateTime.now()};
        
        debugLog('✅ Conectado ao Chromecast: ${display.name}');
        return true;
      } else {
        throw DisplayManagerException('Falha ao conectar ao Chromecast');
      }
    } catch (e) {
      debugLog('❌ Erro ao conectar Chromecast: $e');
      return false;
    }
  }

  Future<bool> _connectToAirPlay(ExternalDisplay display, DisplayConnectionConfig? config) async {
    try {
      final identifier = display.metadata?['identifier'] as String?;
      
      final success = await PlatformUtils.connectToAirPlay(identifier ?? display.id);
      
      if (success) {
        updateDisplayState(display.id, DisplayConnectionState.connected);
        setConnectedDisplay(display.copyWith(state: DisplayConnectionState.connected));
        _connectedDevices[display.id] = {'type': 'airplay', 'connectedAt': DateTime.now()};
        
        debugLog('✅ Conectado ao AirPlay: ${display.name}');
        return true;
      } else {
        throw DisplayManagerException('Falha ao conectar ao AirPlay');
      }
    } catch (e) {
      debugLog('❌ Erro ao conectar AirPlay: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    debugLog('🔌 Desconectando displays nativos');
    
    try {
      // Desconectar de todos os dispositivos ativos
      for (final deviceId in _connectedDevices.keys.toList()) {
        final deviceInfo = _connectedDevices[deviceId];
        final deviceType = deviceInfo?['type'] as String?;
        
        switch (deviceType) {
          case 'chromecast':
            await PlatformUtils.disconnectFromCasting();
            break;
          case 'airplay':
            await PlatformUtils.disconnectFromCasting();
            break;
          case 'physical':
            // Physical displays disconnect automatically
            break;
        }
      }
      
      _connectedDevices.clear();
      setConnectedDisplay(null);
      setPresentationState(false);
      
      debugLog('✅ Todos os displays desconectados');
    } catch (e) {
      debugLog('❌ Erro ao desconectar displays: $e');
    }
  }

  void _startBackgroundDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      scanForDisplays();
    });
  }

  Future<void> _loadSavedDisplays() async {
    try {
      final savedData = await PlatformUtils.loadLocalData(_savedDisplaysKey);
      if (savedData != null) {
        debugLog('📂 Displays salvos carregados');
      }
    } catch (e) {
      debugLog('❌ Erro ao carregar displays salvos: $e');
    }
  }

  @override
  Future<void> saveDisplayConfig(DisplayConnectionConfig config) async {
    try {
      final key = 'native_display_config_${config.displayId}';
      final configJson = config.toMap().toString();
      await PlatformUtils.saveLocalData(key, configJson);
      debugLog('💾 Configuração salva para display ${config.displayId}');
    } catch (e) {
      debugLog('❌ Erro ao salvar configuração: $e');
    }
  }

  @override
  Future<DisplayConnectionConfig?> loadDisplayConfig(String displayId) async {
    try {
      final key = 'native_display_config_$displayId';
      final data = await PlatformUtils.loadLocalData(key);
      if (data != null) {
        debugLog('📂 Configuração carregada para display $displayId');
        // TODO: Implementar deserialização completa
      }
    } catch (e) {
      debugLog('❌ Erro ao carregar configuração: $e');
    }
    return null;
  }

  @override
  Future<void> removeDisplayConfig(String displayId) async {
    try {
      final key = 'native_display_config_$displayId';
      await PlatformUtils.removeLocalData(key);
      debugLog('🗑️ Configuração removida para display $displayId');
    } catch (e) {
      debugLog('❌ Erro ao remover configuração: $e');
    }
  }

  @override
  Future<List<ExternalDisplay>> getSavedDisplays() async {
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
      return await PlatformUtils.testDisplayConnection(displayId);
    } catch (e) {
      debugLog('❌ Erro ao testar conexão: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    try {
      final platformInfo = await PlatformUtils.getPlatformDiagnosticInfo();
      
      return {
        'manager': 'NativeDisplayManager',
        'platform': Platform.operatingSystem,
        'connectedDisplayId': connectedDisplay?.id,
        'isPresenting': isPresenting,
        'availableDisplaysCount': availableDisplays.length,
        'connectedDevicesCount': _connectedDevices.length,
        'platformInfo': platformInfo,
      };
    } catch (e) {
      debugLog('❌ Erro ao obter informações de diagnóstico: $e');
      return {
        'manager': 'NativeDisplayManager',
        'platform': Platform.operatingSystem,
        'error': e.toString(),
      };
    }
  }

  @override
  Future<void> reset() async {
    debugLog('🔄 Resetando NativeDisplayManager');
    
    await disconnect();
    _discoveryTimer?.cancel();
    _connectionMonitorTimer?.cancel();
    
    await initialize();
  }

  @override
  void dispose() {
    debugLog('🗑️ Disposing NativeDisplayManager');
    
    _discoveryTimer?.cancel();
    _connectionMonitorTimer?.cancel();
    PlatformUtils.removeDisplayListeners();
    
    super.dispose();
  }

  // Métodos de apresentação usando base DisplayManager
  @override
  Future<bool> startPresentation(PresentationItem item) async {
    if (!hasConnectedDisplay) {
      throw DisplayManagerException('Nenhum display conectado');
    }
    
    try {
      debugLog('🎬 Iniciando apresentação: ${item.title}');
      
      // Para implementação futura com casting/displays físicos
      // Por enquanto, usar lógica base
      
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
      setPresentationState(true, item: item);
      debugLog('🔄 Apresentação atualizada');
    } catch (e) {
      debugLog('❌ Erro ao atualizar apresentação: $e');
    }
  }
}
