import 'dart:async';
import 'package:flutter/material.dart';
import 'package:versee/services/media_upload_service.dart';

/// Dialog para mostrar progresso de otimização de mídia
/// Monitora automaticamente o status das otimizações server-side
class OptimizationProgressDialog extends StatefulWidget {
  final List<String> mediaItemIds;
  final String title;

  const OptimizationProgressDialog({
    super.key,
    required this.mediaItemIds,
    this.title = 'Otimizando mídia',
  });

  @override
  State<OptimizationProgressDialog> createState() => _OptimizationProgressDialogState();
}

class _OptimizationProgressDialogState extends State<OptimizationProgressDialog> {
  final MediaUploadService _uploadService = MediaUploadService();
  Timer? _progressTimer;
  List<OptimizationProgressItem> _items = [];
  bool _isComplete = false;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeProgress();
    _startProgressMonitoring();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _initializeProgress() {
    _items = widget.mediaItemIds.map((id) => OptimizationProgressItem(
      mediaItemId: id,
      status: 'pending',
      progress: 0.0,
    )).toList();
  }

  void _startProgressMonitoring() {
    _progressTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_isComplete) return;
      
      await _checkProgress();
    });
  }

  Future<void> _checkProgress() async {
    try {
      final results = await _uploadService.checkOptimizationProgress(widget.mediaItemIds);
      
      setState(() {
        _completedCount = 0;
        
        for (final result in results) {
          final mediaItemId = result['mediaItemId'] as String;
          final status = result['status'] as Map<String, dynamic>;
          
          final itemIndex = _items.indexWhere((item) => item.mediaItemId == mediaItemId);
          if (itemIndex != -1) {
            final isOptimized = status['isOptimized'] as bool? ?? false;
            
            _items[itemIndex] = _items[itemIndex].copyWith(
              status: isOptimized ? 'completed' : 'processing',
              progress: isOptimized ? 1.0 : 0.7, // Simular progresso durante processamento
              optimizedUrls: status['optimizedUrls'] as Map<String, dynamic>?,
            );
            
            if (isOptimized) _completedCount++;
          }
        }
        
        // Verificar se todos completaram
        if (_completedCount == widget.mediaItemIds.length) {
          _isComplete = true;
          _progressTimer?.cancel();
        }
      });
    } catch (e) {
      debugPrint('Erro ao verificar progresso: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final overallProgress = _items.isNotEmpty 
        ? _items.map((e) => e.progress).reduce((a, b) => a + b) / _items.length
        : 0.0;

    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(
                  _isComplete ? Icons.check_circle : Icons.settings,
                  color: _isComplete ? Colors.green : Theme.of(context).primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isComplete 
                          ? 'Todas as otimizações foram concluídas!'
                          : '$_completedCount de ${widget.mediaItemIds.length} completas',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Progresso geral
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progresso Geral',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: overallProgress,
                  backgroundColor: Colors.grey[700],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isComplete ? Colors.green : Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(overallProgress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Lista de itens
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.grey[700],
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    return _buildProgressItem(_items[index]);
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isComplete) ...[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_isComplete),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isComplete ? Colors.green : Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isComplete ? 'Concluído' : 'Executar em segundo plano'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(OptimizationProgressItem item) {
    IconData icon;
    Color iconColor;
    String statusText;

    switch (item.status) {
      case 'pending':
        icon = Icons.schedule;
        iconColor = Colors.orange;
        statusText = 'Aguardando';
        break;
      case 'processing':
        icon = Icons.settings;
        iconColor = Theme.of(context).primaryColor;
        statusText = 'Processando';
        break;
      case 'completed':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        statusText = 'Completo';
        break;
      case 'error':
        icon = Icons.error;
        iconColor = Colors.red;
        statusText = 'Erro';
        break;
      default:
        icon = Icons.help;
        iconColor = Colors.grey;
        statusText = 'Desconhecido';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.2),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        'Item ${item.mediaItemId.substring(0, 8)}...',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            statusText,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: item.progress,
            backgroundColor: Colors.grey[600],
            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
          ),
        ],
      ),
      trailing: item.status == 'completed' && item.optimizedUrls != null
          ? Tooltip(
              message: 'Otimização: ${item.optimizedUrls!['format'] ?? 'N/A'}',
              child: Icon(Icons.info_outline, color: Colors.grey[400], size: 16),
            )
          : null,
    );
  }
}

/// Representa o progresso de otimização de um item individual
class OptimizationProgressItem {
  final String mediaItemId;
  final String status; // 'pending', 'processing', 'completed', 'error'
  final double progress; // 0.0 to 1.0
  final Map<String, dynamic>? optimizedUrls;

  const OptimizationProgressItem({
    required this.mediaItemId,
    required this.status,
    required this.progress,
    this.optimizedUrls,
  });

  OptimizationProgressItem copyWith({
    String? status,
    double? progress,
    Map<String, dynamic>? optimizedUrls,
  }) {
    return OptimizationProgressItem(
      mediaItemId: mediaItemId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      optimizedUrls: optimizedUrls ?? this.optimizedUrls,
    );
  }
}

/// Função utilitária para mostrar o dialog de progresso
Future<bool?> showOptimizationProgress({
  required BuildContext context,
  required List<String> mediaItemIds,
  String title = 'Otimizando mídia',
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => OptimizationProgressDialog(
      mediaItemIds: mediaItemIds,
      title: title,
    ),
  );
}