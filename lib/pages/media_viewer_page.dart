import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/widgets/media_player_widget.dart';
import 'package:versee/services/media_playback_service.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/pages/presenter_page.dart';

/// Página dedicada para visualização e reprodução de mídia
/// Permite aos usuários ver imagens, reproduzir áudio e vídeo diretamente
class MediaViewerPage extends StatefulWidget {
  final MediaItem mediaItem;
  final List<MediaItem>? playlist;
  final int? currentIndex;
  final String? playlistTitle;

  const MediaViewerPage({
    super.key,
    required this.mediaItem,
    this.playlist,
    this.currentIndex,
    this.playlistTitle,
  });

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  late MediaItem _currentMedia;
  late int _currentIndex;
  bool _isFullscreen = false;
  bool _showControls = true;
  
  @override
  void initState() {
    super.initState();
    _currentMedia = widget.mediaItem;
    _currentIndex = widget.currentIndex ?? 0;
    
    // Auto-hide controls for videos after 3 seconds
    if (_currentMedia.type == MediaContentType.video) {
      _startControlsTimer();
    }
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentMedia.type == MediaContentType.video) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls && _currentMedia.type == MediaContentType.video) {
      _startControlsTimer();
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _goToPrevious() {
    if (widget.playlist != null && _currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _currentMedia = widget.playlist![_currentIndex];
        _showControls = true;
      });
      
      if (_currentMedia.type == MediaContentType.video) {
        _startControlsTimer();
      }
    }
  }

  void _goToNext() {
    if (widget.playlist != null && _currentIndex < widget.playlist!.length - 1) {
      setState(() {
        _currentIndex++;
        _currentMedia = widget.playlist![_currentIndex];
        _showControls = true;
      });
      
      if (_currentMedia.type == MediaContentType.video) {
        _startControlsTimer();
      }
    }
  }

  void _startPresentation() {
    // Converter MediaItem para PresentationItem
    final presentationItem = _currentMedia.toPresentationItem();
    
    // Navegar para o presenter em modo solo
    PresenterNavigation.startSoloMode(context, presentationItem);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen ? null : _buildAppBar(),
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Media player
            Center(
              child: MediaPlayerWidget(
                mediaItem: _currentMedia,
                showControls: _showControls,
                autoPlay: _currentMedia.type != MediaContentType.image,
                onPlaybackComplete: () {
                  // Auto avançar para próximo item da playlist
                  if (widget.playlist != null && _currentIndex < widget.playlist!.length - 1) {
                    _goToNext();
                  }
                },
              ),
            ),
            
            // Media info overlay (sempre visível para imagens)
            if (_showControls || _currentMedia.type == MediaContentType.image)
              _buildMediaInfoOverlay(),
            
            // Navigation controls for playlist
            if (widget.playlist != null && _showControls) 
              _buildPlaylistNavigation(),
              
            // Fullscreen toggle (bottom right)
            if (_showControls) _buildFullscreenToggle(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentMedia.displayTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.playlist != null) ...[
            const SizedBox(height: 2),
            Consumer<LanguageService>(
              builder: (context, languageService, child) {
                return Text(
                  '${_currentIndex + 1} de ${widget.playlist!.length} • ${widget.playlistTitle ?? languageService.strings.playlist}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ],
        ],
      ),
      actions: [
        Consumer<LanguageService>(
          builder: (context, languageService, child) {
            return IconButton(
              icon: const Icon(Icons.slideshow, color: Colors.white),
              tooltip: languageService.strings.startPresentation,
              onPressed: _startPresentation,
            );
          },
        ),
        Consumer<LanguageService>(
          builder: (context, languageService, child) {
            return IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white),
              tooltip: languageService.strings.fullscreen,
              onPressed: _toggleFullscreen,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMediaInfoOverlay() {
    return Positioned(
      top: _isFullscreen ? 20 : 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isFullscreen) ...[
                  Consumer<LanguageService>(
                    builder: (context, languageService, child) {
                      return Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.slideshow, color: Colors.white),
                            onPressed: _startPresentation,
                          ),
                          IconButton(
                            icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                            onPressed: _toggleFullscreen,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  _currentMedia.displayTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getMediaTypeLabel(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                if (_currentMedia.description != null && _currentMedia.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _currentMedia.description!,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (widget.playlist != null) ...[
                  const SizedBox(height: 8),
                  Consumer<LanguageService>(
                    builder: (context, languageService, child) {
                      return Text(
                        '${_currentIndex + 1} de ${widget.playlist!.length} • ${widget.playlistTitle ?? languageService.strings.playlist}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistNavigation() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Consumer<LanguageService>(
                builder: (context, languageService, child) {
                  return IconButton(
                    icon: Icon(
                      Icons.skip_previous,
                      color: _currentIndex > 0 ? Colors.white : Colors.grey,
                      size: 32,
                    ),
                    onPressed: _currentIndex > 0 ? _goToPrevious : null,
                    tooltip: languageService.strings.previous,
                  );
                },
              ),
              const SizedBox(width: 16),
              Consumer<LanguageService>(
                builder: (context, languageService, child) {
                  return IconButton(
                    icon: const Icon(
                      Icons.slideshow,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _startPresentation,
                    tooltip: languageService.strings.startPresentation,
                  );
                },
              ),
              const SizedBox(width: 16),
              Consumer<LanguageService>(
                builder: (context, languageService, child) {
                  return IconButton(
                    icon: Icon(
                      Icons.skip_next,
                      color: _currentIndex < widget.playlist!.length - 1 ? Colors.white : Colors.grey,
                      size: 32,
                    ),
                    onPressed: _currentIndex < widget.playlist!.length - 1 ? _goToNext : null,
                    tooltip: languageService.strings.next,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenToggle() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return IconButton(
                icon: Icon(
                  _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: _toggleFullscreen,
                tooltip: _isFullscreen ? languageService.strings.exitFullscreen : languageService.strings.fullscreen,
              );
            },
          ),
        ),
      ),
    );
  }

  String _getMediaTypeLabel() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final strings = languageService.strings;
    
    switch (_currentMedia.type) {
      case MediaContentType.audio:
        final audioItem = _currentMedia as AudioItem;
        return audioItem.artist != null 
          ? '${audioItem.artist} • ${strings.audio}'
          : strings.audio;
      case MediaContentType.video:
        return strings.videos;
      case MediaContentType.image:
        final imageItem = _currentMedia as ImageItem;
        return imageItem.resolution != null 
          ? '${imageItem.resolution} • ${strings.images}'
          : strings.images;
    }
  }
}

/// Métodos de navegação para MediaViewerPage
class MediaViewerNavigation {
  /// Abre um item de mídia único
  static void openMedia(BuildContext context, MediaItem mediaItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaViewerPage(mediaItem: mediaItem),
      ),
    );
  }

  /// Abre uma playlist de mídia
  static void openPlaylist(
    BuildContext context, 
    List<MediaItem> playlist, 
    int currentIndex,
    {String? playlistTitle}
  ) {
    if (playlist.isEmpty) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaViewerPage(
          mediaItem: playlist[currentIndex],
          playlist: playlist,
          currentIndex: currentIndex,
          playlistTitle: playlistTitle,
        ),
      ),
    );
  }
}