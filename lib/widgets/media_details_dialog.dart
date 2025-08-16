import 'dart:io';
import 'package:flutter/material.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/services/file_manager_service.dart';
import 'package:versee/pages/media_viewer_page.dart';

class MediaDetailsDialog extends StatelessWidget {
  final MediaItem mediaItem;

  const MediaDetailsDialog({
    super.key,
    required this.mediaItem,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with thumbnail/icon and title
            Row(
              children: [
                _buildThumbnailOrIcon(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mediaItem.displayTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getMediaTypeText(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Details section
            _buildDetailItem(context, 'Tipo', _getMediaTypeText()),
            _buildDetailItem(context, 'Criado em', _formatDate(mediaItem.createdDate)),
            
            if (mediaItem.description != null && mediaItem.description!.isNotEmpty)
              _buildDetailItem(context, 'Descrição', mediaItem.description!),
            
            // Type-specific details
            ..._buildTypeSpecificDetails(context),
            
            _buildDetailItem(context, 'Origem', _getSourceTypeText()),
            _buildDetailItem(context, 'Caminho', mediaItem.sourcePath, isPath: true),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    MediaViewerNavigation.openMedia(context, mediaItem);
                  },
                  icon: const Icon(Icons.preview),
                  label: const Text('Visualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTypeSpecificDetails(BuildContext context) {
    final details = <Widget>[];
    
    switch (mediaItem.type) {
      case MediaContentType.audio:
        final audioItem = mediaItem as AudioItem;
        if (audioItem.duration != null) {
          details.add(_buildDetailItem(context, 'Duração', _formatDuration(audioItem.duration!)));
        }
        if (audioItem.artist != null) {
          details.add(_buildDetailItem(context, 'Artista', audioItem.artist!));
        }
        if (audioItem.album != null) {
          details.add(_buildDetailItem(context, 'Álbum', audioItem.album!));
        }
        if (audioItem.format != null) {
          details.add(_buildDetailItem(context, 'Formato', audioItem.format!));
        }
        if (audioItem.bitrate != null) {
          details.add(_buildDetailItem(context, 'Bitrate', '${audioItem.bitrate} kbps'));
        }
        if (audioItem.fileSize != null) {
          details.add(_buildDetailItem(context, 'Tamanho', FileManagerService.formatFileSize(audioItem.fileSize!)));
        }
        break;
        
      case MediaContentType.video:
        final videoItem = mediaItem as VideoItem;
        if (videoItem.duration != null) {
          details.add(_buildDetailItem(context, 'Duração', _formatDuration(videoItem.duration!)));
        }
        if (videoItem.resolution != null) {
          details.add(_buildDetailItem(context, 'Resolução', videoItem.resolution!));
        }
        if (videoItem.format != null) {
          details.add(_buildDetailItem(context, 'Formato', videoItem.format!));
        }
        if (videoItem.frameRate != null) {
          details.add(_buildDetailItem(context, 'FPS', '${videoItem.frameRate!.toStringAsFixed(1)}'));
        }
        if (videoItem.bitrate != null) {
          details.add(_buildDetailItem(context, 'Bitrate', '${(videoItem.bitrate! / 1000).toStringAsFixed(1)} Mbps'));
        }
        if (videoItem.fileSize != null) {
          details.add(_buildDetailItem(context, 'Tamanho', FileManagerService.formatFileSize(videoItem.fileSize!)));
        }
        break;
        
      case MediaContentType.image:
        final imageItem = mediaItem as ImageItem;
        details.add(_buildDetailItem(context, 'Resolução', imageItem.resolution));
        if (imageItem.format != null) {
          details.add(_buildDetailItem(context, 'Formato', imageItem.format!));
        }
        if (imageItem.fileSize != null) {
          details.add(_buildDetailItem(context, 'Tamanho', FileManagerService.formatFileSize(imageItem.fileSize!)));
        }
        break;
    }
    
    return details;
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, {bool isPath = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: isPath ? 'monospace' : null,
                fontSize: isPath ? 12 : null,
              ),
              maxLines: isPath ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getMediaTypeText() {
    switch (mediaItem.type) {
      case MediaContentType.audio:
        return 'Áudio';
      case MediaContentType.video:
        return 'Vídeo';
      case MediaContentType.image:
        return 'Imagem';
    }
  }

  String _getSourceTypeText() {
    switch (mediaItem.sourceType) {
      case MediaSourceType.file:
        return 'Arquivo Local';
      case MediaSourceType.url:
        return 'URL/Online';
      case MediaSourceType.device:
        return 'Dispositivo';
      case MediaSourceType.local:
        return 'Cache Local';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Widget _buildThumbnailOrIcon(BuildContext context) {
    String? thumbnailPath;
    
    // Get thumbnail path based on media type
    if (mediaItem is AudioItem) {
      thumbnailPath = (mediaItem as AudioItem).thumbnailUrl;
    } else if (mediaItem is VideoItem) {
      thumbnailPath = (mediaItem as VideoItem).thumbnailUrl;
    } else if (mediaItem is ImageItem) {
      thumbnailPath = (mediaItem as ImageItem).thumbnailUrl;
    }

    // If thumbnail exists and file is valid, show thumbnail
    if (thumbnailPath != null && File(thumbnailPath).existsSync()) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.file(
            File(thumbnailPath),
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultIcon(context);
            },
          ),
        ),
      );
    }

    // Fallback to default icon
    return _buildDefaultIcon(context);
  }

  Widget _buildDefaultIcon(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        mediaItem.displayIcon,
        color: Theme.of(context).colorScheme.primary,
        size: 32,
      ),
    );
  }
}