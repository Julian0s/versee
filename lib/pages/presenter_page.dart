import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:versee/models/bible_models.dart';
import 'package:versee/pages/playlist_item_manager_page.dart';
import 'package:versee/pages/presentation_control_page.dart';
import 'package:versee/services/verse_collection_service.dart';
import 'package:versee/services/media_service.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/models/note_models.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/widgets/media_player_widget.dart';

enum PresentationMode { playlist, solo }

class PresenterPage extends StatefulWidget {
  final PresentationItem? initialSoloItem;
  final List<PresentationItem>? initialPlaylistItems;
  final String? initialPlaylistTitle;

  const PresenterPage({
    super.key,
    this.initialSoloItem,
    this.initialPlaylistItems,
    this.initialPlaylistTitle,
  });

  @override
  State<PresenterPage> createState() => _PresenterPageState();
}

class _PresenterPageState extends State<PresenterPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  // Estado da apresentação
  PresentationMode _currentMode = PresentationMode.playlist;
  Playlist? _activePlaylist;
  PresentationItem? _activeSoloItem;
  int _currentSlideIndex = 0;
  bool _isPresenting = false;

  // Controles avançados
  bool _isBlackScreenActive = false;
  bool _isAutoPlayEnabled = false;
  Duration _autoPlayDelay = const Duration(seconds: 5);
  double _presentationOpacity = 1.0;

  // Estado para controles via teclado
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Configure initial presentation if provided
    _configureInitialPresentation();

    // Solicitar foco para controles por teclado quando em apresentação
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isPresenting) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  void _configureInitialPresentation() {
    if (widget.initialSoloItem != null) {
      // Configure solo mode
      setState(() {
        _activeSoloItem = widget.initialSoloItem;
        _activePlaylist = null;
        _currentMode = PresentationMode.solo;
        _currentSlideIndex = 0;
        _isPresenting = false;
      });
      // Navigate to presentation tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController.animateTo(1);
      });
    } else if (widget.initialPlaylistItems != null &&
        widget.initialPlaylistItems!.isNotEmpty) {
      // Configure playlist mode with provided items
      final temporaryPlaylist = Playlist(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        title: widget.initialPlaylistTitle ?? 'Seleção Temporária',
        icon: Icons.slideshow,
        items: widget.initialPlaylistItems!,
      );

      setState(() {
        _activePlaylist = temporaryPlaylist;
        _activeSoloItem = null;
        _currentMode = PresentationMode.playlist;
        _currentSlideIndex = 0;
        _isPresenting = false;
      });
      // Navigate to presentation tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController.animateTo(1);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _isPresenting
          ? null
          : AppBar(
              title: const Text("VERSEE",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Theme.of(context).colorScheme.surface,
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: context.watch<LanguageService>().strings.playlist, icon: Icon(Icons.queue_music)),
                  Tab(text: context.watch<LanguageService>().strings.presenter, icon: Icon(Icons.slideshow)),
                ],
              ),
            ),
      body: _isPresenting
          ? _buildPresentationView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPlaylistsTab(),
                _buildPresentationTab(),
              ],
            ),
    );
  }

  // Tab de Playlists
  Widget _buildPlaylistsTab() {
    return Consumer<PlaylistService>(
      builder: (context, playlistService, child) {
        final playlists = playlistService.playlists;

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: _createNewPlaylist,
                              icon: Icon(
                                Icons.add,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              tooltip: 'Nova Playlist',
                            ),
                            IconButton(
                              onPressed: _showSoloModeDialog,
                              icon: Icon(
                                Icons.flash_on,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 24,
                              ),
                              tooltip: 'Modo Solo',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status da apresentação ativa
              if (_hasContent()) _buildActiveSessionBanner(),

              // Playlists List
              Expanded(
                child: playlists.isEmpty
                    ? _buildEmptyPlaylistsState()
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        itemCount: playlists.length,
                        onReorder: (oldIndex, newIndex) => _reorderPlaylists(oldIndex, newIndex, playlistService),
                        buildDefaultDragHandles: false, // Remove handles padrão
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          return PlaylistCard(
                            key: ValueKey(playlist.id),
                            playlist: playlist,
                            index: index,
                            onTap: () => _selectPlaylist(playlist),
                            onEdit: () => _editPlaylist(playlist),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Tab de Apresentação
  Widget _buildPresentationTab() {
    if (_activePlaylist == null && _activeSoloItem == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.slideshow, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              context.watch<LanguageService>().strings.selectPlaylistMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          // Informações da apresentação ativa
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _currentMode == PresentationMode.playlist
                          ? Icons.queue_music
                          : Icons.flash_on,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentMode == PresentationMode.playlist
                          ? 'Playlist'
                          : 'Modo Solo',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getActiveTitle(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getActiveSubtitle(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),

          // Preview do slide atual
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                ),
              ),
              child: _buildSlidePreview(),
            ),
          ),

          // Controles de apresentação
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Botões principais
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.skip_previous,
                      label: 'Anterior',
                      onPressed: _canGoPrevious() ? _previousSlide : null,
                    ),
                    _buildMainPresentButton(),
                    _buildControlButton(
                      icon: Icons.cast_rounded,
                      label: 'Dual Screen',
                      onPressed:
                          _hasContent() ? _startDualScreenPresentation : null,
                    ),
                    _buildControlButton(
                      icon: Icons.skip_next,
                      label: 'Próximo',
                      onPressed: _canGoNext() ? _nextSlide : null,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Widget de controles avançados
                // Controles removidos - usar PresentationControlPage

                const SizedBox(height: 12),

                // Indicador de progresso
                if (_currentMode == PresentationMode.playlist &&
                    _activePlaylist != null)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: _activePlaylist!.items.isEmpty
                            ? 0
                            : (_currentSlideIndex + 1) /
                                _activePlaylist!.items.length,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_currentSlideIndex + 1} de ${_activePlaylist!.items.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Vista de apresentação em tela cheia
  Widget _buildPresentationView() {
    final currentItem = _getCurrentItem();
    if (currentItem == null) {
      return Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return Center(child: Text(languageService.strings.noContentSelected));
        },
      );
    }

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyboardEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedOpacity(
          opacity: _isBlackScreenActive ? 0.0 : _presentationOpacity,
          duration: const Duration(milliseconds: 300),
          child: Stack(
            children: [
              // Conteúdo principal
              Center(child: _buildSlideContent(currentItem, fullScreen: true)),

              // Controles overlay (sempre visíveis para facilitar controle)
              Positioned(
                bottom: 50,
                left: 20,
                right: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isBlackScreenActive
                        ? Colors.black.withValues(
                            alpha: 0.9) // Mais sólido durante blackout
                        : Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(25),
                    border: _isBlackScreenActive
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1)
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPresentationControlButton(
                        icon: Icons.skip_previous,
                        onPressed: _canGoPrevious() ? _previousSlide : null,
                        tooltip: 'Anterior (A)',
                      ),
                      _buildPresentationControlButton(
                        icon: _isBlackScreenActive
                            ? Icons.visibility
                            : Icons.visibility_off,
                        onPressed: _toggleBlackScreen,
                        tooltip: 'Tela Preta (B)',
                        color: _isBlackScreenActive ? Colors.orange : null,
                      ),
                      _buildPresentationControlButton(
                        icon: Icons.stop,
                        onPressed: () => setState(() => _isPresenting = false),
                        tooltip: 'Parar (ESC)',
                        color: Colors.red,
                      ),
                      _buildPresentationControlButton(
                        icon:
                            _isAutoPlayEnabled ? Icons.pause : Icons.play_arrow,
                        onPressed: _toggleAutoPlay,
                        tooltip: 'Auto-Play (P)',
                      ),
                      _buildPresentationControlButton(
                        icon: Icons.skip_next,
                        onPressed: _canGoNext() ? _nextSlide : null,
                        tooltip: 'Próximo (D)',
                      ),
                    ],
                  ),
                ),
              ),

              // Indicador de slide
              if (_currentMode == PresentationMode.playlist &&
                  _activePlaylist != null &&
                  !_isBlackScreenActive)
                Positioned(
                  top: 50,
                  right: 20,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${_currentSlideIndex + 1}/${_activePlaylist!.items.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),

              // Indicador de auto-play
              if (_isAutoPlayEnabled && !_isBlackScreenActive)
                Positioned(
                  top: 50,
                  left: 20,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('AUTO',
                            style:
                                TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlidePreview() {
    final currentItem = _getCurrentItem();
    if (currentItem == null) {
      return Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return Center(
            child: Text(
              languageService.strings.noSlideSelected,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
    }

    return _buildSlideContent(currentItem);
  }

  Widget _buildNoteSlideContent(PresentationItem item, TextStyle defaultTextStyle, bool fullScreen) {
    // Extract slide information from metadata
    final slideMetadata = item.metadata;
    final slideBackgroundColor = slideMetadata?['backgroundColor'] != null
        ? Color(slideMetadata!['backgroundColor'] as int)
        : Colors.black;
    final slideBackgroundImageUrl = slideMetadata?['backgroundImageUrl'] as String?;
    final slideTextStyle = slideMetadata?['textStyle'] as Map<String, dynamic>?;
    final hasTextShadow = slideMetadata?['hasTextShadow'] as bool? ?? false;
    final shadowColor = slideMetadata?['shadowColor'] != null
        ? Color(slideMetadata!['shadowColor'] as int)
        : Colors.black;
    final shadowBlurRadius = (slideMetadata?['shadowBlurRadius'] as double?) ?? 2.0;
    final shadowOffsetX = (slideMetadata?['shadowOffsetX'] as double?) ?? 1.0;
    final shadowOffsetY = (slideMetadata?['shadowOffsetY'] as double?) ?? 1.0;

    // Build text style from slide metadata
    TextStyle slideTextStyleResolved = defaultTextStyle;
    if (slideTextStyle != null) {
      slideTextStyleResolved = TextStyle(
        color: slideTextStyle['color'] != null
            ? Color(slideTextStyle['color'] as int)
            : defaultTextStyle.color,
        fontSize: slideTextStyle['fontSize'] != null
            ? (slideTextStyle['fontSize'] as double) * (fullScreen ? 1.3 : 0.7)
            : defaultTextStyle.fontSize,
        fontWeight: slideTextStyle['fontWeight'] != null
            ? FontWeight.values[slideTextStyle['fontWeight'] as int]
            : defaultTextStyle.fontWeight,
        fontStyle: slideTextStyle['fontStyle'] != null && slideTextStyle['fontStyle'] == 1
            ? FontStyle.italic
            : FontStyle.normal,
        decoration: slideTextStyle['decoration'] != null && slideTextStyle['decoration'] == 1
            ? TextDecoration.underline
            : TextDecoration.none,
        height: item.type == ContentType.notes ? 1.6 : 1.4,
        shadows: hasTextShadow
            ? [
                Shadow(
                  color: shadowColor,
                  offset: Offset(shadowOffsetX, shadowOffsetY),
                  blurRadius: shadowBlurRadius,
                ),
              ]
            : null,
      );
    }

    Widget slideContent = item.type == ContentType.notes
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              item.content,
              style: slideTextStyleResolved,
            ),
          )
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                item.content,
                style: slideTextStyleResolved,
                textAlign: TextAlign.center,
              ),
            ),
          );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: slideBackgroundColor,
        image: slideBackgroundImageUrl != null
            ? DecorationImage(
                image: NetworkImage(
                  slideBackgroundImageUrl,
                  headers: const {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                  },
                ),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  debugPrint('Error loading background image: $exception');
                },
              )
            : null,
      ),
      child: slideBackgroundImageUrl != null
          ? Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3), // Overlay for better text readability
              ),
              child: slideContent,
            )
          : slideContent,
    );
  }

  Widget _buildSlideContent(PresentationItem item, {bool fullScreen = false}) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: fullScreen ? 32 : 16,
      fontWeight: FontWeight.w500,
      height: 1.4,
    );

    switch (item.type) {
      case ContentType.bible:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.content,
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  item.metadata?['reference'] ?? '',
                  style: textStyle.copyWith(
                    fontSize: fullScreen ? 24 : 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

      case ContentType.lyrics:
      case ContentType.notes:
        return _buildNoteSlideContent(item, textStyle, fullScreen);

      case ContentType.image:
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                item.content,
                headers: const {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                },
              ),
              fit: BoxFit.contain,
              onError: (error, stackTrace) {
                debugPrint(
                    'Erro ao carregar imagem da apresentação: ${item.content} - $error');
              },
            ),
          ),
          child: item.content.isEmpty
              ? Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                )
              : null,
        );

      case ContentType.video:
        // Se o item tem metadados de mídia, usar o MediaPlayerWidget
        final mediaId = item.metadata?['mediaId'] as String?;
        if (mediaId != null) {
          // Reconstruir VideoItem a partir dos metadados
          final videoItem = VideoItem(
            id: mediaId,
            title: item.title,
            description: item.metadata?['description'] as String?,
            createdDate: DateTime.now(),
            sourceType: _parseSourceType(item.metadata?['sourceType']),
            sourcePath: item.content,
            category: item.metadata?['category'] as String?,
            duration: _parseDuration(item.metadata?['duration']),
            thumbnailUrl: item.metadata?['thumbnailUrl'] as String?,
            width: item.metadata?['width'] as int?,
            height: item.metadata?['height'] as int?,
            resolution: item.metadata?['resolution'] as String?,
            bitrate: item.metadata?['bitrate'] as int?,
            format: item.metadata?['format'] as String?,
            frameRate: (item.metadata?['frameRate'] as num?)?.toDouble(),
            fileSize: item.metadata?['fileSize'] as int?,
          );

          return MediaPlayerWidget(
            mediaItem: videoItem,
            autoPlay: true,
            showControls: fullScreen,
          );
        }

        // Fallback para ícone
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_filled,
                size: fullScreen ? 80 : 40,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: textStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      case ContentType.audio:
        // Se o item tem metadados de mídia, usar o MediaPlayerWidget
        final mediaId = item.metadata?['mediaId'] as String?;
        if (mediaId != null) {
          // Reconstruir AudioItem a partir dos metadados
          final audioItem = AudioItem(
            id: mediaId,
            title: item.title,
            description: item.metadata?['description'] as String?,
            createdDate: DateTime.now(),
            sourceType: _parseSourceType(item.metadata?['sourceType']),
            sourcePath: item.content,
            category: item.metadata?['category'] as String?,
            duration: _parseDuration(item.metadata?['duration']),
            artist: item.metadata?['artist'] as String?,
            album: item.metadata?['album'] as String?,
            thumbnailUrl: item.metadata?['thumbnailUrl'] as String?,
            bitrate: item.metadata?['bitrate'] as int?,
            format: item.metadata?['format'] as String?,
            fileSize: item.metadata?['fileSize'] as int?,
          );

          return MediaPlayerWidget(
            mediaItem: audioItem,
            autoPlay: true,
            showControls: fullScreen,
          );
        }

        // Fallback para ícone
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note,
                size: fullScreen ? 80 : 40,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: textStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isMainButton = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 32,
      tooltip: label, // Show label as tooltip instead
      style: IconButton.styleFrom(
        backgroundColor: isMainButton && _isPresenting
            ? Colors.red.withValues(alpha: 0.2)
            : onPressed != null
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        foregroundColor: isMainButton && _isPresenting
            ? Colors.red
            : onPressed != null
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.outline,
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildMainPresentButton() {
    return _buildControlButton(
      icon: _isPresenting ? Icons.stop_circle_rounded : Icons.slideshow_rounded,
      label: _isPresenting ? 'Parar' : 'Apresentar',
      onPressed: _hasContent() ? _togglePresentation : null,
      isMainButton: true,
    );
  }

  // Métodos de controle
  void _selectPlaylist(Playlist playlist) {
    setState(() {
      _activePlaylist = playlist;
      _activeSoloItem = null;
      _currentMode = PresentationMode.playlist;
      _currentSlideIndex = 0;
      _isPresenting = false;
    });
    _tabController.animateTo(1);
  }

  void _togglePresentation() {
    setState(() {
      _isPresenting = !_isPresenting;

      if (_isPresenting) {
        // Reset estados de apresentação
        _isBlackScreenActive = false;
        _isAutoPlayEnabled = false;
        _presentationOpacity = 1.0;

        // Solicitar foco para controles por teclado
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _keyboardFocusNode.requestFocus();
        });
      }
    });

    HapticFeedback.mediumImpact();
  }

  void _previousSlide() {
    if (_canGoPrevious()) {
      setState(() {
        _currentSlideIndex--;
        _isBlackScreenActive = false; // Reset tela preta ao voltar
      });
      HapticFeedback.lightImpact();
    }
  }

  void _nextSlide() {
    if (_canGoNext()) {
      setState(() {
        _currentSlideIndex++;
        _isBlackScreenActive = false; // Reset tela preta ao avançar
      });
      HapticFeedback.lightImpact();
    }
  }

  bool _canGoPrevious() {
    return _currentSlideIndex > 0;
  }

  bool _canGoNext() {
    if (_currentMode == PresentationMode.playlist && _activePlaylist != null) {
      return _currentSlideIndex < _activePlaylist!.items.length - 1;
    }
    return false;
  }

  bool _hasContent() {
    return _activePlaylist != null || _activeSoloItem != null;
  }

  PresentationItem? _getCurrentItem() {
    if (_currentMode == PresentationMode.solo) {
      return _activeSoloItem;
    } else if (_activePlaylist != null &&
        _currentSlideIndex < _activePlaylist!.items.length) {
      return _activePlaylist!.items[_currentSlideIndex];
    }
    return null;
  }

  String _getActiveTitle() {
    if (_currentMode == PresentationMode.solo && _activeSoloItem != null) {
      return _activeSoloItem!.title;
    } else if (_activePlaylist != null) {
      return _activePlaylist!.title;
    }
    return '';
  }

  String _getActiveSubtitle() {
    if (_currentMode == PresentationMode.solo && _activeSoloItem != null) {
      return _getContentTypeLabel(_activeSoloItem!.type);
    } else if (_activePlaylist != null) {
      return '${_activePlaylist!.itemCount} itens';
    }
    return '';
  }

  String _getContentTypeLabel(ContentType type) {
    switch (type) {
      case ContentType.bible:
        return 'Versículo Bíblico';
      case ContentType.lyrics:
        return 'Letra de Música';
      case ContentType.notes:
        return 'Nota/Sermão';
      case ContentType.audio:
        return 'Áudio';
      case ContentType.video:
        return 'Vídeo';
      case ContentType.image:
        return 'Imagem';
    }
  }

  // Métodos auxiliares para UI
  Widget _buildActiveSessionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isPresenting
            ? Colors.red.withValues(alpha: 0.1)
            : Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPresenting
              ? Colors.red.withValues(alpha: 0.3)
              : Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isPresenting
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isPresenting ? Icons.slideshow : Icons.queue_music,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPresenting ? 'APRESENTANDO AGORA' : 'SESSÃO ATIVA',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _isPresenting
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _getActiveTitle(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (_isPresenting)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'AO VIVO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaylistsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add,
            size: 80,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return Text(
                languageService.strings.noPlaylistsFound,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Crie sua primeira playlist para organizar\nseus conteúdos de apresentação',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewPlaylist,
            icon: const Icon(Icons.add),
            label: const Text('Criar Primeira Playlist'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresentationControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    Color? color,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: color ?? Colors.white,
        size: 24,
      ),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: onPressed != null
            ? (color?.withValues(alpha: 0.2) ??
                Colors.white.withValues(alpha: 0.1))
            : Colors.grey.withValues(alpha: 0.1),
      ),
    );
  }

  // Método de reordenação das playlists
  void _reorderPlaylists(int oldIndex, int newIndex, PlaylistService playlistService) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final playlists = List<Playlist>.from(playlistService.playlists);
    final playlist = playlists.removeAt(oldIndex);
    playlists.insert(newIndex, playlist);
    
    // Atualizar a ordem no serviço
    playlistService.reorderPlaylists(playlists);
    
    // Feedback tátil
    HapticFeedback.lightImpact();
  }

  // Métodos de ação
  void _createNewPlaylist() {
    showDialog(
      context: context,
      builder: (context) => PlaylistCreationDialog(
        onPlaylistCreated: (playlist) async {
          final playlistService =
              Provider.of<PlaylistService>(context, listen: false);
          final success = await playlistService.addPlaylist(playlist);

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Playlist "${playlist.title}" criada com sucesso!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro ao criar playlist. Tente novamente.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _editPlaylist(Playlist playlist) {
    final strings = context.read<LanguageService>().strings;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${strings.editPlaylist} "${playlist.title}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit playlist'),
              onTap: () {
                Navigator.pop(context);
                _editPlaylistDetails(playlist);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: Text(strings.manageItems),
              subtitle: Text(strings.itemsCount(playlist.itemCount)),
              onTap: () {
                Navigator.pop(context);
                _managePlaylistItems(playlist);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(strings.deletePlaylist,
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deletePlaylist(playlist);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
        ],
      ),
    );
  }

  void _showSoloModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.flash_on, color: Colors.orange),
            SizedBox(width: 8),
            Text('Modo Solo'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apresente conteúdo individual rapidamente.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Text('Use esta funcionalidade para exibir:'),
            SizedBox(height: 8),
            Text('• Um versículo específico'),
            Text('• Uma nota rápida'),
            Text('• Uma imagem ou mídia'),
            Text('• Qualquer conteúdo individual'),
            SizedBox(height: 16),
            Text(
              'Acesse diretamente das outras páginas do app ou use o botão "Apresentar" em qualquer conteúdo.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  // Métodos de controle avançado
  void _handleKeyboardEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.keyD:
        if (_canGoNext()) _nextSlide();
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        if (_canGoPrevious()) _previousSlide();
        break;
      case LogicalKeyboardKey.keyB:
        _toggleBlackScreen();
        break;
      case LogicalKeyboardKey.keyP:
        _toggleAutoPlay();
        break;
      case LogicalKeyboardKey.escape:
        setState(() => _isPresenting = false);
        break;
      case LogicalKeyboardKey.keyF:
        // Toggle fullscreen (implementação futura)
        break;
    }
  }

  void _toggleBlackScreen() {
    setState(() {
      _isBlackScreenActive = !_isBlackScreenActive;
    });

    HapticFeedback.lightImpact();
  }

  void _toggleAutoPlay() {
    setState(() {
      _isAutoPlayEnabled = !_isAutoPlayEnabled;
    });

    if (_isAutoPlayEnabled) {
      _startAutoPlay();
    }

    HapticFeedback.lightImpact();
  }

  void _startAutoPlay() {
    if (!_isAutoPlayEnabled || !_canGoNext()) return;

    Future.delayed(_autoPlayDelay, () {
      if (_isAutoPlayEnabled && _canGoNext() && _isPresenting) {
        _nextSlide();
        _startAutoPlay(); // Continue auto-play
      }
    });
  }

  void _editPlaylistDetails(Playlist playlist) {
    final titleController = TextEditingController(text: playlist.title);
    final descriptionController = TextEditingController(text: playlist.description ?? '');
    IconData selectedIcon = playlist.icon;
    
    // Lista de ícones disponíveis
    final List<IconData> availableIcons = [
      Icons.queue_music,
      Icons.church,
      Icons.menu_book,
      Icons.celebration,
      Icons.school,
      Icons.favorite,
      Icons.star,
      Icons.music_note,
      Icons.mic,
      Icons.slideshow,
      Icons.people,
      Icons.lightbulb,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Playlist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo do título
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                
                const SizedBox(height: 16),
                
                // Campo da descrição
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 16),
                
                // Seleção de ícone
                const Text('Ícone da Playlist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableIcons.map((icon) {
                    final isSelected = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = icon),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTitle = titleController.text.trim();
                final newDescription = descriptionController.text.trim();
                
                if (newTitle.isNotEmpty) {
                  final playlistService = Provider.of<PlaylistService>(context, listen: false);
                  final updatedPlaylist = Playlist(
                    id: playlist.id,
                    title: newTitle,
                    description: newDescription.isEmpty ? null : newDescription,
                    icon: selectedIcon,
                    items: playlist.items,
                    lastModified: DateTime.now(),
                  );
                  
                  final success = await playlistService.updatePlaylist(updatedPlaylist);
                  
                  if (!mounted) return;
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Playlist atualizada com sucesso!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao atualizar playlist. Tente novamente.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _managePlaylistItems(Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistItemManagerPage(playlist: playlist),
      ),
    );
  }

  void _deletePlaylist(Playlist playlist) {
    final strings = context.read<LanguageService>().strings;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deletePlaylist),
        content: Text(
          '${strings.confirmDeletePlaylist} "${playlist.title}"?\n\n'
          '${strings.actionCannotBeUndone}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Fechar o dialog primeiro
              
              // Mostrar loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${strings.deletePlaylist}...'),
                  duration: const Duration(seconds: 2),
                ),
              );
              
              final playlistService = Provider.of<PlaylistService>(context, listen: false);
              debugPrint('🗑️ Tentando deletar playlist: ${playlist.id}');
              
              final success = await playlistService.removePlaylist(playlist.id);

              if (success) {
                debugPrint('✅ Playlist deletada com sucesso');
                
                // Se esta playlist estava ativa, limpar seleção
                if (_activePlaylist?.id == playlist.id) {
                  setState(() {
                    _activePlaylist = null;
                    _isPresenting = false;
                    _currentSlideIndex = 0;
                  });
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.deletePlaylistSuccess(playlist.title)),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else {
                debugPrint('❌ Falha ao deletar playlist');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.deletePlaylistError),
                        const SizedBox(height: 4),
                        const Text(
                          'Verifique sua conexão e permissões.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startDualScreenPresentation() {
    if (_currentMode == PresentationMode.solo && _activeSoloItem != null) {
      // Modo item único
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PresentationControlPage(
            initialItem: _activeSoloItem,
          ),
        ),
      );
    } else if (_activePlaylist != null) {
      // Modo playlist
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PresentationControlPage(
            playlistItems: _activePlaylist!.items,
            playlistTitle: _activePlaylist!.title,
          ),
        ),
      );
    }
  }

  // Métodos auxiliares para parsing de metadados
  MediaSourceType _parseSourceType(dynamic sourceType) {
    if (sourceType is String) {
      switch (sourceType) {
        case 'file':
          return MediaSourceType.file;
        case 'url':
          return MediaSourceType.url;
        case 'device':
          return MediaSourceType.device;
        default:
          return MediaSourceType.file;
      }
    }
    return MediaSourceType.file;
  }

  Duration? _parseDuration(dynamic duration) {
    if (duration is int) {
      return Duration(milliseconds: duration);
    }
    return null;
  }

  // Método estático para gerar dados de exemplo
}

