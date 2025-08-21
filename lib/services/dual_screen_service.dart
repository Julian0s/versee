import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/utils/media_utils.dart';
import 'package:versee/providers/riverpod_providers.dart';

// Instância global para bridge híbrida
DualScreenService? _globalDualScreenService;

/// Serviço para gerenciar apresentação em dual screen
/// Permite separar a tela de controle da tela de apresentação
class DualScreenService extends ChangeNotifier {
  // Referências aos serviços (MIGRADOS para Riverpod)
  // MediaPlaybackService? null /* _mediaPlaybackService migrado */;
  // PresentationManager? null /* _presentationManager migrado */;
  // PresentationEngineService? _presentationEngine;
  
  // Estados da apresentação
  PresentationItem? _currentItem;
  bool _isPresenting = false;
  bool _isBlackScreenActive = false;
  // Conexão será gerenciada pelo DisplayManager
  int _currentSlideIndex = 0;
  
  // Construtor que configura a instância global
  DualScreenService() {
    _globalDualScreenService = this;
  }
  
  // Configurações de apresentação
  double _fontSize = 32.0;
  Color _textColor = Colors.white;
  Color _backgroundColor = Colors.black;
  TextAlign _textAlignment = TextAlign.center;
  
  // Controladores de stream para sincronização
  final StreamController<PresentationState> _presentationStateController = 
      StreamController<PresentationState>.broadcast();
  
  final StreamController<PresentationSettings> _settingsController = 
      StreamController<PresentationSettings>.broadcast();

  // Getters públicos
  PresentationItem? get currentItem => _currentItem;
  bool get isPresenting => _isPresenting;
  bool get isBlackScreenActive => _isBlackScreenActive;
  // isProjectorConnected será fornecido pelo DisplayManager
  int get currentSlideIndex => _currentSlideIndex;
  double get fontSize => _fontSize;
  Color get textColor => _textColor;
  Color get backgroundColor => _backgroundColor;
  TextAlign get textAlignment => _textAlignment;
  
  // Streams para widgets de apresentação
  Stream<PresentationState> get presentationStateStream => 
      _presentationStateController.stream;
  Stream<PresentationSettings> get settingsStream => 
      _settingsController.stream;

  // Injeta o serviço de reprodução de mídia (MIGRADO)
  // void setMediaPlaybackService(MediaPlaybackService service) {
  //   null /* _mediaPlaybackService migrado */ = service;
  // }

  // Injeta o gerenciador de apresentação (MIGRADO)
  // void setPresentationManager(PresentationManager manager) {
  //   null /* _presentationManager migrado */ = manager;
  //   
  //   // Listen to presentation manager state changes
  //   null /* _presentationManager migrado */?.stateStream.listen((state) {
  //     _syncWithPresentationManager(state);
  //   });
  // }

  // Injeta o serviço de engine de apresentação (MIGRADO)
  // void setPresentationEngine(PresentationEngineService engine) {
  //   _presentationEngine = engine;
  // }

  // Sincroniza com o estado do presentation manager
  void _syncWithPresentationManager(PresentationManagerState state) {
    // Sync black screen state
    if (_isBlackScreenActive != state.isBlackScreenActive) {
      _isBlackScreenActive = state.isBlackScreenActive;
      _broadcastPresentationState();
      notifyListeners();
    }
  }

  // Getter para verificar se há mídia
  bool get hasMediaService => null /* _mediaPlaybackService migrado */ != null;
  // MediaPlaybackService? get mediaPlaybackService => null /* _mediaPlaybackService migrado */; // MIGRADO

  // Getter estático para acesso global
  static DualScreenService? get globalInstance => _globalDualScreenService;
  
