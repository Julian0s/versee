import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/providers/riverpod_providers.dart';
import 'package:versee/services/local_media_cache_service.dart';

class MediaCacheManagerWidget extends StatefulWidget {
  const MediaCacheManagerWidget({super.key});

  @override
  State<MediaCacheManagerWidget> createState() => _MediaCacheManagerWidgetState();
}

class _MediaCacheManagerWidgetState extends State<MediaCacheManagerWidget> {
  // MediaStorageInfo? _storageInfo; // MIGRADO - tipo não encontrado
  dynamic _storageInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    final hybridService = Provider.of<dynamic /* HybridMediaService migrado */>(context, listen: false);
    
    try {
      final info = await hybridService.getStorageInfo();
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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cache Local de Mídia',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_storageInfo != null)
              _buildStorageInfo(_storageInfo!)
            else
              _buildErrorState(),
            
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageInfo(dynamic info) { // MediaStorageInfo migrado
    return Column(
      children: [
        // Estatísticas gerais
        _buildInfoRow(
          'Itens em Cache',
          '${info.localItemCount} de ${info.totalItemCount}',
          Icons.cached,
        ),
        const SizedBox(height: 12),
        
        _buildInfoRow(
          'Tamanho do Cache',
          info.formattedCacheSize,
          Icons.storage,
        ),
        const SizedBox(height: 12),
        
        _buildInfoRow(
          'Uso do Armazenamento',
          '${info.cacheUsagePercentage.toStringAsFixed(1)}%',
          Icons.pie_chart,
        ),
        const SizedBox(height: 12),
        
        if (info.cacheHitRate > 0)
          _buildInfoRow(
            'Taxa de Acerto',
            '${(info.cacheHitRate * 100).toStringAsFixed(1)}%',
            Icons.speed,
          ),
        
        const SizedBox(height: 20),
        
        // Breakdown por tipo
        _buildMediaTypeBreakdown(info),
        
        const SizedBox(height: 20),
        
        // Barra de progresso do armazenamento
        _buildStorageProgressBar(info),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaTypeBreakdown(dynamic info) { // MediaStorageInfo migrado
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breakdown por Tipo',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTypeCount('Áudio', info.audioCount, Icons.audiotrack),
              _buildTypeCount('Vídeo', info.videoCount, Icons.videocam),
              _buildTypeCount('Imagem', info.imageCount, Icons.image),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCount(String type, int count, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          type,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStorageProgressBar(dynamic info) { // MediaStorageInfo migrado
    final percentage = info.cacheUsagePercentage / 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Uso do Armazenamento',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${info.cacheUsagePercentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        LinearProgressIndicator(
          value: percentage.clamp(0.0, 1.0),
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage > 0.8 
              ? Colors.orange 
              : percentage > 0.9 
                ? Colors.red 
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        
        const SizedBox(height: 4),
        
        if (info.storageQuota > 0)
          Text(
            'Disponível: ${_formatBytes(info.storageQuota - info.localCacheSize)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _refreshStorageInfo,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _syncWithCloud,
                icon: const Icon(Icons.cloud_sync),
                label: const Text('Sincronizar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _clearCache,
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Limpar Cache'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _optimizeCache,
                icon: const Icon(Icons.tune),
                label: const Text('Otimizar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar informações de armazenamento',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStorageInfo,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshStorageInfo() async {
    setState(() {
      _isLoading = true;
    });
    await _loadStorageInfo();
  }

  Future<void> _syncWithCloud() async {
    final hybridService = Provider.of<dynamic /* HybridMediaService migrado */>(context, listen: false);
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Sincronizando com a nuvem...'),
            ],
          ),
        ),
      );
      
      await hybridService.syncWithFirebase();
      await _loadStorageInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronização concluída!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na sincronização: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Cache'),
        content: const Text(
          'Tem certeza que deseja limpar todo o cache local? '
          'As mídias precisarão ser baixadas novamente da nuvem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final hybridService = Provider.of<dynamic /* HybridMediaService migrado */>(context, listen: false);
      
      try {
        await hybridService.clearLocalCache();
        await _loadStorageInfo();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cache limpo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao limpar cache: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _optimizeCache() async {
    final cacheService = LocalMediaCacheService();
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Otimizando cache...'),
            ],
          ),
        ),
      );
      
      await cacheService.cleanupOldCache();
      await _loadStorageInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache otimizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na otimização: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}