// Método estático para navegação rápida (para uso em outras páginas)
class PresenterNavigation {
  static void startSoloMode(BuildContext context, PresentationItem item) {
    // Navegar para a página Presenter com item configurado para modo solo
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PresenterPage(
          initialSoloItem: item,
        ),
      ),
    );
  }

  // Método para criar PresentationItem a partir de VerseCollection
  static List<PresentationItem> createPresentationItemsFromVerses(
      List<BibleVerse> verses, String title) {
    return verses.map((verse) {
      return PresentationItem(
        id: '${verse.book}_${verse.chapter}_${verse.verse}',
        title: verse.reference,
        type: ContentType.bible,
        content: verse.text,
        metadata: {
          'reference': verse.reference,
          'version': verse.version,
          'book': verse.book,
          'chapter': verse.chapter,
          'verse': verse.verse,
        },
      );
    }).toList();
  }

  // Método para iniciar apresentação de coleção de versículos
  static void startVerseCollectionPresentation(
      BuildContext context, VerseCollection collection) {
    final items =
        createPresentationItemsFromVerses(collection.verses, collection.title);

    if (items.length == 1) {
      // Se apenas um versículo, usar modo solo
      startSoloMode(context, items.first);
    } else {
      // Se múltiplos versículos, criar playlist temporária
      startPlaylistMode(context, items, collection.title);
    }
  }

  // Método para criar playlist temporária a partir de versículos
  static void startPlaylistMode(
      BuildContext context, List<PresentationItem> items, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PresenterPage(
          initialPlaylistItems: items,
          initialPlaylistTitle: title,
        ),
      ),
    );
  }
}

