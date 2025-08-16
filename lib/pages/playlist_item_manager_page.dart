import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/widgets/playlist_selection_dialog.dart';

class PlaylistItemManagerPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistItemManagerPage({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistItemManagerPage> createState() => _PlaylistItemManagerPageState();
}

class _PlaylistItemManagerPageState extends State<PlaylistItemManagerPage> {
  late List<PresentationItem> _items;
  int? _previewingItemIndex;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.playlist.items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('${context.watch<LanguageService>().strings.manage} "${widget.playlist.title}"'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: _showAddItemDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar item',
          ),
          if (_hasChanges())
            TextButton(
              onPressed: _saveChanges,
              child: Text(context.watch<LanguageService>().strings.save),
            ),
        ],
      ),
      body: _items.isEmpty 
        ? _buildEmptyState()
        : Column(
            children: [
              // Header com informações
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.playlist.icon,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.playlist.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                context.watch<LanguageService>().strings.itemsCountReorder(_items.length),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de itens com drag and drop
              Expanded(
                child: _previewingItemIndex != null
                  ? _buildPreviewMode()
                  : _buildEditMode(),
              ),
            ],
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_remove,
            size: 80,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            context.watch<LanguageService>().strings.emptyPlaylist,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.watch<LanguageService>().strings.addFirstContent,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.watch<LanguageService>().strings.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      onReorder: _reorderItems,
      buildDefaultDragHandles: false, // Remove handles padrão do lado direito
      itemBuilder: (context, index) {
        final item = _items[index];
        return PlaylistItemCard(
          key: ValueKey(item.id),
          item: item,
          index: index + 1,
          onRemove: () => _removeItem(index),
          onPreview: () => _previewItem(index),
        );
      },
    );
  }

  Widget _buildPreviewMode() {
    final item = _items[_previewingItemIndex!];
    final strings = context.read<LanguageService>().strings;
    
    return Column(
      children: [
        // Barra de controle de preview
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _previewingItemIndex = null),
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _previewingItemIndex! > 0 
                      ? () => setState(() => _previewingItemIndex = _previewingItemIndex! - 1)
                      : null,
                    icon: const Icon(Icons.skip_previous),
                    tooltip: strings.previous,
                  ),
                  Text(
                    '${_previewingItemIndex! + 1}/${_items.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  IconButton(
                    onPressed: _previewingItemIndex! < _items.length - 1
                      ? () => setState(() => _previewingItemIndex = _previewingItemIndex! + 1)
                      : null,
                    icon: const Icon(Icons.skip_next),
                    tooltip: strings.next,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Preview do conteúdo
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: _buildSlideContent(item),
          ),
        ),

        // Ações de preview
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _removeItem(_previewingItemIndex!),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: Text(strings.remove),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.read<LanguageService>().strings.presentItemMessage(item.title)),
                    ),
                  );
                },
                icon: const Icon(Icons.info),
                label: Text(strings.details),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlideContent(PresentationItem item) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
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
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      
      case ContentType.lyrics:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              item.content,
              style: textStyle,
              textAlign: TextAlign.center,
            ),
          ),
        );
      
      case ContentType.notes:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(
            item.content,
            style: textStyle.copyWith(height: 1.6),
          ),
        );
      
      case ContentType.image:
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                item.content,
                headers: const {
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                },
              ),
              fit: BoxFit.contain,
              onError: (error, stackTrace) {
                debugPrint('Erro ao carregar imagem do item da playlist: ${item.content} - $error');
              },
            ),
          ),
          child: item.content.isEmpty ? Center(
            child: Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ) : null,
        );
      
      case ContentType.video:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_filled,
                size: 40,
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
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note,
                size: 40,
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

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => PlaylistSelectionDialog(
        itemsToAdd: [],
        itemTypeLabel: 'conteúdo',
        onCompleted: () {
          // Recarregar itens da playlist após adicionar
          setState(() {
            _items = List.from(widget.playlist.items);
          });
        },
      ),
    );
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  void _removeItem(int index) {
    final strings = context.read<LanguageService>().strings;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.removeItem),
        content: Text(strings.removeItemFromPlaylist(_items[index].title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _items.removeAt(index);
                // Se estava previsualizando este item, sair do modo preview
                if (_previewingItemIndex == index) {
                  _previewingItemIndex = null;
                } else if (_previewingItemIndex != null && _previewingItemIndex! > index) {
                  _previewingItemIndex = _previewingItemIndex! - 1;
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(strings.remove)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(strings.remove, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _previewItem(int index) {
    setState(() {
      _previewingItemIndex = index;
    });
  }


  bool _hasChanges() {
    if (_items.length != widget.playlist.items.length) return true;
    
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].id != widget.playlist.items[i].id) return true;
    }
    
    return false;
  }

  void _saveChanges() async {
    final playlistService = Provider.of<PlaylistService>(context, listen: false);
    final strings = context.read<LanguageService>().strings;
    
    final updatedPlaylist = Playlist(
      id: widget.playlist.id,
      title: widget.playlist.title,
      icon: widget.playlist.icon,
      items: List.from(_items),
      lastModified: DateTime.now(),
    );
    
    final success = await playlistService.updatePlaylist(updatedPlaylist);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.success)),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class PlaylistItemCard extends StatelessWidget {
  final PresentationItem item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onPreview;

  const PlaylistItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPreview,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Handle para drag - único ícone do lado esquerdo
                ReorderableDragStartListener(
                  index: index - 1,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.drag_handle,
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Índice
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Ícone do tipo de conteúdo
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getContentTypeColor(item.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getContentTypeIcon(item.type),
                    color: _getContentTypeColor(item.type),
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Informações do item
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getContentTypeLabel(item.type, context),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getContentTypeColor(item.type),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (item.metadata?['reference'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.metadata!['reference'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Ações
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      tooltip: context.read<LanguageService>().strings.remove,
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

  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.bible: return Icons.menu_book;
      case ContentType.lyrics: return Icons.music_note;
      case ContentType.notes: return Icons.note;
      case ContentType.audio: return Icons.audiotrack;
      case ContentType.video: return Icons.videocam;
      case ContentType.image: return Icons.image;
    }
  }

  Color _getContentTypeColor(ContentType type) {
    switch (type) {
      case ContentType.bible: return Colors.blue;
      case ContentType.lyrics: return Colors.purple;
      case ContentType.notes: return Colors.orange;
      case ContentType.audio: return Colors.green;
      case ContentType.video: return Colors.red;
      case ContentType.image: return Colors.teal;
    }
  }

  String _getContentTypeLabel(ContentType type, BuildContext context) {
    final strings = context.read<LanguageService>().strings;
    switch (type) {
      case ContentType.bible: return strings.bibleVerse;
      case ContentType.lyrics: return strings.lyrics;  
      case ContentType.notes: return strings.noteSlashSermon;
      case ContentType.audio: return strings.audio;
      case ContentType.video: return strings.video;
      case ContentType.image: return strings.image;
    }
  }
}