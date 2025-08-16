import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/services/media_service.dart';
import 'package:versee/services/language_service.dart';

/// Widget para gerenciar pastas/categorias de mídia
class MediaFolderManager extends StatefulWidget {
  final MediaContentType mediaType;
  final Function(List<MediaItem>)? onItemsFiltered;
  
  const MediaFolderManager({
    super.key,
    required this.mediaType,
    this.onItemsFiltered,
  });

  @override
  State<MediaFolderManager> createState() => _MediaFolderManagerState();
}

class _MediaFolderManagerState extends State<MediaFolderManager> {
  String? _selectedFolder;
  List<MediaFolder> _folders = [];
  bool _foldersInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeFolders();
  }
  
  void _initializeFolders() {
    // Criar pastas padrão baseadas no tipo de mídia usando método estático
    _folders.clear();
    _folders.addAll(MediaFolder.getAvailableFolders(widget.mediaType));
  }
  
  void _ensureAllFolderInitialized(BuildContext context) {
    if (!_foldersInitialized) {
      // Adicionar pasta "Todos" com cor do tema
      _folders.insert(0, MediaFolder(
        id: 'all',
        name: context.watch<LanguageService>().strings.all,
        icon: Icons.all_inclusive,
        color: Theme.of(context).colorScheme.primary,
      ));
      _foldersInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureAllFolderInitialized(context);
    
    return Consumer<MediaService>(
      builder: (context, mediaService, child) {
        return Container(
          height: 56, // Altura compacta fixa
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Apenas ícone compacto
              Icon(
                Icons.filter_list,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              
              // Chips horizontais compactos
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _folders.length,
                  itemBuilder: (context, index) {
                    final folder = _folders[index];
                    final isSelected = _selectedFolder == folder.id;
                    final itemCount = _getItemCountForFolder(folder.id, mediaService);
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onLongPress: folder.id != 'all' ? () => _showFolderOptions(folder) : null,
                        child: FilterChip(
                          label: Text(
                            '${folder.name} (${itemCount})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          avatar: Icon(
                            folder.icon,
                            size: 14,
                            color: isSelected 
                                ? folder.color 
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          selected: isSelected,
                          selectedColor: folder.color.withValues(alpha: 0.2),
                          checkmarkColor: folder.color,
                          onSelected: (selected) => _selectFolder(folder.id, mediaService),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Botão adicionar categoria
              IconButton(
                onPressed: _showCreateFolderDialog,
                icon: const Icon(Icons.add),
                iconSize: 18,
                tooltip: 'Nova Categoria',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        );
      },
    );
  }
  
  
  int _getItemCountForFolder(String folderId, MediaService mediaService) {
    final items = mediaService.getMediaItemsByType(widget.mediaType);
    
    if (folderId == 'all') {
      return items.length;
    }
    
    // Por ora, retorna contagem baseada em categoria fictícia
    // Em implementação real, seria baseado em metadata ou tags
    return items.where((item) => _getItemCategory(item) == folderId).length;
  }
  
  String _getItemCategory(MediaItem item) {
    // Usar categoria real se disponível, senão usar fallback baseado em palavras-chave
    if (item.category != null && item.category!.isNotEmpty) {
      return item.category!;
    }
    
    // Fallback para itens sem categoria definida - categorização baseada no título/descrição
    final title = item.title.toLowerCase();
    final description = item.description?.toLowerCase() ?? '';
    
    switch (widget.mediaType) {
      case MediaContentType.audio:
        if (title.contains('adoração') || title.contains('worship') || 
            description.contains('adoração')) return 'worship';
        if (title.contains('instrumental') || description.contains('instrumental')) return 'instrumental';
        if (title.contains('coral') || title.contains('choir') || 
            description.contains('coral')) return 'choir';
        return 'other_audio';
        
      case MediaContentType.video:
        if (title.contains('sermão') || title.contains('sermon') || 
            description.contains('sermão')) return 'sermons';
        if (title.contains('testemunho') || title.contains('testimony') || 
            description.contains('testemunho')) return 'testimonies';
        if (title.contains('evento') || title.contains('event') || 
            description.contains('evento')) return 'events';
        return 'other_video';
        
      case MediaContentType.image:
        if (title.contains('fundo') || title.contains('background') || 
            description.contains('fundo')) return 'backgrounds';
        if (title.contains('slide') || description.contains('slide')) return 'slides';
        if (title.contains('foto') || title.contains('photo') || 
            description.contains('foto')) return 'photos';
        return 'other_image';
    }
  }
  
  void _selectFolder(String folderId, MediaService mediaService) {
    setState(() {
      _selectedFolder = folderId == _selectedFolder ? null : folderId;
    });
    
    // Filtrar e retornar itens da pasta selecionada
    final allItems = mediaService.getMediaItemsByType(widget.mediaType);
    List<MediaItem> filteredItems;
    
    if (_selectedFolder == null || _selectedFolder == 'all') {
      filteredItems = allItems;
    } else {
      filteredItems = allItems.where((item) => _getItemCategory(item) == _selectedFolder).toList();
    }
    
    widget.onItemsFiltered?.call(filteredItems);
  }
  
  void _showCreateFolderDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(
        onCreateFolder: (folder) {
          setState(() {
            _folders.add(folder);
          });
        },
      ),
    );
  }
  
  void _showFolderOptions(MediaFolder folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FolderOptionsSheet(
        folder: folder,
        onEdit: () => _editFolder(folder),
        onDelete: () => _deleteFolder(folder),
      ),
    );
  }
  
  void _editFolder(MediaFolder folder) {
    showDialog(
      context: context,
      builder: (context) => EditFolderDialog(
        folder: folder,
        onEditFolder: (editedFolder) {
          setState(() {
            final index = _folders.indexWhere((f) => f.id == folder.id);
            if (index != -1) {
              _folders[index] = editedFolder;
            }
          });
        },
      ),
    );
  }
  
  void _deleteFolder(MediaFolder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text('Deseja excluir a categoria "${folder.name}"?\n\nOs arquivos não serão excluídos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _folders.removeWhere((f) => f.id == folder.id);
                if (_selectedFolder == folder.id) {
                  _selectedFolder = null;
                }
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// WIDGETS AUXILIARES

class FolderCard extends StatelessWidget {
  final MediaFolder folder;
  final int itemCount;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  
  const FolderCard({
    super.key,
    required this.folder,
    required this.itemCount,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? folder.color.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? folder.color
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              folder.icon,
              color: isSelected ? folder.color : Theme.of(context).colorScheme.onSurface,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              folder.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? folder.color : Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isSelected ? folder.color : Theme.of(context).colorScheme.primary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                itemCount.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected ? folder.color : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateFolderDialog extends StatefulWidget {
  final Function(MediaFolder) onCreateFolder;
  
  const CreateFolderDialog({super.key, required this.onCreateFolder});

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _nameController = TextEditingController();
  IconData _selectedIcon = Icons.folder;
  Color _selectedColor = Colors.blue;
  
  final List<IconData> _icons = [
    Icons.folder,
    Icons.music_note,
    Icons.video_library,
    Icons.image,
    Icons.star,
    Icons.favorite,
    Icons.church,
    Icons.event,
  ];
  
  final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.brown,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Categoria'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da categoria',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          
          Text('Ícone', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _icons.map((icon) {
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIcon == icon 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedIcon == icon 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Icon(icon, size: 24),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          Text('Cor', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((color) {
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color ? Colors.black : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: _selectedColor == color 
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              final folder = MediaFolder(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: _nameController.text.trim(),
                icon: _selectedIcon,
                color: _selectedColor,
              );
              widget.onCreateFolder(folder);
              Navigator.pop(context);
            }
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}

class EditFolderDialog extends StatefulWidget {
  final MediaFolder folder;
  final Function(MediaFolder) onEditFolder;
  
  const EditFolderDialog({super.key, required this.folder, required this.onEditFolder});

  @override
  State<EditFolderDialog> createState() => _EditFolderDialogState();
}

class _EditFolderDialogState extends State<EditFolderDialog> {
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late Color _selectedColor;
  
  final List<IconData> _icons = [
    Icons.folder,
    Icons.music_note,
    Icons.video_library,
    Icons.image,
    Icons.star,
    Icons.favorite,
    Icons.church,
    Icons.event,
  ];
  
  final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.brown,
    Colors.pink,
  ];
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder.name);
    _selectedIcon = widget.folder.icon;
    _selectedColor = widget.folder.color;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Categoria'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da categoria',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          Text('Ícone', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _icons.map((icon) {
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIcon == icon 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedIcon == icon 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Icon(icon, size: 24),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          Text('Cor', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((color) {
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color ? Colors.black : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: _selectedColor == color 
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              final updatedFolder = MediaFolder(
                id: widget.folder.id,
                name: _nameController.text.trim(),
                icon: _selectedIcon,
                color: _selectedColor,
              );
              widget.onEditFolder(updatedFolder);
              Navigator.pop(context);
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class FolderOptionsSheet extends StatelessWidget {
  final MediaFolder folder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const FolderOptionsSheet({
    super.key,
    required this.folder,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
            title: const Text('Editar'),
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Excluir'),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}

// MODELO DE DADOS

class MediaFolder {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  
  const MediaFolder({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
  
  /// Método estático para obter categorias disponíveis por tipo de mídia
  static List<MediaFolder> getAvailableFolders(MediaContentType mediaType) {
    final folders = <MediaFolder>[];
    
    switch (mediaType) {
      case MediaContentType.audio:
        folders.addAll([
          MediaFolder(
            id: 'worship',
            name: 'Adoração',
            icon: Icons.music_note,
            color: Colors.purple,
          ),
          MediaFolder(
            id: 'instrumental',
            name: 'Instrumental',
            icon: Icons.piano,
            color: Colors.blue,
          ),
          MediaFolder(
            id: 'choir',
            name: 'Coral',
            icon: Icons.groups,
            color: Colors.green,
          ),
          MediaFolder(
            id: 'other_audio',
            name: 'Outros',
            icon: Icons.folder,
            color: Colors.grey,
          ),
        ]);
        break;
        
      case MediaContentType.video:
        folders.addAll([
          MediaFolder(
            id: 'sermons',
            name: 'Sermões',
            icon: Icons.video_library,
            color: Colors.brown,
          ),
          MediaFolder(
            id: 'testimonies',
            name: 'Testemunhos',
            icon: Icons.person,
            color: Colors.orange,
          ),
          MediaFolder(
            id: 'events',
            name: 'Eventos',
            icon: Icons.event,
            color: Colors.red,
          ),
          MediaFolder(
            id: 'other_video',
            name: 'Outros',
            icon: Icons.folder,
            color: Colors.grey,
          ),
        ]);
        break;
        
      case MediaContentType.image:
        folders.addAll([
          MediaFolder(
            id: 'backgrounds',
            name: 'Fundos',
            icon: Icons.image,
            color: Colors.indigo,
          ),
          MediaFolder(
            id: 'slides',
            name: 'Slides',
            icon: Icons.slideshow,
            color: Colors.teal,
          ),
          MediaFolder(
            id: 'photos',
            name: 'Fotos',
            icon: Icons.photo,
            color: Colors.pink,
          ),
          MediaFolder(
            id: 'other_image',
            name: 'Outros',
            icon: Icons.folder,
            color: Colors.grey,
          ),
        ]);
        break;
    }
    
    return folders;
  }
}