// Widget do card de playlist
class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.index,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Drag Handle - único ícone de drag do lado esquerdo
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.drag_handle,
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Icon Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    playlist.icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                // Playlist Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título da playlist
                      Text(
                        playlist.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Descrição (se existir)
                      if (playlist.description?.isNotEmpty == true) ...[
                        Text(
                          playlist.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                      ],
                      
                      // Contador de itens (sempre presente)
                      Row(
                        children: [
                          Icon(
                            Icons.queue_music,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.read<LanguageService>().strings.itemsCount(playlist.itemCount),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget de diálogo para criação de playlist
class PlaylistCreationDialog extends StatefulWidget {
  final Future<void> Function(Playlist) onPlaylistCreated;

  const PlaylistCreationDialog({
    super.key,
    required this.onPlaylistCreated,
  });

  @override
  State<PlaylistCreationDialog> createState() => _PlaylistCreationDialogState();
}

class _PlaylistCreationDialogState extends State<PlaylistCreationDialog>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  IconData _selectedIcon = Icons.queue_music;
  final List<PresentationItem> _selectedItems = [];

  // Opções de ícones para playlists
  final List<IconData> _availableIcons = [
    Icons.queue_music,
    Icons.church,
    Icons.menu_book,
    Icons.celebration,
    Icons.school,
    Icons.favorite,
    Icons.star,
    Icons.music_note,
    Icons.mic,
    Icons.slideshow,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nova Playlist'),
          actions: [
            TextButton(
              onPressed: _canCreatePlaylist() ? _createPlaylist : null,
              child: const Text('Criar'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campos básicos
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Playlist',
                  hintText: 'Ex: Culto de Domingo',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Descreva o propósito da playlist',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Seleção de ícone
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ícone da Playlist',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableIcons.map((icon) {
                      final isSelected = icon == _selectedIcon;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Tabs para adicionar conteúdo
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Bíblia', icon: Icon(Icons.menu_book)),
                  Tab(text: 'Notas', icon: Icon(Icons.note)),
                  Tab(text: 'Mídia', icon: Icon(Icons.perm_media)),
                ],
              ),

              // Conteúdo das tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBibleTab(),
                    _buildNotesTab(),
                    _buildMediaTab(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Preview dos itens selecionados
              if (_selectedItems.isNotEmpty) ...[
                Text(
                  'Itens Selecionados (${_selectedItems.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _selectedItems.length,
                    itemBuilder: (context, index) {
                      final item = _selectedItems[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(_getContentTypeIcon(item.type)),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_getContentTypeLabel(item.type)),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () =>
                              setState(() => _selectedItems.remove(item)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBibleTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            context.watch<LanguageService>().strings.addSavedVerses,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Expanded(
          child: Consumer<VerseCollectionService>(
            builder: (context, service, child) {
              final collections = service.collections;
              if (collections.isEmpty) {
                return Center(
                  child: Text(context.read<LanguageService>().strings.noSavedVerses),
                );
              }
              return ListView.builder(
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: Text(collection.title),
                      subtitle: Text('${collection.verses.length} versículos'),
                      trailing: ElevatedButton(
                        onPressed: () => _addVerseCollection(collection),
                        child: const Text('Adicionar'),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotesTab() {
    // Sample notes data to demonstrate functionality
    final sampleNotes = [
      NoteItem(
        id: 'note_1',
        title: 'Exemplo: Louvor de Abertura',
        slideCount: 3,
        createdDate: DateTime.now().subtract(const Duration(days: 1)),
        description: 'Letra de música para abertura do culto',
        type: NotesContentType.lyrics,
        slides: [
          NoteSlide(
            id: 'slide_1',
            content:
                'Grande é o Senhor\nE mui digno de ser louvado\nNa cidade do nosso Deus',
            order: 0,
          ),
          NoteSlide(
            id: 'slide_2',
            content:
                'Maravilhoso em santidade\nTerrível em louvores\nOperando maravilhas',
            order: 1,
          ),
          NoteSlide(
            id: 'slide_3',
            content:
                'Santo, Santo, Santo\nÉ o Senhor dos Exércitos\nToda a terra está cheia da sua glória',
            order: 2,
          ),
        ],
      ),
      NoteItem(
        id: 'note_2',
        title: 'Exemplo: Mensagem Principal',
        slideCount: 2,
        createdDate: DateTime.now().subtract(const Duration(hours: 2)),
        description: 'Pontos principais do sermão',
        type: NotesContentType.notes,
        slides: [
          NoteSlide(
            id: 'slide_1',
            content:
                'Ponto 1: O Amor de Deus é incondicional\n\n• Ele nos ama independente das nossas falhas\n• Seu amor não tem limites\n• É demonstrado através de Jesus',
            order: 0,
          ),
          NoteSlide(
            id: 'slide_2',
            content:
                'Ponto 2: Nossa Resposta ao Amor de Deus\n\n• Amar uns aos outros\n• Compartilhar o evangelho\n• Viver em santidade',
            order: 1,
          ),
        ],
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Adicione notas e letras às suas playlists',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Exemplo com dados de demonstração:',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sampleNotes.length,
            itemBuilder: (context, index) {
              final note = sampleNotes[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    note.type == NotesContentType.lyrics
                        ? Icons.music_note
                        : Icons.note,
                    color: note.type == NotesContentType.lyrics
                        ? Colors.purple
                        : Colors.orange,
                  ),
                  title: Text(note.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.description),
                      const SizedBox(height: 4),
                      Text(
                        '${note.slideCount} slides • ${note.type == NotesContentType.lyrics ? "Letra" : "Nota"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _addNoteItem(note),
                    child: const Text('Adicionar'),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMediaTab() {
    return Consumer<MediaService>(
      builder: (context, mediaService, child) {
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Adicione mídia às suas playlists',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              TabBar(
                tabs: const [
                  Tab(text: 'Áudio', icon: Icon(Icons.music_note)),
                  Tab(text: 'Vídeo', icon: Icon(Icons.play_circle_outline)),
                  Tab(text: 'Imagem', icon: Icon(Icons.image)),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildMediaTypeList(context, mediaService.audioItems),
                    _buildMediaTypeList(context, mediaService.videoItems),
                    _buildMediaTypeList(context, mediaService.imageItems),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaTypeList(BuildContext context, List<MediaItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            return Text(languageService.strings.noItemsFound);
          },
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            leading: Icon(
              item.displayIcon,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(item.displayTitle),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.displaySubtitle),
                if (item.description != null && item.description!.isNotEmpty)
                  Text(
                    item.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _addMediaItem(item),
              child: const Text('Adicionar'),
            ),
            isThreeLine:
                item.description != null && item.description!.isNotEmpty,
          ),
        );
      },
    );
  }

  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.bible:
        return Icons.menu_book;
      case ContentType.lyrics:
        return Icons.music_note;
      case ContentType.notes:
        return Icons.note;
      case ContentType.audio:
        return Icons.audiotrack;
      case ContentType.video:
        return Icons.videocam;
      case ContentType.image:
        return Icons.image;
    }
  }

  String _getContentTypeLabel(ContentType type) {
    switch (type) {
      case ContentType.bible:
        return 'Versículo Bíblico';
      case ContentType.lyrics:
        return 'Letra de Música';
      case ContentType.notes:
        return 'Nota/Sermão';
      case ContentType.audio:
        return 'Áudio';
      case ContentType.video:
        return 'Vídeo';
      case ContentType.image:
        return 'Imagem';
    }
  }

  void _addVerseCollection(VerseCollection collection) {
    final items = PresenterNavigation.createPresentationItemsFromVerses(
      collection.verses,
      collection.title,
    );

    setState(() {
      _selectedItems.addAll(items);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${items.length} versículos adicionados')),
    );
  }

  void _addNoteItem(NoteItem note) {
    final items = note.toPresentationItems();

    setState(() {
      _selectedItems.addAll(items);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('${items.length} slides de "${note.title}" adicionados')),
    );
  }

  void _addMediaItem(MediaItem mediaItem) {
    final presentationItem = mediaItem.toPresentationItem();

    setState(() {
      _selectedItems.add(presentationItem);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${mediaItem.displayTitle}" adicionado')),
    );
  }

  bool _canCreatePlaylist() {
    return _titleController.text.trim().isNotEmpty;
  }

  void _createPlaylist() async {
    if (!_canCreatePlaylist()) return;

    final playlist = Playlist(
      id: '', // Firebase irá gerar o ID
      title: _titleController.text.trim(),
      icon: _selectedIcon,
      items: List.from(_selectedItems),
    );

    await widget.onPlaylistCreated(playlist);
    Navigator.pop(context);
  }
}
