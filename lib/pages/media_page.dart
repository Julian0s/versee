import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/services/media_service.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/utils/playlist_helpers.dart';
import 'package:versee/widgets/media_details_dialog.dart';
import 'package:versee/pages/media_viewer_page.dart';
import 'package:versee/widgets/media_folder_manager.dart';

class MediaPage extends StatefulWidget {
  const MediaPage({super.key});

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Auto-refresh from Firebase periodically to catch uploaded files
    _setupAutoRefresh();
  }

  void _setupAutoRefresh() {
    // Refresh every 30 seconds to catch any Firebase uploads
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        final mediaService = Provider.of<MediaService>(context, listen: false);
        mediaService.syncWithFirebase().catchError((e) {
          // Silent fail - don't disturb user experience
        });
        _setupAutoRefresh(); // Continue the cycle
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cleanupInvalidMedia(BuildContext context) async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final strings = languageService.strings;
    
    // Show confirmation dialog first
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.cleanupInvalidFiles),
        content: Text(strings.cleanupDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.continue_),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Verificando arquivos de mídia...'),
          ],
        ),
      ),
    );

    try {
      final mediaService = Provider.of<MediaService>(context, listen: false);
      final removedCount = await mediaService.validateAndCleanupInvalidItems();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
    }
  }

  Future<void> _syncWithFirebase(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Sincronizando com Firebase...'),
          ],
        ),
      ),
    );

    try {
      final mediaService = Provider.of<MediaService>(context, listen: false);
      await mediaService.forceSyncAll();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
    }
  }

  void _showAddMediaDialogForCurrentTab(BuildContext context) {
    final currentTab = _tabController.index;
    MediaContentType mediaType;
    
    switch (currentTab) {
      case 0:
        mediaType = MediaContentType.audio;
        break;
      case 1:
        mediaType = MediaContentType.video;
        break;
      case 2:
        mediaType = MediaContentType.image;
        break;
      default:
        mediaType = MediaContentType.audio;
    }
    
    // Find the current tab's state to call its method
    // Since this is a simplified approach, we'll navigate to a generic media import
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar ${_getMediaTypeName(mediaType)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Selecionar Arquivos'),
                subtitle: Text('Importar ${_getMediaTypeName(mediaType).toLowerCase()} do dispositivo'),
                onTap: () {
                  Navigator.of(context).pop();
                  // This would need to be implemented or delegated to the tab content
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
  
  String _getMediaTypeName(MediaContentType mediaType) {
    switch (mediaType) {
      case MediaContentType.audio:
        return 'Áudio';
      case MediaContentType.video:
        return 'Vídeo';
      case MediaContentType.image:
        return 'Imagem';
    }
  }

  String _getMediaTypeNameFromIndex(int index) {
    switch (index) {
      case 0:
        return 'Áudio';
      case 1:
        return 'Vídeo';
      case 2:
        return 'Imagem';
      default:
        return 'Mídia';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final strings = languageService.strings;
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.media),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: strings.audio),
                Tab(text: strings.videos),
                Tab(text: strings.images),
              ],
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          body: Column(
            children: [
              // Header com botão de adicionar (como na página presenter)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _showAddMediaDialogForCurrentTab(context),
                      icon: Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      tooltip: 'Adicionar ${_getMediaTypeNameFromIndex(_tabController.index)}',
                    ),
                  ],
                ),
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    MediaTabContent(mediaType: MediaContentType.audio),
                    MediaTabContent(mediaType: MediaContentType.video),
                    MediaTabContent(mediaType: MediaContentType.image),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MediaTabContent extends StatefulWidget {
  final MediaContentType mediaType;

  const MediaTabContent({super.key, required this.mediaType});

  @override
  State<MediaTabContent> createState() => _MediaTabContentState();
}

class _MediaTabContentState extends State<MediaTabContent> {
  bool _isUploading = false;
  List<MediaItem> _filteredItems = [];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Folder Manager
            MediaFolderManager(
              mediaType: widget.mediaType,
              onItemsFiltered: (items) {
                setState(() {
                  _filteredItems = items;
                });
              },
            ),

            // Media list
            Expanded(
              child: _buildMediaList(context),
            ),
          ],
        ),
        // Upload dialog overlay
        if (_isUploading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        return Text(
                          languageService.strings.importingFiles,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getMediaTypeName() {
    final strings = Provider.of<LanguageService>(context, listen: false).strings;
    switch (widget.mediaType) {
      case MediaContentType.audio:
        return strings.audio;
      case MediaContentType.video:
        return strings.videoFiles;
      case MediaContentType.image:
        return strings.imageFiles;
    }
  }

  String _getAddButtonText() {
    final strings = Provider.of<LanguageService>(context, listen: false).strings;
    switch (widget.mediaType) {
      case MediaContentType.audio:
        return strings.addAudio;
      case MediaContentType.video:
        return strings.addVideo;
      case MediaContentType.image:
        return strings.addImage;
    }
  }

  static String getLocalizedDescription(MediaItem mediaItem, LanguageService languageService) {
    if (mediaItem.description == null || mediaItem.description!.isEmpty) {
      return '';
    }
    
    final strings = languageService.strings;
    final dateString = _formatDate(mediaItem.createdDate);
    
    // Check if it's an import description
    if (mediaItem.description!.contains('importado em') || 
        mediaItem.description!.contains('importada em')) {
      
      if (mediaItem is AudioItem) {
        return '${strings.audioImportedOn} $dateString';
      } else if (mediaItem is VideoItem) {
        return '${strings.videoImportedOn} $dateString';
      } else if (mediaItem is ImageItem) {
        return '${strings.imageImportedOn} $dateString';
      }
    }
    
    return mediaItem.description!;
  }
  
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String getEditMenuText(MediaItem mediaItem, LanguageService languageService) {
    final strings = languageService.strings;
    if (mediaItem is AudioItem) {
      return strings.editAudio;
    } else if (mediaItem is VideoItem) {
      return strings.editVideo;
    } else if (mediaItem is ImageItem) {
      return strings.editImage;
    }
    return strings.edit;
  }

  static String getPlayTooltip(MediaItem mediaItem, LanguageService languageService) {
    final strings = languageService.strings;
    switch (mediaItem.type) {
      case MediaContentType.audio:
        return strings.playAudio;
      case MediaContentType.video:
        return strings.playVideo;
      case MediaContentType.image:
        return strings.viewImage;
    }
  }

  IconData _getMediaIcon() {
    switch (widget.mediaType) {
      case MediaContentType.audio:
        return Icons.music_note;
      case MediaContentType.video:
        return Icons.play_circle_outline;
      case MediaContentType.image:
        return Icons.image;
    }
  }

  Widget _buildMediaList(BuildContext context) {
    return Consumer<MediaService>(
      builder: (context, mediaService, child) {
        // Usar itens filtrados se disponível, senão usar todos os itens
        final allItems = mediaService.getMediaItemsByType(widget.mediaType);
        final items = _filteredItems.isNotEmpty ? _filteredItems : allItems;

        // Verificar se o serviço ainda está inicializando
        if (!mediaService.isInitialized) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Carregando mídia...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          );
        }

        // Agora, se inicializado e vazio, mostrar empty state
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getMediaIcon(),
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Consumer<LanguageService>(
                  builder: (context, languageService, child) {
                    String emptyMessage;
                    String addMessage;
                    switch (widget.mediaType) {
                      case MediaContentType.audio:
                        emptyMessage = languageService.strings.noAudioFound;
                        addMessage = languageService.strings.addFirstMedia.replaceAll('mídia', 'áudio');
                        break;
                      case MediaContentType.video:
                        emptyMessage = languageService.strings.noVideoFound;
                        addMessage = languageService.strings.addFirstMedia.replaceAll('mídia', 'vídeo');
                        break;
                      case MediaContentType.image:
                        emptyMessage = languageService.strings.noImagesFound;
                        addMessage = languageService.strings.addFirstMedia.replaceAll('mídia', 'imagem');
                        break;
                    }
                    return Column(
                      children: [
                        Text(
                          emptyMessage,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          addMessage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4),
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }

        return Scrollbar(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return MediaListItem(
                mediaItem: item,
                onTap: () => MediaViewerNavigation.openPlaylist(
                  context,
                  items,
                  index,
                  playlistTitle: '${_getMediaTypeName()} - Biblioteca',
                ),
                onAddToPlaylist: () => _addToPlaylist(context, item),
                onShowDetails: () => _showMediaDetails(context, item),
                onDeleteItem: () => _deleteMediaItem(context, item),
                onEditTitle: () => _editMediaTitle(context, item),
                onAddToCategory: () => _addToCategory(context, item),
              );
            },
          ),
        );
      },
    );
  }

  void _showAddMediaDialog(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final strings = languageService.strings;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar ${_getMediaTypeName()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: Text(strings.selectFiles),
                subtitle: Text(
                    'Importar ${_getMediaTypeName().toLowerCase()} do dispositivo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _importFiles(context, widget.mediaType);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importFiles(
      BuildContext context, MediaContentType mediaType) async {
    final mediaService = Provider.of<MediaService>(context, listen: false);

    setState(() {
      _isUploading = true;
    });

    try {
      debugPrint('Iniciando importação de ${mediaType.name}...');
      List<MediaItem> importedItems = [];

      switch (mediaType) {
        case MediaContentType.audio:
          importedItems = await mediaService.importAudioFiles().timeout(
                const Duration(minutes: 3),
                onTimeout: () => throw Exception(
                  'O processamento dos arquivos de áudio demorou mais que o esperado',
                ),
              );
          break;
        case MediaContentType.video:
          importedItems = await mediaService.importVideoFiles().timeout(
                const Duration(minutes: 5),
                onTimeout: () => throw Exception(
                  'O processamento dos arquivos de vídeo demorou mais que o esperado',
                ),
              );
          break;
        case MediaContentType.image:
          importedItems = await mediaService.importImageFiles().timeout(
                const Duration(minutes: 2),
                onTimeout: () => throw Exception(
                  'O processamento das imagens demorou mais que o esperado',
                ),
              );
          break;
      }

      debugPrint('Importação concluída: ${importedItems.length} itens');

      // Force refresh to show new items
      await mediaService.refreshFromFirebase();

      // Small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && importedItems.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${importedItems.length} ${mediaType.name} importado(s) com sucesso'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Erro na importação: $e');

      String errorMessage = 'Erro ao processar arquivos';
      String errorDetails = e.toString().replaceAll('Exception: ', '');

      if (errorDetails.contains('Timeout') ||
          errorDetails.contains('esperado')) {
        errorMessage = 'Processamento interrompido';
        errorDetails =
            'Tente novamente com arquivos menores ou uma conexão melhor';
      } else if (errorDetails.contains('No files selected') ||
          errorDetails.contains('Nenhum arquivo')) {
        final languageService = Provider.of<LanguageService>(context, listen: false);
        errorMessage = languageService.strings.noFileSelected;
        errorDetails = 'Selecione os arquivos que deseja importar';
      } else if (errorDetails.contains('não autenticado')) {
        errorMessage = 'Erro de autenticação';
        errorDetails = 'Faça login novamente para importar arquivos';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(errorDetails, style: const TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showMediaDetails(BuildContext context, MediaItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) => MediaDetailsDialog(mediaItem: item),
    );
  }

  void _addToPlaylist(BuildContext context, MediaItem item) {
    PlaylistHelpers.addSingleMediaToPlaylist(
      context,
      item,
      onCompleted: () {
        // Callback opcional quando concluído
      },
    );
  }

  Future<void> _deleteMediaItem(BuildContext context, MediaItem item) async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final strings = languageService.strings;
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteMedia),
        content: Text(
          '${strings.confirmDelete} "${item.title}"?\n\n'
          '${strings.actionCannotBeUndone}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Excluindo mídia...'),
              ],
            ),
          ),
        );

        final mediaService = Provider.of<MediaService>(context, listen: false);
        final success = await mediaService.deleteMediaItem(item.id);

        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          if (success) {
          } else {}
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }
      }
    }
  }

  Future<void> _editMediaTitle(BuildContext context, MediaItem item) async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final strings = languageService.strings;
    final titleController = TextEditingController(text: item.title);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.editTitle),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Título',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty && title != item.title) {
                Navigator.of(context).pop(title);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text(strings.save),
          ),
        ],
      ),
    );

    if (newTitle != null) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Salvando alterações...'),
              ],
            ),
          ),
        );

        final mediaService = Provider.of<MediaService>(context, listen: false);
        final success =
            await mediaService.updateMediaItemTitle(item.id, newTitle);

        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          if (success) {
          } else {}
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }
      }
    }

    titleController.dispose();
  }

  Future<void> _addToCategory(BuildContext context, MediaItem item) async {
    // Obter categorias disponíveis baseadas no tipo de mídia
    final folders = _getAvailableFolders(widget.mediaType);
    
    final selectedCategoryId = await showDialog<String>(
      context: context,
      builder: (context) => CategorySelectionDialog(
        currentCategory: item.category,
        availableFolders: folders,
        mediaType: widget.mediaType,
      ),
    );

    if (selectedCategoryId != null) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Atualizando categoria...'),
              ],
            ),
          ),
        );

        final mediaService = Provider.of<MediaService>(context, listen: false);
        final success = await mediaService.updateMediaItemCategory(item.id, selectedCategoryId);

        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          if (success) {
            final languageService = Provider.of<LanguageService>(context, listen: false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(languageService.strings.categoryUpdatedSuccess),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            final languageService = Provider.of<LanguageService>(context, listen: false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(languageService.strings.errorUpdatingCategory),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  List<MediaFolder> _getAvailableFolders(MediaContentType mediaType) {
    // Usa o método estático do MediaFolder para evitar duplicação
    return MediaFolder.getAvailableFolders(mediaType);
  }
}

class MediaListItem extends StatelessWidget {
  final MediaItem mediaItem;
  final VoidCallback onTap;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onShowDetails;
  final VoidCallback? onDeleteItem;
  final VoidCallback? onEditTitle;
  final VoidCallback? onAddToCategory;

  const MediaListItem({
    super.key,
    required this.mediaItem,
    required this.onTap,
    this.onAddToPlaylist,
    this.onShowDetails,
    this.onDeleteItem,
    this.onEditTitle,
    this.onAddToCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: _buildThumbnailOrIcon(context),
        title: Text(
          mediaItem.displayTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mediaItem.displaySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            if (mediaItem.description != null &&
                mediaItem.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Consumer<LanguageService>(
                builder: (context, languageService, child) {
                  return Text(
                    _MediaTabContentState.getLocalizedDescription(mediaItem, languageService),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play/View button
            Consumer<LanguageService>(
              builder: (context, languageService, child) {
                return IconButton(
                  icon: Icon(
                    _getPlayIcon(),
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  tooltip: _MediaTabContentState.getPlayTooltip(mediaItem, languageService),
                  onPressed: onTap,
                );
              },
            ),
            // Menu button
            Consumer<LanguageService>(
              builder: (context, languageService, child) {
                final strings = languageService.strings;
                return PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'playlist':
                        if (onAddToPlaylist != null) {
                          onAddToPlaylist!();
                        }
                        break;
                      case 'details':
                        if (onShowDetails != null) {
                          onShowDetails!();
                        }
                        break;
                      case 'edit':
                        if (onEditTitle != null) {
                          onEditTitle!();
                        }
                        break;
                      case 'category':
                        if (onAddToCategory != null) {
                          onAddToCategory!();
                        }
                        break;
                      case 'delete':
                        if (onDeleteItem != null) {
                          onDeleteItem!();
                        }
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(strings.details),
                        ],
                      ),
                    ),
                    if (onEditTitle != null)
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(_MediaTabContentState.getEditMenuText(mediaItem, languageService)),
                          ],
                        ),
                      ),
                    if (onAddToCategory != null)
                      PopupMenuItem<String>(
                        value: 'category',
                        child: Row(
                          children: [
                            Icon(Icons.folder,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(strings.addToCategory),
                          ],
                        ),
                      ),
                    if (onAddToPlaylist != null)
                      PopupMenuItem<String>(
                        value: 'playlist',
                        child: Row(
                          children: [
                            Icon(Icons.playlist_add,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(strings.addToPlaylistMenu),
                          ],
                        ),
                      ),
                    if (onDeleteItem != null)
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(strings.delete, style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        isThreeLine:
            mediaItem.description != null && mediaItem.description!.isNotEmpty,
      ),
    );
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

    // If thumbnail exists, show thumbnail
    if (thumbnailPath != null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: _buildThumbnailImage(thumbnailPath, context),
        ),
      );
    }

    // Fallback to default icon
    return _buildDefaultIcon(context);
  }

  Widget _buildThumbnailImage(String path, BuildContext context) {
    // Handle web URLs (blob: or data: URLs) vs file paths
    if (kIsWeb ||
        path.startsWith('blob:') ||
        path.startsWith('data:') ||
        path.startsWith('http')) {
      return Image.network(
        path,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Erro ao carregar thumbnail: $path - $error');
          return _buildDefaultIcon(context);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 48,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        },
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );
    } else {
      // Local file path
      try {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultIcon(context);
            },
          );
        }
      } catch (e) {
        // File doesn't exist or error reading it
      }
      return _buildDefaultIcon(context);
    }
  }

  Widget _buildDefaultIcon(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        mediaItem.displayIcon,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  IconData _getPlayIcon() {
    switch (mediaItem.type) {
      case MediaContentType.audio:
        return Icons.play_arrow;
      case MediaContentType.video:
        return Icons.play_circle_outline;
      case MediaContentType.image:
        return Icons.visibility;
    }
  }

}

class CategorySelectionDialog extends StatefulWidget {
  final String? currentCategory;
  final List<MediaFolder> availableFolders;
  final MediaContentType mediaType;

  const CategorySelectionDialog({
    super.key,
    this.currentCategory,
    required this.availableFolders,
    required this.mediaType,
  });

  @override
  State<CategorySelectionDialog> createState() => _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<CategorySelectionDialog> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return AlertDialog(
          title: Text(languageService.strings.selectCategory),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Opção "Remover Categoria"
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(null), // null = remover categoria
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Remover Categoria'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
          
          const Divider(),
          const SizedBox(height: 8),
          
          // Lista de categorias disponíveis
          ...widget.availableFolders.map((folder) {
            final isSelected = _selectedCategory == folder.id;
            
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 4),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(folder.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected 
                      ? folder.color.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.surface,
                  foregroundColor: isSelected 
                      ? folder.color 
                      : Theme.of(context).colorScheme.onSurface,
                  elevation: isSelected ? 2 : 0,
                  side: BorderSide(
                    color: isSelected 
                        ? folder.color 
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      folder.icon,
                      size: 20,
                      color: isSelected ? folder.color : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        folder.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 18,
                        color: folder.color,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}
