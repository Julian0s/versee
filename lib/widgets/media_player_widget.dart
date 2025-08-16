import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/utils/media_utils.dart';
import 'package:versee/services/media_sync_service.dart';
import 'package:versee/services/display_manager.dart';

/// Widget unificado para reprodução de mídia (áudio, vídeo e imagem)
/// Suporta todas as plataformas incluindo web com sincronização multi-display
class MediaPlayerWidget extends StatefulWidget {
  final MediaItem mediaItem;
  final bool autoPlay;
  final bool showControls;
  final bool enableSync;
  final VoidCallback? onPlaybackComplete;
  final Function(Duration)? onPositionChanged;
  final double? aspectRatio;

  const MediaPlayerWidget({
    super.key,
    required this.mediaItem,
    this.autoPlay = false,
    this.showControls = true,
    this.enableSync = true,
    this.onPlaybackComplete,
    this.onPositionChanged,
    this.aspectRatio,
  });

  @override
  State<MediaPlayerWidget> createState() => _MediaPlayerWidgetState();
}

class _MediaPlayerWidgetState extends State<MediaPlayerWidget> {
  // Controladores de vídeo
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // Player de áudio
  AudioPlayer? _audioPlayer;
  
  // Serviços de sincronização
  MediaSyncService? _mediaSyncService;
  DisplayManager? _displayManager;
  
