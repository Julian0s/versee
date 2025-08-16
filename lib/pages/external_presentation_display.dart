import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/presentation_engine_service.dart';
import 'package:versee/services/dual_screen_service.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/widgets/media_player_widget.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/utils/media_utils.dart';

/// Widget para exibição na apresentação externa (Presentation API)
/// Este widget é renderizado no Flutter engine separado para display externo
class ExternalPresentationDisplay extends StatelessWidget {
  const ExternalPresentationDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<PresentationEngineService>(
          builder: (context, engineService, child) {
            return StreamBuilder<PresentationEngineState>(
              stream: engineService.stateStream,
              initialData: engineService.getCurrentState(),
              builder: (context, snapshot) {
                final state = snapshot.data!;
                
                // Show black screen if active
                if (state.isBlackScreenActive) {
                  return _buildBlackScreen();
                }
                
                // Show waiting screen if no content
                if (!state.isPresentationReady || state.currentItem == null) {
                  return _buildWaitingScreen();
                }
                
                // Show content
                return _buildContent(state.currentItem!);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBlackScreen() {
    return Container(
      color: Colors.black,
      child: const SizedBox.expand(),
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

  Widget _buildContent(PresentationItem item) {
    switch (item.type) {
      case ContentType.bible:
        return _buildBibleContent(item);
      case ContentType.lyrics:
        return _buildLyricsContent(item);
      case ContentType.notes:
        return _buildNotesContent(item);
      case ContentType.image:
        return _buildImageContent(item);
      case ContentType.video:
        return _buildVideoContent(item);
      case ContentType.audio:
        return _buildAudioContent(item);
    }
  }

  Widget _buildBibleContent(PresentationItem item) {
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w500,
                height: 1.4,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Referência bíblica
          Text(
            item.metadata?['reference'] ?? '',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 28,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              shadows: const [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(1, 1),
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

  Widget _buildLyricsContent(PresentationItem item) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Text(
          item.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w500,
            height: 1.5,
            shadows: [
              Shadow(
                color: Colors.black54,
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildNotesContent(PresentationItem item) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: SingleChildScrollView(
        child: Text(
          item.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w400,
            height: 1.6,
            shadows: [
              Shadow(
                color: Colors.black54,
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Widget _buildImageContent(PresentationItem item) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Image.network(
          item.content,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          headers: const {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 120,
                ),
                const SizedBox(height: 20),
                Text(
                  'Erro ao carregar imagem',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 18,
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
                  color: Colors.white,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  'Carregando imagem...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 20,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoContent(PresentationItem item) {
    // For now, show placeholder - video playback in external display requires more complex setup
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 120,
            ),
            const SizedBox(height: 20),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(2, 2),
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
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioContent(PresentationItem item) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              color: Colors.white,
              size: 120,
            ),
            const SizedBox(height: 20),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Reproduzindo áudio...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}