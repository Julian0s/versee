import 'package:flutter/foundation.dart';
import 'package:versee/models/media_models.dart';

/// Serviço para controlar a reprodução de mídia no sistema dual screen
/// Gerencia o estado de reprodução e coordena com a apresentação
class MediaPlaybackService extends ChangeNotifier {
  MediaItem? _currentMedia;
  bool _isPlaying = false;
  bool _isPaused = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  bool _isMuted = false;

  // Callbacks para controle do player widget
  VoidCallback? _playCallback;
  VoidCallback? _pauseCallback;
  VoidCallback? _stopCallback;
  Function(Duration)? _seekCallback;
  Function(double)? _volumeCallback;

  // Getters
  MediaItem? get currentMedia => _currentMedia;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get isMuted => _isMuted;

  // Estado da reprodução
  bool get hasMedia => _currentMedia != null;
  bool get canPlay => hasMedia && !_isPlaying;
  bool get canPause => hasMedia && _isPlaying;
  bool get canStop => hasMedia && (_isPlaying || _isPaused);
  bool get canSeek => hasMedia && _duration > Duration.zero;

  // Progresso da reprodução (0.0 - 1.0)
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  // Getters adicionais para compatibilidade com MediaSyncService
  Duration get currentPosition => _position;
  String? get currentMediaId => _currentMedia?.id;

  /// Define a mídia atual para reprodução
  void setCurrentMedia(MediaItem? media) {
    if (_currentMedia?.id != media?.id) {
      _currentMedia = media;
      _resetPlaybackState();
      notifyListeners();
    }
  }

  /// Registra callbacks do player widget para controle
  void registerPlayerCallbacks({
    VoidCallback? onPlay,
    VoidCallback? onPause,
    VoidCallback? onStop,
    Function(Duration)? onSeek,
    Function(double)? onVolume,
  }) {
    _playCallback = onPlay;
    _pauseCallback = onPause;
    _stopCallback = onStop;
    _seekCallback = onSeek;
    _volumeCallback = onVolume;
  }

  /// Inicia a reprodução
  Future<void> play() async {
    if (!hasMedia || _isPlaying) return;

    try {
      _playCallback?.call();
      _isPlaying = true;
      _isPaused = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao iniciar reprodução: $e');
    }
  }

  /// Pausa a reprodução
  Future<void> pause() async {
    if (!hasMedia || !_isPlaying) return;

    try {
      _pauseCallback?.call();
      _isPlaying = false;
      _isPaused = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao pausar reprodução: $e');
    }
  }

  /// Para a reprodução
  Future<void> stop() async {
    if (!hasMedia) return;

    try {
      _stopCallback?.call();
      _isPlaying = false;
      _isPaused = false;
      _position = Duration.zero;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao parar reprodução: $e');
    }
  }

  /// Inicia reprodução de uma mídia específica
  Future<void> playMedia(String mediaId) async {
    // Esta implementação seria conectada com o MediaItem apropriado
    // Por enquanto, apenas inicia se já há mídia carregada
    if (_currentMedia?.id == mediaId) {
      await play();
    }
  }

  /// Resume reprodução (alias para play para compatibilidade)
  Future<void> resume() async {
    await play();
  }

  /// Seek para posição específica (alias para seekTo para compatibilidade)
  Future<void> seek(Duration position) async {
    await seekTo(position);
  }

  /// Alterna entre play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Busca uma posição específica na mídia
  Future<void> seekTo(Duration position) async {
    if (!hasMedia || !canSeek) return;

    try {
      _seekCallback?.call(position);
      _position = position;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao buscar posição: $e');
    }
  }

  /// Busca por porcentagem (0.0 - 1.0)
  Future<void> seekToPercentage(double percentage) async {
    if (!canSeek) return;
    
    final position = Duration(
      milliseconds: (_duration.inMilliseconds * percentage).round(),
    );
    await seekTo(position);
  }

  /// Avança alguns segundos
  Future<void> forward(int seconds) async {
    final newPosition = _position + Duration(seconds: seconds);
    final maxPosition = _duration;
    
    if (newPosition >= maxPosition) {
      await seekTo(maxPosition);
    } else {
      await seekTo(newPosition);
    }
  }

  /// Retrocede alguns segundos
  Future<void> rewind(int seconds) async {
    final newPosition = _position - Duration(seconds: seconds);
    
    if (newPosition <= Duration.zero) {
      await seekTo(Duration.zero);
    } else {
      await seekTo(newPosition);
    }
  }

  /// Define o volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    if (!hasMedia) return;

    _volume = volume.clamp(0.0, 1.0);
    _isMuted = _volume == 0.0;
    
    try {
      _volumeCallback?.call(_volume);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao definir volume: $e');
    }
  }

  /// Ativa/desativa mudo
  Future<void> toggleMute() async {
    if (_isMuted) {
      await setVolume(1.0);
    } else {
      await setVolume(0.0);
    }
  }

  /// Atualiza a posição atual (chamado pelo player widget)
  void updatePosition(Duration position) {
    if (_position != position) {
      _position = position;
      notifyListeners();
    }
  }

  /// Atualiza a duração total (chamado pelo player widget)
  void updateDuration(Duration duration) {
    if (_duration != duration) {
      _duration = duration;
      notifyListeners();
    }
  }

  /// Atualiza o estado de reprodução (chamado pelo player widget)
  void updatePlaybackState({
    bool? isPlaying,
    bool? isPaused,
  }) {
    bool changed = false;
    
    if (isPlaying != null && _isPlaying != isPlaying) {
      _isPlaying = isPlaying;
      changed = true;
    }
    
    if (isPaused != null && _isPaused != isPaused) {
      _isPaused = isPaused;
      changed = true;
    }
    
    if (changed) {
      notifyListeners();
    }
  }

  /// Notifica que a reprodução foi concluída
  void onPlaybackComplete() {
    _isPlaying = false;
    _isPaused = false;
    _position = Duration.zero;
    notifyListeners();
  }

  /// Reseta o estado de reprodução
  void _resetPlaybackState() {
    _isPlaying = false;
    _isPaused = false;
    _position = Duration.zero;
    _duration = Duration.zero;
  }

  /// Limpa a mídia atual
  void clearMedia() {
    setCurrentMedia(null);
  }

  /// Formata duração para exibição
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  /// Obtém informações da mídia atual
  String get currentMediaInfo {
    if (!hasMedia) return 'Nenhuma mídia selecionada';
    
    final media = _currentMedia!;
    final parts = <String>[media.title];
    
    if (media is AudioItem && media.artist != null) {
      parts.add(media.artist!);
    } else if (media is VideoItem && media.resolution != null) {
      parts.add(media.resolution!);
    }
    
    return parts.join(' • ');
  }

  /// Obtém o status atual da reprodução
  String get playbackStatus {
    if (!hasMedia) return 'Parado';
    if (_isPlaying) return 'Reproduzindo';
    if (_isPaused) return 'Pausado';
    return 'Parado';
  }

  @override
  void dispose() {
    _playCallback = null;
    _pauseCallback = null;
    _stopCallback = null;
    _seekCallback = null;
    _volumeCallback = null;
    super.dispose();
  }
}