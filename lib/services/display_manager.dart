import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:versee/models/display_models.dart' hide ConnectionState;
import 'package:versee/services/playlist_service.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/providers/riverpod_providers.dart';

// Instância global para bridge híbrida
BaseDisplayManager? _globalDisplayManager;

/// Interface abstrata para gerenciamento de displays externos
/// Implementações específicas para web, Android e iOS
abstract class DisplayManager extends ChangeNotifier {
  /// Lista de displays disponíveis
  List<ExternalDisplay> get availableDisplays;
  
  /// Display atualmente conectado para apresentação
  ExternalDisplay? get connectedDisplay;
  
  /// Verifica se há algum display conectado
  bool get hasConnectedDisplay;
  
  /// Verifica se está apresentando em algum display
  bool get isPresenting;
  
  /// Stream de mudanças de estado dos displays
  Stream<DisplayStateChangeEvent> get displayStateStream;
  
  /// Stream de descoberta de novos displays
  Stream<List<ExternalDisplay>> get discoveryStream;

  /// Inicializa o gerenciador de displays
  Future<void> initialize();

  /// Busca por displays disponíveis
  Future<List<ExternalDisplay>> scanForDisplays({Duration? timeout});

  /// Conecta a um display específico
  Future<bool> connectToDisplay(String displayId, {DisplayConnectionConfig? config});

  /// Desconecta do display atual
  Future<void> disconnect();

  /// Inicia apresentação em display conectado
  Future<bool> startPresentation(PresentationItem item);

  /// Para apresentação
  Future<void> stopPresentation();

  /// Atualiza conteúdo da apresentação
  Future<void> updatePresentation(PresentationItem item);

  /// Navega para próximo slide
  Future<void> nextSlide();

  /// Navega para slide anterior
  Future<void> previousSlide();

  /// Vai para slide específico
  Future<void> goToSlide(int index);

  /// Ativa/desativa tela preta
  Future<void> toggleBlackScreen(bool active);

  /// Atualiza configurações de apresentação
  Future<void> updatePresentationSettings({
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    TextAlign? textAlignment,
  });

  /// Salva configurações de um display
  Future<void> saveDisplayConfig(DisplayConnectionConfig config);

  /// Carrega configurações salvas de um display
  Future<DisplayConnectionConfig?> loadDisplayConfig(String displayId);

  /// Remove configurações salvas de um display
  Future<void> removeDisplayConfig(String displayId);

  /// Obter displays salvos/lembrados
  Future<List<ExternalDisplay>> getSavedDisplays();

  /// Verificar capabilities específicas de um display
  Future<List<DisplayCapability>> getDisplayCapabilities(String displayId);

  /// Testar conexão com um display
  Future<bool> testConnection(String displayId);

  /// Obter informações de diagnóstico
  Future<Map<String, dynamic>> getDiagnosticInfo();

  /// Limpar cache e reinicializar
  Future<void> reset();

  /// Configura o serviço de idioma para localizações
  void setLanguageService(LanguageService languageService);

  /// Getters para configurações de apresentação
  double get fontSize;
  Color get textColor;
  Color get backgroundColor;
  TextAlign get textAlignment;

  /// Dispose resources
  @override
  void dispose();
}

/// Implementação base que fornece funcionalidades comuns
abstract class BaseDisplayManager extends DisplayManager {
  final List<ExternalDisplay> _availableDisplays = [];
  ExternalDisplay? _connectedDisplay;
  bool _isPresenting = false;
  PresentationItem? _currentItem;
  int _currentSlideIndex = 0;
  bool _isBlackScreenActive = false;
  
  // Construtor que configura a instância global
  BaseDisplayManager() {
    _globalDisplayManager = this;
  }

  // Controladores de stream
  final StreamController<DisplayStateChangeEvent> _stateController = 
      StreamController<DisplayStateChangeEvent>.broadcast();
  final StreamController<List<ExternalDisplay>> _discoveryController = 
      StreamController<List<ExternalDisplay>>.broadcast();

  // Serviços
  LanguageService? _languageService;

  // Configurações de apresentação
  double _fontSize = 32.0;
  Color _textColor = const Color(0xFFFFFFFF);
  Color _backgroundColor = const Color(0xFF000000);
  TextAlign _textAlignment = TextAlign.center;

  @override
  List<ExternalDisplay> get availableDisplays => List.unmodifiable(_availableDisplays);

  @override
  ExternalDisplay? get connectedDisplay => _connectedDisplay;

  @override
  bool get hasConnectedDisplay => _connectedDisplay != null && _connectedDisplay!.isConnected;

  @override
  bool get isPresenting => _isPresenting && hasConnectedDisplay;

  @override
  Stream<DisplayStateChangeEvent> get displayStateStream => _stateController.stream;

  @override
  Stream<List<ExternalDisplay>> get discoveryStream => _discoveryController.stream;

  // Getters para configurações
  double get fontSize => _fontSize;
  Color get textColor => _textColor;
  Color get backgroundColor => _backgroundColor;
  TextAlign get textAlignment => _textAlignment;
  PresentationItem? get currentItem => _currentItem;
  int get currentSlideIndex => _currentSlideIndex;
  bool get isBlackScreenActive => _isBlackScreenActive;

