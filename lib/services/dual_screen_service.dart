import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/services/media_playback_service.dart';
import 'package:versee/services/presentation_manager.dart';
import 'package:versee/services/presentation_engine_service.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/utils/media_utils.dart';

/// Serviço para gerenciar apresentação em dual screen
/// Permite separar a tela de controle da tela de apresentação
class DualScreenService extends ChangeNotifier {
  // Referências aos serviços
  MediaPlaybackService? _mediaPlaybackService;
  PresentationManager? _presentationManager;
  PresentationEngineService? _presentationEngine;
  
  // Estados da apresentação
  PresentationItem? _currentItem;
  bool _isPresenting = false;
  bool _isBlackScreenActive = false;
  // Conexão será gerenciada pelo DisplayManager
  int _currentSlideIndex = 0;
  
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

  // Injeta o serviço de reprodução de mídia
  void setMediaPlaybackService(MediaPlaybackService service) {
    _mediaPlaybackService = service;
  }

  // Injeta o gerenciador de apresentação
  void setPresentationManager(PresentationManager manager) {
    _presentationManager = manager;
    
    // Listen to presentation manager state changes
    _presentationManager?.stateStream.listen((state) {
      _syncWithPresentationManager(state);
    });
  }

  // Injeta o serviço de engine de apresentação
  void setPresentationEngine(PresentationEngineService engine) {
    _presentationEngine = engine;
  }

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
  bool get hasMediaService => _mediaPlaybackService != null;
  MediaPlaybackService? get mediaPlaybackService => _mediaPlaybackService;

  @override
  void dispose() {
    _presentationStateController.close();
    _settingsController.close();
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
      if (_presentationManager != null) {
        // Verificar se há display externo disponível
        final hasExternal = await _presentationManager!.checkForExternalDisplays();
        
        if (hasExternal) {
          // Iniciar apresentação externa
          final success = await _presentationManager!.startExternalPresentation();
          
          if (success) {
            // Atualizar conteúdo na apresentação externa
            await _presentationManager!.updatePresentationContent(item);
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
    _mediaPlaybackService?.stop();
    
    // Parar apresentação externa se ativa
    await _stopExternalPresentation();
    
    _broadcastPresentationState();
    notifyListeners();
    
    HapticFeedback.lightImpact();
  }

  /// Para apresentação externa
  Future<void> _stopExternalPresentation() async {
    try {
      if (_presentationManager?.isExternalPresentationActive == true) {
        await _presentationManager!.stopExternalPresentation();
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
      if (_presentationManager?.isExternalPresentationActive == true) {
        await _presentationManager!.setBlackScreen(_isBlackScreenActive);
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
    if (_mediaPlaybackService == null) return;
    
    final mediaItem = MediaUtils.createMediaItemFromPresentation(item);
    if (mediaItem != null) {
      _mediaPlaybackService!.setCurrentMedia(mediaItem);
    }
  }

  /// Controles de mídia para integração com controles de apresentação
  Future<void> playMedia() async {
    await _mediaPlaybackService?.play();
  }

  Future<void> pauseMedia() async {
    await _mediaPlaybackService?.pause();
  }

  Future<void> stopMedia() async {
    await _mediaPlaybackService?.stop();
  }

  Future<void> toggleMediaPlayPause() async {
    await _mediaPlaybackService?.togglePlayPause();
  }

  /// Verifica se o item atual é de mídia
  bool get isCurrentItemMedia {
    if (_currentItem?.metadata == null) return false;
    final mediaType = _currentItem!.metadata!['mediaType'];
    return mediaType == 'audio' || mediaType == 'video' || mediaType == 'image';
  }

  /// Verifica se a mídia está reproduzindo
  bool get isMediaPlaying => _mediaPlaybackService?.isPlaying ?? false;

  /// Verifica se há mídia carregada
  bool get hasCurrentMedia => _mediaPlaybackService?.hasMedia ?? false;

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
  bool get hasExternalDisplay => _presentationManager?.hasExternalDisplay ?? false;
  
  /// Verificar se apresentação externa está ativa
  bool get isExternalPresentationActive => _presentationManager?.isExternalPresentationActive ?? false;
  
  /// Obter informações do display externo
  String? get externalDisplayName => _presentationManager?.activeDisplayName;
  
  /// Forçar atualização do conteúdo na apresentação externa
  Future<void> refreshExternalPresentation() async {
    if (_currentItem != null && _presentationManager?.isExternalPresentationActive == true) {
      await _presentationManager!.updatePresentationContent(_currentItem!);
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