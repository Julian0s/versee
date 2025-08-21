import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:versee/providers/riverpod_providers.dart';
import 'package:versee/models/note_models.dart';
import 'package:versee/services/notes_service.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/pages/note_editor_page_improved.dart';
import 'package:versee/utils/playlist_helpers.dart';
import 'dart:async';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 NotesPage initState');
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    debugPrint('🎬 NotesPage dispose');
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 NotesPage build');
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<LanguageService>().strings.notes),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.watch<LanguageService>().strings.lyrics),
            Tab(text: context.watch<LanguageService>().strings.notesOnly),
          ],
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NoteEditorPageImproved(
                        contentType: _tabController.index == 0 ? NotesContentType.lyrics : NotesContentType.notes,
                      ),
                    ),
                  ),
                  icon: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  tooltip: 'Adicionar ${_tabController.index == 0 ? 'Letra' : 'Nota'}',
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                NotesTabContent(contentType: NotesContentType.lyrics),
                NotesTabContent(contentType: NotesContentType.notes),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotesTabContent extends StatefulWidget {
  final NotesContentType contentType;

  const NotesTabContent({super.key, required this.contentType});

  @override
  State<NotesTabContent> createState() => _NotesTabContentState();
}

class _NotesTabContentState extends State<NotesTabContent> {
  List<NoteItem> _items = [];
  bool _isLoading = true;
  StreamSubscription<List<NoteItem>>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 NotesTabContent initState - tipo: ${widget.contentType}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🎬 PostFrameCallback - inicializando serviço');
      _initializeService();
    });
  }

  @override
  void dispose() {
    debugPrint('🎬 NotesTabContent dispose - tipo: ${widget.contentType}');
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeService() async {
    if (!mounted) {
      debugPrint('⚠️ Widget não está montado, cancelando inicialização');
      return;
    }
    
    try {
      debugPrint('🔧 Inicializando serviço para ${widget.contentType}...');
      final notesService = provider.Provider.of<NotesService>(context, listen: false);
      
      await notesService.initialize();
      
      if (mounted) {
        _setupStreamListeners(notesService);
        // Carrega dados iniciais se necessário
        await _loadInitialData(notesService);
      }
      
      debugPrint('✅ Serviço inicializado com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar serviço: $e');
      if (mounted) {
        setState(() {
          _items = [];
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadInitialData(NotesService notesService) async {
    try {
      final data = await notesService.getNotesByType(widget.contentType);
      if (mounted) {
        setState(() {
          _items = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados iniciais: $e');
    }
  }
  

  void _setupStreamListeners(NotesService notesService) {
    debugPrint('🔧 Configurando stream listeners para tipo: ${widget.contentType}');
    
    if (widget.contentType == NotesContentType.lyrics) {
      debugPrint('🎵 Escutando lyrics stream...');
      _streamSubscription = notesService.lyricsStream.listen((lyrics) {
        debugPrint('🎵 STREAM RECEBIDO - ${lyrics.length} lyrics');
        
        // LOG DETALHADO DAS LYRICS RECEBIDAS
        for (var lyric in lyrics) {
          debugPrint('🎵 Lyric recebida - ID: ${lyric.id}, Title: ${lyric.title}');
        }
        
        if (mounted) {
          debugPrint('🎵 Widget ainda montado, atualizando estado...');
          setState(() {
            _items = lyrics;
            _isLoading = false;
          });
          debugPrint('🎵 Estado atualizado - _items.length: ${_items.length}, _isLoading: $_isLoading');
        } else {
          debugPrint('⚠️ Widget não está mais montado, ignorando atualização');
        }
      }, onError: (error) {
        debugPrint('❌ Erro no stream de lyrics: $error');
        debugPrint('📍 Stack trace: ${StackTrace.current}');
        if (mounted) {
          setState(() {
            _items = [];
            _isLoading = false;
          });
        }
      });
    } else {
      debugPrint('📝 Escutando notes stream...');
      _streamSubscription = notesService.notesStream.listen((notes) {
        debugPrint('📝 STREAM RECEBIDO - ${notes.length} notes');
        
        // LOG DETALHADO DAS NOTES RECEBIDAS
        for (var note in notes) {
          debugPrint('📝 Note recebida - ID: ${note.id}, Title: ${note.title}');
        }
        
        if (mounted) {
          debugPrint('📝 Widget ainda montado, atualizando estado...');
          setState(() {
            _items = notes;
            _isLoading = false;
          });
          debugPrint('📝 Estado atualizado - _items.length: ${_items.length}, _isLoading: $_isLoading');
        } else {
          debugPrint('⚠️ Widget não está mais montado, ignorando atualização');
        }
      }, onError: (error) {
        debugPrint('❌ Erro no stream de notes: $error');
        debugPrint('📍 Stack trace: ${StackTrace.current}');
        if (mounted) {
          setState(() {
            _items = [];
            _isLoading = false;
          });
        }
      });
    }
    
    debugPrint('✅ Stream listeners configurados');
  }


  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 Build chamado - tipo: ${widget.contentType}, _isLoading: $_isLoading, _items.length: ${_items.length}');
    
    return _buildContentList(context);
  }

  String _getContentTypeName(LanguageService languageService) {
    switch (widget.contentType) {
      case NotesContentType.lyrics:
        return languageService.strings.lyrics;
      case NotesContentType.notes:
        return languageService.strings.notes;
    }
  }

  IconData _getContentIcon() {
    switch (widget.contentType) {
      case NotesContentType.lyrics:
        return Icons.music_note;
      case NotesContentType.notes:
        return Icons.note_alt;
    }
  }

  Widget _buildContentList(BuildContext context) {
    debugPrint('🎨 Buildando content list - _isLoading: $_isLoading, _items.length: ${_items.length}');
    
    if (_isLoading) {
      debugPrint('🔄 Mostrando loading...');
      return const Center(child: CircularProgressIndicator());
    }
    
    final items = _items;
    debugPrint('🎨 Items finais para exibir: ${items.length}');
    
    if (items.isEmpty) {
      debugPrint('🎨 Mostrando estado vazio...');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getContentIcon(),
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            provider.Consumer<LanguageService>(
              builder: (context, languageService, child) {
                final contentType = _getContentTypeName(languageService).toLowerCase();
                return Column(
                  children: [
                    Text(
                      widget.contentType == NotesContentType.lyrics 
                        ? languageService.strings.noLyricsFound
                        : languageService.strings.noNotesFound,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.contentType == NotesContentType.lyrics 
                        ? languageService.strings.createFirstNote.replaceAll('nota', 'letra')
                        : languageService.strings.createFirstNote,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
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

    debugPrint('🎨 Buildando ListView com ${items.length} items');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        debugPrint('🎨 Buildando item $index: ${item.title} (${item.id})');
        return NoteCard(
          note: item,
          icon: _getContentIcon(),
          onTap: () => _openItem(item),
          onEdit: () => _editItem(item),
          onDelete: () => _deleteItem(item),
          onAddToPlaylist: () => _addToPlaylist(item),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final languageService = provider.Provider.of<LanguageService>(context, listen: false);
    debugPrint('➕ Abrindo dialog para adicionar ${_getContentTypeName(languageService)}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorPageImproved(
          contentType: widget.contentType,
        ),
      ),
    );
  }

  void _openItem(NoteItem item) {
    debugPrint('👁️ Abrindo item: ${item.title} (${item.id})');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorPageImproved(
          existingNote: item,
          contentType: widget.contentType,
        ),
      ),
    );
  }

  void _editItem(NoteItem item) {
    debugPrint('✏️ Editando item: ${item.title} (${item.id})');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorPageImproved(
          existingNote: item,
          contentType: widget.contentType,
        ),
      ),
    );
  }

  void _addToPlaylist(NoteItem item) {
    debugPrint('📋 Adicionando à playlist: ${item.title} (${item.id})');
    PlaylistHelpers.addSingleNoteToPlaylist(
      context,
      item,
      onCompleted: () {
        debugPrint('✅ Item adicionado à playlist com sucesso');
      },
    );
  }

  void _deleteItem(NoteItem item) {
    debugPrint('🗑️ Solicitando exclusão de: ${item.title} (${item.id})');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return provider.Consumer<LanguageService>(
          builder: (context, languageService, child) {
            return AlertDialog(
              title: Text('${languageService.strings.delete} ${_getContentTypeName(languageService)}'),
              content: Text('Deseja excluir "${item.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(languageService.strings.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    debugPrint('🗑️ Confirmado - excluindo ${item.title} (${item.id})');
                    try {
                      final notesService = provider.Provider.of<NotesService>(context, listen: false);
                      await notesService.deleteNote(item.id, item.type);
                      debugPrint('✅ Item excluído com sucesso');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${_getContentTypeName(languageService)} "${item.title}" excluída'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('❌ Erro ao excluir: $e');
                  debugPrint('📍 Stack trace: ${StackTrace.current}');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao excluir: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
                  child: Text(
                    languageService.strings.delete,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class NoteCard extends StatelessWidget {
  final NoteItem note;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onAddToPlaylist;

  const NoteCard({
    super.key,
    required this.note,
    required this.icon,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Note Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.layers,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${note.slideCount} slides',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(note.createdDate),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'playlist':
                        if (onAddToPlaylist != null) {
                          onAddToPlaylist!();
                        }
                        break;
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    if (onAddToPlaylist != null)
                      PopupMenuItem<String>(
                        value: 'playlist',
                        child: Row(
                          children: [
                            Icon(Icons.playlist_add, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('Adicionar à Playlist'),
                          ],
                        ),
                      ),
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 8),
                          const Text('Excluir'),
                        ],
                      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}