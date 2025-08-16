import 'package:flutter/foundation.dart';
import 'package:versee/services/display_manager.dart';
import 'package:versee/services/cross_platform_web_display_manager.dart';
import 'package:versee/services/native_display_manager.dart';

/// Factory para criar a implementação correta do DisplayManager
/// baseado na plataforma atual (web vs mobile)
class DisplayFactory {
  static DisplayManager? _instance;
  
  /// Obtém a instância singleton do DisplayManager apropriado para a plataforma
  static DisplayManager get instance {
    _instance ??= createDisplayManager();
    return _instance!;
  }
  
  /// Cria a implementação correta do DisplayManager baseado na plataforma
  static DisplayManager createDisplayManager() {
    if (kIsWeb) {
      debugPrint('🌐 Criando CrossPlatformWebDisplayManager para plataforma web');
      return CrossPlatformWebDisplayManager();
    } else {
      debugPrint('📱 Criando NativeDisplayManager para plataforma móvel');
      return NativeDisplayManager();
    }
  }
  
  /// Reinicia o DisplayManager (útil para testes ou reset)
  static Future<void> reset() async {
    if (_instance != null) {
      await _instance!.reset();
      _instance!.dispose();
      _instance = null;
    }
  }
  
  /// Verifica se a plataforma suporta displays externos
  static bool get supportsExternalDisplays {
    if (kIsWeb) {
      // Web sempre suporta múltiplas janelas
      return true;
    } else {
      // Mobile suporta displays externos nativos
      return true;
    }
  }
  
  /// Obtém informações sobre as capacidades da plataforma
  static Map<String, bool> get platformCapabilities {
    if (kIsWeb) {
      return {
        'multipleWindows': true,
        'fullscreenAPI': true,
        'popupWindows': true,
        'broadcastChannel': true,
        'screenAPI': false, // Experimental
        'physicalDisplays': false,
        'wirelessCasting': false,
        'nativeIntegration': false,
      };
    } else {
      return {
        'multipleWindows': false,
        'fullscreenAPI': false,
        'popupWindows': false,
        'broadcastChannel': false,
        'screenAPI': false,
        'physicalDisplays': true,
        'wirelessCasting': true,
        'nativeIntegration': true,
      };
    }
  }
  
  /// Obtém lista de tipos de display suportados pela plataforma
  static List<String> get supportedDisplayTypes {
    if (kIsWeb) {
      return [
        'webWindow',
        'popupWindow',
        'secondaryMonitor', // Se Screen API disponível
      ];
    } else {
      return [
        'hdmi',
        'usbC',
        'chromecast',
        'airplay',
        'androidTv',
        'fireTV',
        'miracast',
        'nativeDualScreen',
      ];
    }
  }
  
  /// Verifica se um tipo específico de display é suportado
  static bool supportsDisplayType(String displayType) {
    return supportedDisplayTypes.contains(displayType);
  }
  
  /// Obtém a implementação recomendada para a plataforma atual
  static String get recommendedImplementation {
    if (kIsWeb) {
      return 'WebDisplayManager com múltiplas janelas do browser';
    } else {
      return 'NativeDisplayManager com presentation_displays';
    }
  }
  
  /// Obtém limitações conhecidas da plataforma atual
  static List<String> get platformLimitations {
    if (kIsWeb) {
      return [
        'Depende de permissões de popup do browser',
        'Usuário precisa mover janela para monitor secundário manualmente',
        'Screen API ainda é experimental',
        'Sem detecção automática de hardware',
        'Limitado pelas políticas de segurança do browser',
      ];
    } else {
      return [
        'Requer hardware físico ou dispositivos de casting',
        'Permissões específicas podem ser necessárias',
        'Compatibilidade varia entre fabricantes',
        'Algumas funcionalidades dependem da versão do OS',
      ];
    }
  }
  
  /// Obtém sugestões para melhorar a experiência na plataforma atual
  static List<String> get platformRecommendations {
    if (kIsWeb) {
      return [
        'Permita popups para este site',
        'Use Chrome ou Edge para melhor suporte',
        'Configure múltiplos monitores no sistema',
        'Considere usar modo fullscreen',
      ];
    } else {
      return [
        'Conecte display via HDMI ou USB-C',
        'Configure dispositivos Chromecast/AirPlay na mesma rede',
        'Verifique permissões do app para displays externos',
        'Mantenha drivers de display atualizados',
      ];
    }
  }
}