  // Método de sincronização com Riverpod
  void syncWithRiverpod(DualScreenState state) {
    bool hasChanged = false;
    
    if (_currentItem != state.currentItem ||
        _isPresenting != state.isPresenting ||
        _isBlackScreenActive != state.isBlackScreenActive ||
        _currentSlideIndex != state.currentSlideIndex ||
        _fontSize != state.fontSize ||
        _textColor != state.textColor ||
        _backgroundColor != state.backgroundColor ||
        _textAlignment != state.textAlignment) {
      
      _currentItem = state.currentItem;
      _isPresenting = state.isPresenting;
      _isBlackScreenActive = state.isBlackScreenActive;
      _currentSlideIndex = state.currentSlideIndex;
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
    _presentationStateController.close();
    _settingsController.close();
    
    if (_globalDualScreenService == this) {
      _globalDualScreenService = null;
    }
    
    super.dispose();
  }

  /// Inicia apresentação em dual screen
  Future<void> startPresentation(PresentationItem item, {int initialSlideIndex = 0}) async {
    _currentItem = item;
    _currentSlideIndex = initialSlideIndex;
    _isPresenting = true;
    _isBlackScreenActive = false;
    
    // Se o item é de mídia, configurar no serviço de reprodução
    _setupMediaIfNeeded(item);
    
    // Tentar iniciar apresentação externa se disponível
    await _tryStartExternalPresentation(item);
    
    _broadcastPresentationState();
    notifyListeners();
    
    // Vibração para feedback
    HapticFeedback.mediumImpact();
  }

  /// Tenta iniciar apresentação em display externo
  Future<void> _tryStartExternalPresentation(PresentationItem item) async {
    try {
      if (null /* _presentationManager migrado */ != null) {
        // Verificar se há display externo disponível
        final hasExternal = await null /* _presentationManager migrado */!.checkForExternalDisplays();
        
        if (hasExternal) {
          // Iniciar apresentação externa
          final success = await null /* _presentationManager migrado */!.startExternalPresentation();
          
          if (success) {
            // Atualizar conteúdo na apresentação externa
            await null /* _presentationManager migrado */!.updatePresentationContent(item);
            debugPrint('📱 Apresentação externa iniciada com sucesso');
          } else {
            debugPrint('📱 Falhou ao iniciar apresentação externa - usando fallback');
          }
        } else {
          debugPrint('📱 Nenhum display externo encontrado - usando apresentação local');
        }
      }
    } catch (e) {
      debugPrint('📱 Erro ao tentar apresentação externa: $e');
    }
  }

  /// Para apresentação
  Future<void> stopPresentation() async {
    _isPresenting = false;
    _isBlackScreenActive = false;
    _currentItem = null;
    _currentSlideIndex = 0;
    
    // Parar reprodução de mídia se houver
    null /* _mediaPlaybackService migrado */?.stop();
    
    // Parar apresentação externa se ativa
    await _stopExternalPresentation();
    
    _broadcastPresentationState();
    notifyListeners();
    
    HapticFeedback.lightImpact();
  }

  /// Para apresentação externa
  Future<void> _stopExternalPresentation() async {
    try {
      if (null /* _presentationManager migrado */?.isExternalPresentationActive == true) {
        await null /* _presentationManager migrado */!.stopExternalPresentation();
        debugPrint('📱 Apresentação externa parada');
      }
    } catch (e) {
      debugPrint('📱 Erro ao parar apresentação externa: $e');
    }
  }

  /// Alterna tela preta
  Future<void> toggleBlackScreen() async {
    _isBlackScreenActive = !_isBlackScreenActive;
    
    // Aplicar tela preta na apresentação externa também
    await _applyBlackScreenToExternal();
    
    _broadcastPresentationState();
    notifyListeners();
    
    HapticFeedback.lightImpact();
  }

  /// Aplica tela preta na apresentação externa
  Future<void> _applyBlackScreenToExternal() async {
    try {
      if (null /* _presentationManager migrado */?.isExternalPresentationActive == true) {
        await null /* _presentationManager migrado */!.setBlackScreen(_isBlackScreenActive);
      }
    } catch (e) {
      debugPrint('📱 Erro ao aplicar tela preta externa: $e');
    }
  }

  /// Navega para próximo slide (se aplicável)
  void nextSlide() {
    if (_currentItem == null) return;
    
    // Verificar se o item tem múltiplos slides
    final slides = _getCurrentItemSlides();
    if (slides.isEmpty) return;
    
    if (_currentSlideIndex < slides.length - 1) {
      _currentSlideIndex++;
      _broadcastPresentationState();
      notifyListeners();
    }
    
    HapticFeedback.lightImpact();
  }

  /// Navega para slide anterior (se aplicável)
  void previousSlide() {
    if (_currentItem == null) return;
    
    if (_currentSlideIndex > 0) {
      _currentSlideIndex--;
      _broadcastPresentationState();
      notifyListeners();
    }
    
    HapticFeedback.lightImpact();
  }
  
  /// Vai para slide específico
  void goToSlide(int index) {
    if (_currentItem == null) return;
    
    final slides = _getCurrentItemSlides();
    if (index >= 0 && index < slides.length) {
      _currentSlideIndex = index;
      _broadcastPresentationState();
      notifyListeners();
      
      HapticFeedback.lightImpact();
    }
  }
  
  /// Obter slides do item atual
  List<dynamic> _getCurrentItemSlides() {
    if (_currentItem == null) return [];
    
    // Se é uma nota com slides
    final slides = _currentItem!.metadata?['slides'] as List<dynamic>?;
    if (slides != null && slides.isNotEmpty) {
      return slides;
    }
    
    // Item simples (mídia, verso, etc) tem apenas um "slide"
    return [_currentItem];
  }
  
  /// Obter total de slides do item atual
  int get totalSlides {
    final slides = _getCurrentItemSlides();
    return slides.length;
  }
  
  /// Verificar se há próximo slide
  bool get hasNextSlide {
    return _currentSlideIndex < totalSlides - 1;
  }
  
  /// Verificar se há slide anterior
  bool get hasPreviousSlide {
    return _currentSlideIndex > 0;
  }

  /// Atualiza configurações de apresentação
  void updatePresentationSettings({
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    TextAlign? textAlignment,
  }) {
    if (fontSize != null) _fontSize = fontSize;
    if (textColor != null) _textColor = textColor;
    if (backgroundColor != null) _backgroundColor = backgroundColor;
    if (textAlignment != null) _textAlignment = textAlignment;
    
    _broadcastPresentationSettings();
    notifyListeners();
  }

  // checkProjectorConnection removido - será substituído pelo DisplayManager

  // MÉTODOS DE CONTROLE DE MÍDIA

  /// Configura mídia se o item de apresentação for de mídia
  void _setupMediaIfNeeded(PresentationItem item) {
    if (null /* _mediaPlaybackService migrado */ == null) return;
    
    final mediaItem = MediaUtils.createMediaItemFromPresentation(item);
    if (mediaItem != null) {
      null /* _mediaPlaybackService migrado */!.setCurrentMedia(mediaItem);
    }
  }

  /// Controles de mídia para integração com controles de apresentação
  Future<void> playMedia() async {
    await null /* _mediaPlaybackService migrado */?.play();
  }

  Future<void> pauseMedia() async {
    await null /* _mediaPlaybackService migrado */?.pause();
  }

  Future<void> stopMedia() async {
    await null /* _mediaPlaybackService migrado */?.stop();
  }

  Future<void> toggleMediaPlayPause() async {
    await null /* _mediaPlaybackService migrado */?.togglePlayPause();
  }

  /// Verifica se o item atual é de mídia
  bool get isCurrentItemMedia {
    if (_currentItem?.metadata == null) return false;
    final mediaType = _currentItem!.metadata!['mediaType'];
    return mediaType == 'audio' || mediaType == 'video' || mediaType == 'image';
  }

  /// Verifica se a mídia está reproduzindo
  bool get isMediaPlaying => null /* _mediaPlaybackService migrado */?.isPlaying ?? false;

  /// Verifica se há mídia carregada
  bool get hasCurrentMedia => null /* _mediaPlaybackService migrado */?.hasMedia ?? false;

  /// Transmite estado atual da apresentação
  void _broadcastPresentationState() {
    final state = PresentationState(
      currentItem: _currentItem,
      isPresenting: _isPresenting,
      isBlackScreenActive: _isBlackScreenActive,
      currentSlideIndex: _currentSlideIndex,
    );
    
    _presentationStateController.add(state);
  }

  /// Transmite configurações atuais
  void _broadcastPresentationSettings() {
    final settings = PresentationSettings(
      fontSize: _fontSize,
      textColor: _textColor,
      backgroundColor: _backgroundColor,
      textAlignment: _textAlignment,
    );
    
    _settingsController.add(settings);
  }

  /// Inicializa o serviço
  Future<void> initialize() async {
    // Configurações padrão para apresentação
    _fontSize = 32.0;
    _textColor = Colors.white;
    _backgroundColor = Colors.black;
    _textAlignment = TextAlign.center;
    
    debugPrint('📱 DualScreenService inicializado com Presentation API');
  }

  /// Verificar se apresentação externa está disponível
  bool get hasExternalDisplay => null /* _presentationManager migrado */?.hasExternalDisplay ?? false;
  
  /// Verificar se apresentação externa está ativa
  bool get isExternalPresentationActive => null /* _presentationManager migrado */?.isExternalPresentationActive ?? false;
  
  /// Obter informações do display externo
  String? get externalDisplayName => null /* _presentationManager migrado */?.activeDisplayName;
  
  /// Forçar atualização do conteúdo na apresentação externa
  Future<void> refreshExternalPresentation() async {
    if (_currentItem != null && null /* _presentationManager migrado */?.isExternalPresentationActive == true) {
      await null /* _presentationManager migrado */!.updatePresentationContent(_currentItem!);
    }
  }
  
  /// Verificar se apresentação está ativa e tem slides
  bool get canNavigateSlides {
    return _isPresenting && totalSlides > 1;
  }
  
  /// Obter informações do slide atual
  Map<String, dynamic> getCurrentSlideInfo() {
    if (_currentItem == null || !_isPresenting) {
      return {
        'currentSlide': 0,
        'totalSlides': 0,
        'canNext': false,
        'canPrevious': false,
        'title': '',
        'content': '',
      };
    }
    
    final slides = _getCurrentItemSlides();
    final currentSlide = slides.isNotEmpty ? slides[_currentSlideIndex] : null;
    
    return {
      'currentSlide': _currentSlideIndex + 1,
      'totalSlides': slides.length,
      'canNext': hasNextSlide,
      'canPrevious': hasPreviousSlide,
      'title': _currentItem!.title,
      'content': currentSlide?.toString() ?? _currentItem!.content,
    };
  }
}

/// Estado da apresentação para sincronização
class PresentationState {
  final PresentationItem? currentItem;
  final bool isPresenting;
  final bool isBlackScreenActive;
  final int currentSlideIndex;

  const PresentationState({
    required this.currentItem,
    required this.isPresenting,
    required this.isBlackScreenActive,
    required this.currentSlideIndex,
  });
}

/// Configurações de apresentação
class PresentationSettings {
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final TextAlign textAlignment;

  const PresentationSettings({
    required this.fontSize,
    required this.textColor,
    required this.backgroundColor,
    required this.textAlignment,
  });
}