  /// Atualiza lista de displays disponíveis
  void updateAvailableDisplays(List<ExternalDisplay> displays) {
    _availableDisplays.clear();
    _availableDisplays.addAll(displays);
    _discoveryController.add(List.unmodifiable(_availableDisplays));
    notifyListeners();
  }

  /// Atualiza estado de um display específico
  void updateDisplayState(String displayId, DisplayConnectionState newState, {String? message}) {
    final displayIndex = _availableDisplays.indexWhere((d) => d.id == displayId);
    if (displayIndex != -1) {
      final oldDisplay = _availableDisplays[displayIndex];
      final newDisplay = oldDisplay.copyWith(state: newState);
      _availableDisplays[displayIndex] = newDisplay;
      
      // Atualizar display conectado se necessário
      if (_connectedDisplay?.id == displayId) {
        _connectedDisplay = newDisplay;
      }
      
      // Emitir evento de mudança
      _stateController.add(DisplayStateChangeEvent(
        display: newDisplay,
        previousState: oldDisplay.state,
        newState: newState,
        message: message,
        timestamp: DateTime.now(),
      ));
      
      notifyListeners();
    }
  }

  /// Atualiza display conectado
  void setConnectedDisplay(ExternalDisplay? display) {
    _connectedDisplay = display;
    notifyListeners();
  }

  /// Atualiza estado de apresentação
  void setPresentationState(bool presenting, {PresentationItem? item}) {
    _isPresenting = presenting;
    if (item != null) {
      _currentItem = item;
      _currentSlideIndex = 0;
    }
    if (!presenting) {
      _currentItem = null;
      _currentSlideIndex = 0;
      _isBlackScreenActive = false;
    }
    notifyListeners();
  }

  @override
  Future<void> updatePresentationSettings({
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    TextAlign? textAlignment,
  }) async {
    if (fontSize != null) _fontSize = fontSize;
    if (textColor != null) _textColor = textColor;
    if (backgroundColor != null) _backgroundColor = backgroundColor;
    if (textAlignment != null) _textAlignment = textAlignment;
    
    notifyListeners();
    
    // Subclasses podem override para implementar sync com display
  }

  @override
  Future<void> toggleBlackScreen(bool active) async {
    _isBlackScreenActive = active;
    notifyListeners();
    
    // Subclasses podem override para implementar no display
  }

  @override
  Future<void> nextSlide() async {
    if (_currentItem != null && _currentSlideIndex < getTotalSlides() - 1) {
      _currentSlideIndex++;
      notifyListeners();
    }
  }

  @override
  Future<void> previousSlide() async {
    if (_currentItem != null && _currentSlideIndex > 0) {
      _currentSlideIndex--;
      notifyListeners();
    }
  }

  @override
  Future<void> goToSlide(int index) async {
    if (_currentItem != null && index >= 0 && index < getTotalSlides()) {
      _currentSlideIndex = index;
      notifyListeners();
    }
  }

  /// Obter total de slides do item atual
  int getTotalSlides() {
    if (_currentItem == null) return 0;
    // TODO: Implementar lógica de slides múltiplos se necessário
    return 1;
  }

  @override
  void setLanguageService(LanguageService languageService) {
    _languageService = languageService;
  }
  
  // Getter estático para acesso global
  static BaseDisplayManager? get globalInstance => _globalDisplayManager;
  
  // Método de sincronização com Riverpod
  void syncWithRiverpod(DisplayManagerState state) {
    bool hasChanged = false;
    
    if (_availableDisplays.length != state.availableDisplays.length ||
        _connectedDisplay != state.connectedDisplay ||
        _isPresenting != state.isPresenting ||
        _currentItem != state.currentItem ||
        _currentSlideIndex != state.currentSlideIndex ||
        _isBlackScreenActive != state.isBlackScreenActive ||
        _fontSize != state.fontSize ||
        _textColor != state.textColor ||
        _backgroundColor != state.backgroundColor ||
        _textAlignment != state.textAlignment) {
      
      _availableDisplays.clear();
      _availableDisplays.addAll(state.availableDisplays);
      _connectedDisplay = state.connectedDisplay;
      _isPresenting = state.isPresenting;
      _currentItem = state.currentItem;
      _currentSlideIndex = state.currentSlideIndex;
      _isBlackScreenActive = state.isBlackScreenActive;
      _fontSize = state.fontSize;
      _textColor = state.textColor;
      _backgroundColor = state.backgroundColor;
      _textAlignment = state.textAlignment;
      
      hasChanged = true;
    }
    
    if (hasChanged) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stateController.close();
    _discoveryController.close();
    
    if (_globalDisplayManager == this) {
      _globalDisplayManager = null;
    }
    
    super.dispose();
  }

  /// Log helper para debugging
  void debugLog(String message) {
    if (kDebugMode) {
      debugPrint('📺 DisplayManager: $message');
    }
  }
}

/// Exception para erros relacionados ao DisplayManager
class DisplayManagerException implements Exception {
  final String message;
  final String? displayId;
  final dynamic originalError;

  const DisplayManagerException(
    this.message, {
    this.displayId,
    this.originalError,
  });

  @override
  String toString() {
    var msg = 'DisplayManagerException: $message';
    if (displayId != null) msg += ' (Display: $displayId)';
    if (originalError != null) msg += ' - Original: $originalError';
    return msg;
  }
}