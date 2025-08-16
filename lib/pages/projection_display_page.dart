import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/dual_screen_service.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/widgets/media_player_widget.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/utils/media_utils.dart';

/// Página de exibição para projeção em tela secundária
/// Esta é a tela que o público vê projetada
class ProjectionDisplayPage extends StatelessWidget {
  const ProjectionDisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<DualScreenService>(
        builder: (context, service, child) {
          return StreamBuilder<PresentationState>(
            stream: service.presentationStateStream,
            initialData: PresentationState(
              currentItem: service.currentItem,
              isPresenting: service.isPresenting,
              isBlackScreenActive: service.isBlackScreenActive,
              currentSlideIndex: service.currentSlideIndex,
            ),
            builder: (context, snapshot) {
              final state = snapshot.data!;
              
              if (state.isBlackScreenActive) {
                return _buildBlackScreen();
              }
              
              if (!state.isPresenting || state.currentItem == null) {
                return _buildWaitingScreen();
              }
              
              return StreamBuilder<PresentationSettings>(
                stream: service.settingsStream,
                initialData: PresentationSettings(
                  fontSize: service.fontSize,
                  textColor: service.textColor,
                  backgroundColor: service.backgroundColor,
                  textAlignment: service.textAlignment,
                ),
                builder: (context, settingsSnapshot) {
                  final settings = settingsSnapshot.data!;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color: settings.backgroundColor,
                    child: _buildSlideContent(
                      state.currentItem!,
                      settings,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBlackScreen() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: SizedBox.shrink(),
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.slideshow,
              color: Colors.white.withValues(alpha: 0.3),
              size: 120,
            ),
            const SizedBox(height: 32),
            Text(
              'VERSEE',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aguardando apresentação...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideContent(PresentationItem item, PresentationSettings settings) {
    switch (item.type) {
      case ContentType.bible:
        return _buildBibleSlide(item, settings);
      case ContentType.lyrics:
        return _buildLyricsSlide(item, settings);
      case ContentType.notes:
        return _buildNotesSlide(item, settings);
      case ContentType.image:
        return _buildImageSlide(item, settings);
      case ContentType.video:
        return _buildVideoSlide(item, settings);
      case ContentType.audio:
        return _buildAudioSlide(item, settings);
    }
  }

  Widget _buildBibleSlide(PresentationItem item, PresentationSettings settings) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Texto do versículo
          Flexible(
            child: Text(
              item.content,
              style: TextStyle(
                color: settings.textColor,
                fontSize: settings.fontSize,
                fontWeight: FontWeight.w500,
                height: 1.4,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: settings.textAlignment,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Referência bíblica
          Text(
            item.metadata?['reference'] ?? '',
            style: TextStyle(
              color: settings.textColor.withValues(alpha: 0.8),
              fontSize: settings.fontSize * 0.7,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsSlide(PresentationItem item, PresentationSettings settings) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Text(
          item.content,
          style: TextStyle(
            color: settings.textColor,
            fontSize: settings.fontSize,
            fontWeight: FontWeight.w500,
            height: 1.5,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: settings.textAlignment,
        ),
      ),
    );
  }

  Widget _buildNotesSlide(PresentationItem item, PresentationSettings settings) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: SingleChildScrollView(
        child: Text(
          item.content,
          style: TextStyle(
            color: settings.textColor,
            fontSize: settings.fontSize * 0.8,
            fontWeight: FontWeight.w400,
            height: 1.6,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: settings.textAlignment,
        ),
      ),
    );
  }

  Widget _buildImageSlide(PresentationItem item, PresentationSettings settings) {
    return Consumer<DualScreenService>(
      builder: (context, dualScreenService, child) {
        // Verificar se o item tem metadados de mídia
        final mediaId = item.metadata?['mediaId'] as String?;
        
        if (mediaId != null && dualScreenService.hasMediaService) {
          // Reconstruir MediaItem a partir dos metadados
          final mediaItem = ImageItem(
            id: mediaId,
            title: item.title,
            description: item.metadata?['description'] as String?,
            createdDate: DateTime.now(),
            sourceType: MediaUtils.parseSourceType(item.metadata?['sourceType']),
            sourcePath: item.content,
            width: item.metadata?['width'] as int?,
            height: item.metadata?['height'] as int?,
            resolution: item.metadata?['resolution'] as String?,
            format: item.metadata?['format'] as String?,
            fileSize: item.metadata?['fileSize'] as int?,
            thumbnailUrl: item.metadata?['thumbnailUrl'] as String?,
          );
          
          return MediaPlayerWidget(
            mediaItem: mediaItem,
            showControls: false, // Para projeção, não mostrar controles
          );
        }
        
        // Fallback para imagem simples
        return Container(
          color: settings.backgroundColor,
          child: Center(
            child: Image.network(
              item.content,
              fit: BoxFit.contain,
              headers: const {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Erro ao carregar imagem da projeção: ${item.content} - $error');
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      color: settings.textColor.withValues(alpha: 0.5),
                      size: 120,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Erro ao carregar imagem',
                      style: TextStyle(
                        color: settings.textColor.withValues(alpha: 0.7),
                        fontSize: settings.fontSize * 0.6,
                      ),
                    ),
                  ],
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: settings.textColor,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Carregando imagem...',
                      style: TextStyle(
                        color: settings.textColor.withValues(alpha: 0.7),
                        fontSize: settings.fontSize * 0.6,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoSlide(PresentationItem item, PresentationSettings settings) {
    return Consumer<DualScreenService>(
      builder: (context, dualScreenService, child) {
        // Verificar se o item tem metadados de mídia
        final mediaId = item.metadata?['mediaId'] as String?;
        
        if (mediaId != null && dualScreenService.hasMediaService) {
          // Reconstruir MediaItem a partir dos metadados
          final mediaItem = VideoItem(
            id: mediaId,
            title: item.title,
            description: item.metadata?['description'] as String?,
            createdDate: DateTime.now(),
            sourceType: MediaUtils.parseSourceType(item.metadata?['sourceType']),
            sourcePath: item.content,
            category: item.metadata?['category'] as String?,
            duration: MediaUtils.parseDuration(item.metadata?['duration']),
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
            mediaItem: mediaItem,
            autoPlay: false, // Para controle manual
            showControls: false, // Para projeção, controles ficam na tela de controle
          );
        }
        
        // Fallback para tela de placeholder
        return Container(
          color: settings.backgroundColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_filled,
                  color: settings.textColor,
                  size: 120,
                ),
                const SizedBox(height: 20),
                Text(
                  item.title,
                  style: TextStyle(
                    color: settings.textColor,
                    fontSize: settings.fontSize,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Aguardando reprodução...',
                  style: TextStyle(
                    color: settings.textColor.withValues(alpha: 0.7),
                    fontSize: settings.fontSize * 0.6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioSlide(PresentationItem item, PresentationSettings settings) {
    return Consumer<DualScreenService>(
      builder: (context, dualScreenService, child) {
        // Verificar se o item tem metadados de mídia
        final mediaId = item.metadata?['mediaId'] as String?;
        
        if (mediaId != null && dualScreenService.hasMediaService) {
          // Reconstruir MediaItem a partir dos metadados
          final mediaItem = AudioItem(
            id: mediaId,
            title: item.title,
            description: item.metadata?['description'] as String?,
            createdDate: DateTime.now(),
            sourceType: MediaUtils.parseSourceType(item.metadata?['sourceType']),
            sourcePath: item.content,
            category: item.metadata?['category'] as String?,
            duration: MediaUtils.parseDuration(item.metadata?['duration']),
            artist: item.metadata?['artist'] as String?,
            album: item.metadata?['album'] as String?,
            thumbnailUrl: item.metadata?['thumbnailUrl'] as String?,
            bitrate: item.metadata?['bitrate'] as int?,
            format: item.metadata?['format'] as String?,
            fileSize: item.metadata?['fileSize'] as int?,
          );
          
          return MediaPlayerWidget(
            mediaItem: mediaItem,
            autoPlay: false, // Para controle manual
            showControls: false, // Para projeção, controles ficam na tela de controle
          );
        }
        
        // Fallback para tela de placeholder
        return Container(
          color: settings.backgroundColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note,
                  color: settings.textColor,
                  size: 120,
                ),
                const SizedBox(height: 20),
                Text(
                  item.title,
                  style: TextStyle(
                    color: settings.textColor,
                    fontSize: settings.fontSize,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Aguardando reprodução...',
                  style: TextStyle(
                    color: settings.textColor.withValues(alpha: 0.7),
                    fontSize: settings.fontSize * 0.6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}