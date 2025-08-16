import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/media_service.dart';

class ThumbnailCacheWidget extends StatelessWidget {
  const ThumbnailCacheWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaService>(
      builder: (context, mediaService, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: mediaService.getStorageInfo(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final storageInfo = snapshot.data!;
            final totalFiles = storageInfo['totalFiles'] as int;
            final totalSize = storageInfo['totalSize'] as int;

            if (totalFiles == 0) {
              return const SizedBox.shrink();
            }

            return Card(
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.storage,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Armazenamento',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Storage breakdown
                    _buildStorageItem(
                      context,
                      'Áudio',
                      storageInfo['audioFiles'] as int,
                      storageInfo['audioSize'] as int,
                      Icons.music_note,
                      Colors.green,
                    ),
                    _buildStorageItem(
                      context,
                      'Vídeo',
                      storageInfo['videoFiles'] as int,
                      storageInfo['videoSize'] as int,
                      Icons.play_circle_outline,
                      Colors.blue,
                    ),
                    _buildStorageItem(
                      context,
                      'Imagens',
                      storageInfo['imageFiles'] as int,
                      storageInfo['imageSize'] as int,
                      Icons.image,
                      Colors.orange,
                    ),
                    
                    const Divider(height: 24),
                    
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$totalFiles arquivo${totalFiles != 1 ? 's' : ''}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              _formatFileSize(totalSize),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStorageItem(
    BuildContext context,
    String label,
    int fileCount,
    int size,
    IconData icon,
    Color color,
  ) {
    if (fileCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$fileCount arquivo${fileCount != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatFileSize(size),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class MediaImportProgressDialog extends StatefulWidget {
  final String title;
  final Stream<double> progressStream;
  final VoidCallback? onCancel;

  const MediaImportProgressDialog({
    super.key,
    required this.title,
    required this.progressStream,
    this.onCancel,
  });

  @override
  State<MediaImportProgressDialog> createState() => _MediaImportProgressDialogState();
}

class _MediaImportProgressDialogState extends State<MediaImportProgressDialog> {
  double _progress = 0.0;
  String _currentTask = 'Preparando...';

  @override
  void initState() {
    super.initState();
    widget.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
          _currentTask = _getTaskDescription(progress);
        });
      }
    });
  }

  String _getTaskDescription(double progress) {
    if (progress < 0.1) return 'Preparando...';
    if (progress < 0.3) return 'Copiando arquivos...';
    if (progress < 0.7) return 'Extraindo metadados...';
    if (progress < 0.9) return 'Gerando thumbnails...';
    if (progress < 1.0) return 'Finalizando...';
    return 'Concluído!';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentTask,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      actions: [
        if (widget.onCancel != null && _progress < 1.0)
          TextButton(
            onPressed: widget.onCancel,
            child: const Text('Cancelar'),
          ),
        if (_progress >= 1.0)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
      ],
    );
  }
}