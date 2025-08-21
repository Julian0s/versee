import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/media_service.dart';
import 'package:versee/services/file_manager_service.dart';

class StorageInfoWidget extends StatefulWidget {
  const StorageInfoWidget({super.key});

  @override
  State<StorageInfoWidget> createState() => _StorageInfoWidgetState();
}

class _StorageInfoWidgetState extends State<StorageInfoWidget> {
  Map<String, dynamic>? _storageInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    try {
      final mediaService = Provider.of<MediaService>(context, listen: false);
      final info = await mediaService.getStorageInfo();
      if (mounted) {
        setState(() {
          _storageInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Carregando informações de armazenamento...'),
            ],
          ),
        ),
      );
    }

    if (_storageInfo == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Erro ao carregar informações de armazenamento.'),
        ),
      );
    }

    final totalFiles = _storageInfo!['totalFiles'] as int;
    final totalSize = _storageInfo!['totalSize'] as int;
    final audioFiles = _storageInfo!['audioFiles'] as int;
    final videoFiles = _storageInfo!['videoFiles'] as int;
    final imageFiles = _storageInfo!['imageFiles'] as int;
    final audioSize = _storageInfo!['audioSize'] as int;
    final videoSize = _storageInfo!['videoSize'] as int;
    final imageSize = _storageInfo!['imageSize'] as int;

    return Card(
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
                  'Armazenamento de Mídia',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _loadStorageInfo();
                  },
                  tooltip: 'Atualizar',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Total summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$totalFiles arquivo${totalFiles != 1 ? 's' : ''} • ${FileManagerService.formatFileSize(totalSize)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Breakdown by type
            _buildTypeRow(
              context,
              icon: Icons.music_note,
              label: 'Áudio',
              count: audioFiles,
              size: audioSize,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildTypeRow(
              context,
              icon: Icons.play_circle_outline,
              label: 'Vídeo',
              count: videoFiles,
              size: videoSize,
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            _buildTypeRow(
              context,
              icon: Icons.image,
              label: 'Imagens',
              count: imageFiles,
              size: imageSize,
              color: Colors.green,
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: totalFiles > 0 ? _showCleanupDialog : null,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Limpeza'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Show detailed storage breakdown
                      _showDetailedStorageInfo();
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Detalhes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeRow(BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required int size,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          '$count arquivo${count != 1 ? 's' : ''}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          FileManagerService.formatFileSize(size),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpeza de Arquivos'),
        content: const Text(
          'Esta função irá remover arquivos não utilizados que não estão associados a nenhum item de mídia.\n\n'
          'Esta operação não pode ser desfeita. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performCleanup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCleanup() async {
    try {
      // TODO: Implementar cleanupUnusedFiles no MediaService
      // final mediaService = Provider.of<MediaService>(context, listen: false);
      // await mediaService.cleanupUnusedFiles();
      
      // Por enquanto, apenas simula a limpeza
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Função de limpeza em desenvolvimento'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadStorageInfo(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro durante a limpeza: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDetailedStorageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações Detalhadas'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Total de Arquivos', '${_storageInfo!['totalFiles']}'),
              _buildDetailItem('Tamanho Total', FileManagerService.formatFileSize(_storageInfo!['totalSize'])),
              const Divider(),
              _buildDetailItem('Arquivos de Áudio', '${_storageInfo!['audioFiles']}'),
              _buildDetailItem('Tamanho de Áudio', FileManagerService.formatFileSize(_storageInfo!['audioSize'])),
              const Divider(),
              _buildDetailItem('Arquivos de Vídeo', '${_storageInfo!['videoFiles']}'),
              _buildDetailItem('Tamanho de Vídeo', FileManagerService.formatFileSize(_storageInfo!['videoSize'])),
              const Divider(),
              _buildDetailItem('Arquivos de Imagem', '${_storageInfo!['imageFiles']}'),
              _buildDetailItem('Tamanho de Imagem', FileManagerService.formatFileSize(_storageInfo!['imageSize'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}