  // Estados de reprodução
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isSyncEnabled = false;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeSyncServices();
    _initializeMedia();
  }
  
  void _initializeSyncServices() {
    if (widget.enableSync) {
      try {
        _mediaSyncService = Provider.of<MediaSyncService>(context, listen: false);
        _displayManager = Provider.of<DisplayManager>(context, listen: false);
        _isSyncEnabled = _displayManager?.hasConnectedDisplay ?? false;
        
        if (_isSyncEnabled) {
          debugPrint('🔄 Sync habilitado para mídia: ${widget.mediaItem.id}');
        }
      } catch (e) {
        debugPrint('⚠️ Serviços de sync não disponíveis: $e');
        _isSyncEnabled = false;
      }
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _audioPlayer?.dispose();
  }

  Future<void> _initializeMedia() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Verificar se o sourcePath é válido antes de tentar inicializar
      final sourcePath = widget.mediaItem.sourcePath.trim();
      if (sourcePath.isEmpty) {
        throw Exception('Caminho da mídia está vazio');
      }

      // Verificar se não é apenas um placeholder da UI
      if (sourcePath.contains('_Namespace') || sourcePath.contains('undefined')) {
        throw Exception('Item de mídia é apenas placeholder da UI');
      }

      debugPrint('Inicializando mídia: ${widget.mediaItem.type} - $sourcePath');

      switch (widget.mediaItem.type) {
        case MediaContentType.video:
          await _initializeVideo();
          break;
        case MediaContentType.audio:
          await _initializeAudio();
          break;
        case MediaContentType.image:
          _initializeImage();
          break;
      }
    } catch (e) {
      debugPrint('Erro ao inicializar mídia: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Erro ao carregar mídia: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeVideo() async {
    try {
      // Validar e configurar a fonte do vídeo
      final sourcePath = widget.mediaItem.sourcePath.trim();
      debugPrint('Tentando carregar vídeo: $sourcePath');
      
      // Verificar se a URL/caminho é válido
      if (sourcePath.isEmpty) {
        throw Exception('Caminho do vídeo está vazio');
      }

      // Suporte para web e mobile
      if (kIsWeb) {
        if (MediaUtils.isValidUrl(sourcePath)) {
          _videoController = VideoPlayerController.networkUrl(Uri.parse(sourcePath));
        } else {
          throw Exception('URL do vídeo inválida: $sourcePath');
        }
      } else {
        if (widget.mediaItem.sourceType == MediaSourceType.url) {
          if (MediaUtils.isValidUrl(sourcePath)) {
            _videoController = VideoPlayerController.networkUrl(Uri.parse(sourcePath));
          } else {
            throw Exception('URL do vídeo inválida: $sourcePath');
          }
        } else {
          // Verificar se o arquivo local existe
          final file = File(sourcePath);
          if (await file.exists()) {
            _videoController = VideoPlayerController.file(file);
          } else {
            throw Exception('Arquivo de vídeo não encontrado: $sourcePath');
          }
        }
      }

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: widget.autoPlay,
        looping: false,
        aspectRatio: widget.aspectRatio ?? _videoController!.value.aspectRatio,
        showControls: widget.showControls,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightGreen,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Erro ao reproduzir vídeo',
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      // Listeners para eventos
      _videoController!.addListener(_videoListener);

      setState(() {
        _isLoading = false;
        _duration = _videoController!.value.duration;
      });
    } catch (e) {
      throw Exception('Falha ao inicializar vídeo: $e');
    }
  }

  Future<void> _initializeAudio() async {
    try {
      _audioPlayer = AudioPlayer();

      // Configurar listeners
      _audioPlayer!.onDurationChanged.listen((duration) {
        setState(() {
          _duration = duration;
        });
      });

      _audioPlayer!.onPositionChanged.listen((position) {
        setState(() {
          _position = position;
        });
        widget.onPositionChanged?.call(position);
      });

      _audioPlayer!.onPlayerStateChanged.listen((state) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      });

      _audioPlayer!.onPlayerComplete.listen((_) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
        widget.onPlaybackComplete?.call();
      });

      // Validar e configurar a fonte do áudio
      final sourcePath = widget.mediaItem.sourcePath.trim();
      debugPrint('Tentando carregar áudio: $sourcePath');
      
      // Verificar se a URL/caminho é válido
      if (sourcePath.isEmpty) {
        throw Exception('Caminho do áudio está vazio');
      }

      // Para web, usar URL diretamente; para mobile, usar arquivo local
      if (kIsWeb || widget.mediaItem.sourceType == MediaSourceType.url) {
        // Validar e normalizar URL antes de tentar carregar
        if (!MediaUtils.isValidUrl(sourcePath)) {
          throw Exception('URL do áudio inválida: $sourcePath');
        }
        
        // Para URLs do Firebase Storage, garantir que estão corretamente codificadas
        String normalizedUrl = sourcePath;
        if (sourcePath.contains('firebasestorage.googleapis.com')) {
          // Recodificar URL para garantir compatibilidade com web
          final uri = Uri.parse(sourcePath);
          normalizedUrl = uri.toString();
          debugPrint('URL normalizada: $normalizedUrl');
          
          // Verificar se a URL tem token de acesso válido
          if (!normalizedUrl.contains('token=') && !normalizedUrl.contains('alt=media')) {
            throw Exception('URL do Firebase Storage sem token de acesso válido');
          }
        }
        
        // Web-specific audio initialization with fallback strategies
        if (kIsWeb) {
          await _initializeWebAudio(normalizedUrl);
        } else {
          await _audioPlayer!.setSourceUrl(normalizedUrl);
        }
        
      } else {
        // Verificar se o arquivo local existe
        final file = File(sourcePath);
        if (await file.exists()) {
          await _audioPlayer!.setSourceDeviceFile(sourcePath);
        } else {
          throw Exception('Arquivo de áudio não encontrado: $sourcePath');
        }
      }

      if (widget.autoPlay) {
        await _audioPlayer!.resume();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro detalhado ao inicializar áudio: $e');
      throw Exception('Falha ao inicializar áudio: $e');
    }
  }

  /// Web-specific audio initialization with optimized formats and fallback
  Future<void> _initializeWebAudio(String url) async {
    // Verificar se há URL de fallback nos metadados
    String? fallbackUrl;
    if (widget.mediaItem is AudioItem) {
      final audioItem = widget.mediaItem as AudioItem;
      fallbackUrl = audioItem.metadata?['fallbackUrl'] as String?;
    }
    
    final strategies = [
      () async {
        // Estratégia 1: URL primária (formato otimizado)
        final mimeType = MediaUtils.getMimeTypeFromUrl(url);
        await _audioPlayer!.setSource(UrlSource(url));
      },
      () async {
        // Estratégia 2: URL primária sem MIME type
        await _audioPlayer!.setSource(UrlSource(url));
      },
      if (fallbackUrl != null) () async {
        // Estratégia 3: URL de fallback (formato compatível)
        final mimeType = MediaUtils.getMimeTypeFromUrl(fallbackUrl!);
        await _audioPlayer!.setSource(UrlSource(fallbackUrl));
      },
      if (fallbackUrl != null) () async {
        // Estratégia 4: URL de fallback sem MIME type
        await _audioPlayer!.setSource(UrlSource(fallbackUrl!));
      },
    ];

    Exception? lastError;
    
    for (int i = 0; i < strategies.length; i++) {
      try {
        await strategies[i]();
        debugPrint('Áudio carregado com estratégia ${i + 1}${i >= 2 ? " (fallback)" : " (otimizado)"}');
        return;
      } catch (e) {
        lastError = Exception('Falha na estratégia ${i + 1}: $e');
        if (i < strategies.length - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    
    throw lastError ?? Exception('Erro ao carregar áudio com todas as estratégias');
  }
  

  void _initializeImage() {
    setState(() {
      _isLoading = false;
    });
  }

  void _videoListener() {
    if (_videoController!.value.hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = _videoController!.value.errorDescription;
      });
    }

    setState(() {
      _isPlaying = _videoController!.value.isPlaying;
      _position = _videoController!.value.position;
      _duration = _videoController!.value.duration;
    });

    widget.onPositionChanged?.call(_position);

    // Verificar se chegou ao fim
    if (_position >= _duration && _duration > Duration.zero) {
      widget.onPlaybackComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    switch (widget.mediaItem.type) {
      case MediaContentType.video:
        return _buildVideoPlayer();
      case MediaContentType.audio:
        return _buildAudioPlayer();
      case MediaContentType.image:
        return _buildImageViewer();
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Carregando mídia...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Erro ao carregar mídia',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Arquivo: ${widget.mediaItem.sourcePath}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _initializeMedia,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Possíveis soluções:',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Verifique sua conexão com a internet\n'
                '• O arquivo pode ter sido movido ou excluído\n'
                '• Tente importar o arquivo novamente\n'
                '• Entre em contato com o suporte se o problema persistir',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      color: Colors.black,
      child: _chewieController != null
          ? Chewie(controller: _chewieController!)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildAudioPlayer() {
    final audioItem = widget.mediaItem as AudioItem;
    
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Thumbnail ou ícone
          _buildAudioThumbnail(audioItem),
          
          const SizedBox(height: 32),
          
          // Informações da música
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                Text(
                  audioItem.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (audioItem.artist != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    audioItem.artist!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Barra de progresso
          if (widget.showControls) _buildAudioProgressBar(),
          
          const SizedBox(height: 24),
          
          // Controles de reprodução
          if (widget.showControls) _buildAudioControls(),
        ],
      ),
    );
  }

  Widget _buildAudioThumbnail(AudioItem audioItem) {
    if (audioItem.thumbnailUrl != null && !kIsWeb) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(audioItem.thumbnailUrl!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultAudioIcon(),
          ),
        ),
      );
    }
    
    return _buildDefaultAudioIcon();
  }

  Widget _buildDefaultAudioIcon() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.music_note,
        size: 80,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildAudioProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          Slider(
            value: _duration.inMilliseconds > 0 
                ? _position.inMilliseconds.toDouble() 
                : 0.0,
            max: _duration.inMilliseconds.toDouble(),
            onChanged: (value) async {
              final position = Duration(milliseconds: value.toInt());
              if (_isSyncEnabled && _mediaSyncService != null && _mediaSyncService!.isSyncing) {
                await _mediaSyncService!.seekSyncedPlayback(value);
              } else {
                await _audioPlayer?.seek(position);
              }
            },
            activeColor: Theme.of(context).primaryColor,
            inactiveColor: Colors.grey,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                MediaUtils.formatDuration(_position),
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                MediaUtils.formatDuration(_duration),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    return Column(
      children: [
        // Indicador de sincronização
        if (_isSyncEnabled) _buildSyncIndicator(),
        
        const SizedBox(height: 16),
        
        // Controles principais
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
              onPressed: () async {
                if (_isSyncEnabled && _mediaSyncService != null) {
                  await _mediaSyncService!.seekSyncedPlayback(0.0);
                } else {
                  await _audioPlayer?.seek(Duration.zero);
                }
              },
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () async {
                  if (_isSyncEnabled && _mediaSyncService != null) {
                    if (_isPlaying) {
                      await _mediaSyncService!.pauseSyncedPlayback();
                    } else {
                      if (!_mediaSyncService!.isSyncing) {
                        await _mediaSyncService!.startSyncedPlayback(
                          widget.mediaItem.id,
                          startPosition: _position.inMilliseconds.toDouble(),
                        );
                      } else {
                        await _mediaSyncService!.resumeSyncedPlayback();
                      }
                    }
                  } else {
                    if (_isPlaying) {
                      await _audioPlayer?.pause();
                    } else {
                      await _audioPlayer?.resume();
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.white, size: 32),
              onPressed: () async {
                if (_isSyncEnabled && _mediaSyncService != null) {
                  await _mediaSyncService!.stopSyncedPlayback();
                } else {
                  await _audioPlayer?.stop();
                }
              },
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
              onPressed: () {
                widget.onPlaybackComplete?.call();
              },
            ),
          ],
        ),
        
        // Controles de sincronização avançados
        if (_isSyncEnabled && widget.showControls) _buildSyncControls(),
      ],
    );
  }
  
  Widget _buildSyncIndicator() {
    return Consumer<MediaSyncService>(
      builder: (context, syncService, child) {
        final isSync = syncService.isSyncing;
        final connectedDisplays = syncService.lastHeartbeats.length;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSync ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSync ? Colors.green : Colors.orange,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSync ? Icons.sync : Icons.sync_disabled,
                color: isSync ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isSync 
                  ? 'Sincronizado ($connectedDisplays displays)'
                  : 'Sync disponível',
                style: TextStyle(
                  color: isSync ? Colors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSyncControls() {
    return Consumer<MediaSyncService>(
      builder: (context, syncService, child) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Volume sincronizado
              Icon(Icons.volume_up, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: Slider(
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) async {
                    setState(() {
                      _volume = value;
                    });
                    await _audioPlayer?.setVolume(value);
                    if (syncService.isSyncing) {
                      await syncService.setSyncedVolume(value);
                    }
                  },
                  activeColor: Theme.of(context).primaryColor,
                  inactiveColor: Colors.grey,
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Status de latência
              if (syncService.displayLatencies.isNotEmpty) ...[
                Icon(Icons.network_check, color: Colors.grey, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${syncService.displayLatencies.values.first.toStringAsFixed(0)}ms',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageViewer() {
    final imageItem = widget.mediaItem as ImageItem;
    final sourcePath = imageItem.sourcePath.trim();
    
    // Validar caminho/URL da imagem
    if (sourcePath.isEmpty) {
      debugPrint('Caminho da imagem está vazio');
      return _buildImageError('Caminho da imagem não especificado');
    }
    
    if (kIsWeb || imageItem.sourceType == MediaSourceType.url) {
      if (!MediaUtils.isValidUrl(sourcePath)) {
        debugPrint('URL da imagem inválida: $sourcePath');
        return _buildImageError('URL da imagem inválida');
      }
      
      return Image.network(
        sourcePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Erro ao carregar imagem: $sourcePath - $error');
          return _buildImageError('Erro ao carregar imagem da internet');
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Carregando imagem...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
        headers: const {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );
    } else {
      return FutureBuilder<bool>(
        future: File(sourcePath).exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Verificando arquivo...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }
          
          if (snapshot.data != true) {
            debugPrint('Arquivo de imagem não encontrado: $sourcePath');
            return _buildImageError('Arquivo de imagem não encontrado');
          }
          
          return Image.file(
            File(sourcePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Erro ao carregar arquivo de imagem: $sourcePath - $error');
              return _buildImageError('Erro ao carregar arquivo de imagem');
            },
          );
        },
      );
    }
  }

  Widget _buildImageError([String? customMessage]) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              Text(
                customMessage ?? 'Não foi possível carregar a imagem',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Arquivo: ${widget.mediaItem.sourcePath}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Métodos públicos para controle externo com suporte a sincronização
  Future<void> play() async {
    if (_isSyncEnabled && _mediaSyncService != null) {
      if (!_mediaSyncService!.isSyncing) {
        await _mediaSyncService!.startSyncedPlayback(
          widget.mediaItem.id,
          startPosition: _position.inMilliseconds.toDouble(),
        );
      } else {
        await _mediaSyncService!.resumeSyncedPlayback();
      }
      return;
    }
    
    switch (widget.mediaItem.type) {
      case MediaContentType.video:
        await _videoController?.play();
        break;
      case MediaContentType.audio:
        await _audioPlayer?.resume();
        break;
      case MediaContentType.image:
        // Imagens não têm reprodução
        break;
    }
  }

  Future<void> pause() async {
    if (_isSyncEnabled && _mediaSyncService != null && _mediaSyncService!.isSyncing) {
      await _mediaSyncService!.pauseSyncedPlayback();
      return;
    }
    
    switch (widget.mediaItem.type) {
      case MediaContentType.video:
        await _videoController?.pause();
        break;
      case MediaContentType.audio:
        await _audioPlayer?.pause();
        break;
      case MediaContentType.image:
        // Imagens não têm reprodução
        break;
    }
  }

  Future<void> stop() async {
    if (_isSyncEnabled && _mediaSyncService != null && _mediaSyncService!.isSyncing) {
      await _mediaSyncService!.stopSyncedPlayback();
      return;
    }
    
    switch (widget.mediaItem.type) {
      case MediaContentType.video:
        await _videoController?.pause();
        await _videoController?.seekTo(Duration.zero);
        break;
      case MediaContentType.audio:
        await _audioPlayer?.stop();
        break;
      case MediaContentType.image:
        // Imagens não têm reprodução
        break;
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_isSyncEnabled && _mediaSyncService != null && _mediaSyncService!.isSyncing) {
      await _mediaSyncService!.seekSyncedPlayback(position.inMilliseconds.toDouble());
      return;
    }
    
    switch (widget.mediaItem.type) {
      case MediaContentType.video:
        await _videoController?.seekTo(position);
        break;
      case MediaContentType.audio:
        await _audioPlayer?.seek(position);
        break;
      case MediaContentType.image:
        // Imagens não têm seek
        break;
    }
  }
  
  // Métodos específicos para sincronização
  Future<void> enableSync() async {
    if (widget.enableSync && _mediaSyncService != null && _displayManager?.hasConnectedDisplay == true) {
      _isSyncEnabled = true;
      setState(() {});
      debugPrint('🔄 Sync habilitado para ${widget.mediaItem.id}');
    }
  }
  
  Future<void> disableSync() async {
    if (_mediaSyncService?.isSyncing == true) {
      await _mediaSyncService!.stopSyncedPlayback();
    }
    _isSyncEnabled = false;
    setState(() {});
    debugPrint('⏹️ Sync desabilitado para ${widget.mediaItem.id}');
  }
  
  Future<void> setVolume(double volume) async {
    setState(() {
      _volume = volume;
    });
    
    if (_isSyncEnabled && _mediaSyncService != null && _mediaSyncService!.isSyncing) {
      await _mediaSyncService!.setSyncedVolume(volume);
    } else {
      switch (widget.mediaItem.type) {
        case MediaContentType.video:
          await _videoController?.setVolume(volume);
          break;
        case MediaContentType.audio:
          await _audioPlayer?.setVolume(volume);
          break;
        case MediaContentType.image:
          // Imagens não têm volume
          break;
      }
    }
  }

  // Getters para estado atual
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get hasError => _hasError;
  bool get isLoading => _isLoading;
  bool get isSyncEnabled => _isSyncEnabled;
  bool get isSyncing => _mediaSyncService?.isSyncing ?? false;
  Map<String, double> get displayLatencies => _mediaSyncService?.displayLatencies ?? {};
}