import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/services/playlist_service.dart';

/// Diálogo para seleção de playlist existente ou criação de nova playlist
class PlaylistSelectionDialog extends StatefulWidget {
  final List<PresentationItem> itemsToAdd;
  final String itemTypeLabel; // Ex: "versículo", "nota", "mídia", etc.
  final VoidCallback? onCompleted;

  const PlaylistSelectionDialog({
    super.key,
    required this.itemsToAdd,
    required this.itemTypeLabel,
    this.onCompleted,
  });

  @override
  State<PlaylistSelectionDialog> createState() => _PlaylistSelectionDialogState();
}

class _PlaylistSelectionDialogState extends State<PlaylistSelectionDialog> {
  final TextEditingController _newPlaylistController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final PageController _pageController = PageController();
  
  IconData _selectedIcon = Icons.queue_music;
  int _currentPage = 0;

  // Opções de ícones para novas playlists
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
    Icons.people,
    Icons.lightbulb,
  ];

  @override
  void dispose() {
    _newPlaylistController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Adicionar ${widget.itemTypeLabel}'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_currentPage == 1)
              TextButton(
                onPressed: _canCreatePlaylist() ? _createNewPlaylist : null,
                child: Text(context.read<LanguageService>().strings.create),
              ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (page) => setState(() => _currentPage = page),
          children: [
            _buildPlaylistSelectionPage(),
            _buildNewPlaylistCreationPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistSelectionPage() {
    return Consumer<PlaylistService>(
      builder: (context, playlistService, child) {
        final playlists = playlistService.playlists;
        
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com informações dos itens
              _buildItemsInfoCard(),
              
              const SizedBox(height: 24),
              
              // Opção para criar nova playlist
              _buildCreateNewPlaylistCard(),
              
              const SizedBox(height: 24),
              
              // Lista de playlists existentes
              Text(
                'Ou adicionar a uma playlist existente:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Expanded(
                child: playlists.isEmpty
                    ? _buildEmptyPlaylistsState()
                    : ListView.builder(
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          return _buildPlaylistCard(playlist, playlistService);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewPlaylistCreationPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.watch<LanguageService>().strings.newPlaylist,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            context.read<LanguageService>().strings.createNewPlaylistWithItemsMessage(widget.itemsToAdd.length, widget.itemTypeLabel),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Campo do nome da playlist
          TextField(
            controller: _newPlaylistController,
            decoration: InputDecoration(
              labelText: context.read<LanguageService>().strings.playlistName,
              hintText: context.read<LanguageService>().strings.playlistNameHint,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => setState(() {}),
          ),
          
          const SizedBox(height: 16),
          
          // Campo de descrição
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: context.read<LanguageService>().strings.playlistDescription,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          
          const SizedBox(height: 24),
          
          // Seleção de ícone
          Text(
            context.read<LanguageService>().strings.chooseIcon,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableIcons.map((icon) {
              final isSelected = icon == _selectedIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      width: 2,
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
          
          const Spacer(),
          
          // Preview dos itens que serão adicionados
          _buildItemsPreview(),
        ],
      ),
    );
  }

  Widget _buildItemsInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getItemTypeIcon(),
              color: Colors.white,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adicionando ${widget.itemsToAdd.length} ${widget.itemTypeLabel}${widget.itemsToAdd.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.itemsToAdd.map((item) => item.title).join(', '),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateNewPlaylistCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.read<LanguageService>().strings.createNewPlaylist,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Organize seus conteúdos em uma nova playlist personalizada',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(Playlist playlist, PlaylistService playlistService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addToExistingPlaylist(playlist, playlistService),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    playlist.icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist.itemCount} itens',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaylistsState() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.playlist_add,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                languageService.strings.noPlaylistsFound,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                languageService.strings.createFirstPlaylist,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Itens que serão adicionados:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: widget.itemsToAdd.length,
              itemBuilder: (context, index) {
                final item = widget.itemsToAdd[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        _getContentTypeIcon(item.type),
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getItemTypeIcon() {
    if (widget.itemsToAdd.isEmpty) return Icons.help_outline;
    
    final firstItemType = widget.itemsToAdd.first.type;
    return _getContentTypeIcon(firstItemType);
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

  bool _canCreatePlaylist() {
    return _newPlaylistController.text.trim().isNotEmpty;
  }

  void _addToExistingPlaylist(Playlist playlist, PlaylistService playlistService) async {
    // Adiciona os itens à playlist existente
    final success = await playlistService.addItemsToPlaylist(playlist.id, widget.itemsToAdd);
    
    if (success) {
      // Mostra feedback de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.itemsToAdd.length} ${widget.itemTypeLabel}${widget.itemsToAdd.length > 1 ? 's' : ''} '
            'adicionado${widget.itemsToAdd.length > 1 ? 's' : ''} à playlist "${playlist.title}"',
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      // Chama callback se fornecido
      widget.onCompleted?.call();
      
      // Fecha o diálogo
      Navigator.pop(context);
    } else {
      // Mostra erro
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao adicionar itens à playlist. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _createNewPlaylist() async {
    if (!_canCreatePlaylist()) return;
    
    final playlistService = Provider.of<PlaylistService>(context, listen: false);
    
    // Cria a nova playlist
    final playlistId = await playlistService.createPlaylist(
      title: _newPlaylistController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      icon: _selectedIcon,
      initialItems: widget.itemsToAdd,
    );
    
    if (playlistId != null) {
      // Mostra feedback de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Playlist "${_newPlaylistController.text.trim()}" criada com '
            '${widget.itemsToAdd.length} ${widget.itemTypeLabel}${widget.itemsToAdd.length > 1 ? 's' : ''}!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      // Chama callback se fornecido
      widget.onCompleted?.call();
      
      // Fecha o diálogo
      Navigator.pop(context);
    } else {
      // Mostra erro
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao criar playlist. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Método estático para facilitar o uso em outras partes do app
  static void show(
    BuildContext context, {
    required List<PresentationItem> items,
    required String itemTypeLabel,
    VoidCallback? onCompleted,
  }) {
    showDialog(
      context: context,
      builder: (context) => PlaylistSelectionDialog(
        itemsToAdd: items,
        itemTypeLabel: itemTypeLabel,
        onCompleted: onCompleted,
      ),
    );
  }
}