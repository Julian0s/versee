import 'package:flutter/material.dart';
import 'package:versee/models/playlist_models.dart';
import 'package:versee/services/typed_firebase_service.dart';
import 'dart:async';

/// Instância global do PlaylistService para bridge híbrida com Riverpod
PlaylistService? _globalPlaylistService;

// Enum para tipos de conteúdo
enum ContentType { bible, lyrics, notes, audio, video, image }

// Classe PresentationItem
class PresentationItem {
  final String id;
  final String title;
  final ContentType type;
  final String content;
  final Map<String, dynamic>? metadata;

  PresentationItem({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    this.metadata,
  });
}

// Classe Playlist (mantida para compatibilidade)
class Playlist {
  final String id;
  final String title;
  final String? description;
  final IconData icon;
  final List<PresentationItem> items;
  final DateTime lastModified;

  Playlist({
    required this.id,
    required this.title,
    this.description,
    required this.icon,
    required this.items,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  int get itemCount => items.length;

  // Converter para PlaylistModel do Firebase
  PlaylistModel toFirebaseModel(String userId) {
    return PlaylistModel(
      id: id,
      userId: userId,
      title: title,
      description: description ?? '',
      iconCodePoint: icon.codePoint,
      items: items.map((item) => PlaylistItemModel(
        order: items.indexOf(item),
        type: _contentTypeToString(item.type),
        itemId: item.id,
        title: item.title,
        metadata: {
          'content': item.content,
          ...?item.metadata,
        },
      )).toList(),
      itemCount: items.length,
      createdAt: lastModified,
      updatedAt: lastModified,
    );
  }

  // Converter de PlaylistModel do Firebase
  static Playlist fromFirebaseModel(PlaylistModel model) {
    return Playlist(
      id: model.id,
      title: model.title,
      description: model.description.isNotEmpty ? model.description : null,
      icon: _getIconFromCodePoint(model.iconCodePoint),
      items: model.items.map((item) => PresentationItem(
        id: item.itemId,
        title: item.title,
        type: _stringToContentType(item.type),
        content: item.metadata?['content'] as String? ?? '',
        metadata: item.metadata,
      )).toList(),
      lastModified: model.updatedAt,
    );
  }

  // Helper para converter code point para IconData de forma tree-shake friendly
  static IconData _getIconFromCodePoint(int codePoint) {
    // Map dos ícones mais comuns para permitir tree-shaking
    switch (codePoint) {
      case 0xe8b6: return Icons.playlist_play; // playlist_play
      case 0xe037: return Icons.queue_music; // queue_music
      case 0xe8d6: return Icons.slideshow; // slideshow
      case 0xe8d2: return Icons.slideshow_outlined; // slideshow_outlined
      case 0xe4cb: return Icons.music_note; // music_note
      case 0xe40f: return Icons.library_music; // library_music
      case 0xe039: return Icons.video_library; // video_library
      case 0xe3a9: return Icons.image; // image
      case 0xe5c3: return Icons.photo_library; // photo_library
      case 0xe0b4: return Icons.folder; // folder
      case 0xe8fd: return Icons.star; // star
      case 0xe8d4: return Icons.favorite; // favorite  
      case 0xe7f7: return Icons.celebration; // celebration
      case 0xe80e: return Icons.church; // church / place_of_worship
      case 0xe8cc: return Icons.school; // school
      case 0xe7ee: return Icons.campaign; // campaign
      case 0xe157: return Icons.event; // event
      default:
        // Fallback para ícones não mapeados - usa um ícone padrão
        return Icons.playlist_play;
    }
  }

  static String _contentTypeToString(ContentType type) {
    switch (type) {
      case ContentType.bible: return 'bible';
      case ContentType.lyrics: return 'lyrics';
      case ContentType.notes: return 'notes';
      case ContentType.audio: return 'audio';
      case ContentType.video: return 'video';
      case ContentType.image: return 'image';
    }
  }

  static ContentType _stringToContentType(String type) {
    switch (type) {
      case 'bible': return ContentType.bible;
      case 'lyrics': return ContentType.lyrics;
      case 'notes': return ContentType.notes;
      case 'audio': return ContentType.audio;
      case 'video': return ContentType.video;
      case 'image': return ContentType.image;
      default: return ContentType.notes;
    }
  }
}

/// Serviço responsável por gerenciar playlists persistentes no Firebase
class PlaylistService extends ChangeNotifier {
  final TypedFirebaseService _firebaseService = TypedFirebaseService();
  final List<Playlist> _playlists = [];
  StreamSubscription<List<PlaylistModel>>? _playlistsSubscription;

  PlaylistService() {
    // Registrar esta instância globalmente para bridge híbrida
    _globalPlaylistService = this;
    _initializeFirebaseConnection();
  }

  @override
  void dispose() {
    _playlistsSubscription?.cancel();
    super.dispose();
  }

  List<Playlist> get playlists => List.unmodifiable(_playlists);

  /// Inicializa conexão com Firebase e sincroniza dados
  void _initializeFirebaseConnection() {
    if (_firebaseService.isAuthenticated) {
      _listenToPlaylistChanges();
    } else {
      // Escuta mudanças no estado de autenticação
      _firebaseService.authStateChanges.listen((user) {
        if (user != null) {
          _listenToPlaylistChanges();
        } else {
          _clearLocalPlaylists();
        }
      });
    }
  }

  /// Escuta mudanças nas playlists do Firebase
  void _listenToPlaylistChanges() {
    if (!_firebaseService.isAuthenticated) {
      debugPrint('⚠️ Usuário não autenticado - não carregando playlists');
      return;
    }
    
    _playlistsSubscription?.cancel();
    _playlistsSubscription = _firebaseService.getUserPlaylists().listen(
      (playlistModels) {
        try {
          debugPrint('🔄 Convertendo ${playlistModels.length} playlists do Firebase');
          _playlists.clear();
          
          for (final model in playlistModels) {
            try {
              final playlist = Playlist.fromFirebaseModel(model);
              _playlists.add(playlist);
            } catch (e) {
              debugPrint('❌ Erro ao converter playlist ${model.id}: $e');
            }
          }
          
          debugPrint('✅ ${_playlists.length} playlists carregadas com sucesso');
          notifyListeners();
        } catch (e) {
          debugPrint('❌ Erro geral ao processar playlists: $e');
        }
      },
      onError: (error) {
        debugPrint('❌ Erro ao carregar playlists: $error');
        if (error.toString().contains('permission-denied')) {
          debugPrint('🚫 Erro de permissão ao carregar playlists');
        }
      },
    );
  }

  /// Limpa playlists locais
  void _clearLocalPlaylists() {
    _playlists.clear();
    notifyListeners();
  }

  /// Adiciona uma nova playlist no Firebase
  Future<bool> addPlaylist(Playlist playlist) async {
    try {
      if (!_firebaseService.isAuthenticated) {
        debugPrint('❌ Usuário não autenticado');
        return false;
      }

      final playlistModel = playlist.toFirebaseModel(_firebaseService.currentUserId!);
      final playlistId = await _firebaseService.createPlaylist(playlistModel);
      
      if (playlistId != null) {
        debugPrint('✅ Playlist criada no Firebase: $playlistId');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao adicionar playlist: $e');
      return false;
    }
  }

  /// Remove uma playlist do Firebase
  Future<bool> removePlaylist(String playlistId) async {
    try {
      debugPrint('🔄 Iniciando remoção de playlist: $playlistId');
      debugPrint('🔐 Usuário autenticado: ${_firebaseService.isAuthenticated}');
      debugPrint('👤 ID do usuário: ${_firebaseService.currentUserId}');
      
      if (!_firebaseService.isAuthenticated) {
        debugPrint('❌ Usuário não autenticado para deletar playlist');
        return false;
      }

      // Verificar se a playlist pertence ao usuário atual
      final playlistToDelete = _playlists.firstWhere(
        (p) => p.id == playlistId,
        orElse: () => throw Exception('Playlist não encontrada localmente'),
      );
      
      debugPrint('📋 Tentando deletar playlist: "${playlistToDelete.title}"');
      
      final success = await _firebaseService.deletePlaylist(playlistId);
      if (success) {
        debugPrint('✅ Playlist removida do Firebase: $playlistId');
        // Remover da lista local também
        _playlists.removeWhere((p) => p.id == playlistId);
        notifyListeners();
      } else {
        debugPrint('❌ Falha ao remover playlist do Firebase: $playlistId');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Erro ao remover playlist: $e');
      if (e.toString().contains('permission-denied')) {
        debugPrint('🚫 Erro de permissão - verifique as regras do Firestore');
      }
      return false;
    }
  }

  /// Atualiza uma playlist existente no Firebase
  Future<bool> updatePlaylist(Playlist updatedPlaylist) async {
    try {
      if (!_firebaseService.isAuthenticated) {
        debugPrint('❌ Usuário não autenticado');
        return false;
      }

      final updates = {
        'title': updatedPlaylist.title,
        'description': updatedPlaylist.description ?? '',
        'iconCodePoint': updatedPlaylist.icon.codePoint,
        'items': updatedPlaylist.items.map((item) => {
          'order': updatedPlaylist.items.indexOf(item),
          'type': Playlist._contentTypeToString(item.type),
          'itemId': item.id,
          'title': item.title,
          'metadata': {
            'content': item.content,
            ...?item.metadata,
          },
        }).toList(),
        'itemCount': updatedPlaylist.items.length,
      };

      final success = await _firebaseService.updatePlaylist(updatedPlaylist.id, updates);
      if (success) {
        debugPrint('✅ Playlist atualizada no Firebase: ${updatedPlaylist.id}');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Erro ao atualizar playlist: $e');
      return false;
    }
  }

  /// Adiciona um item a uma playlist específica no Firebase
  Future<bool> addItemToPlaylist(String playlistId, PresentationItem item) async {
    try {
      final playlist = _playlists.firstWhere((p) => p.id == playlistId);
      final updatedItems = List<PresentationItem>.from(playlist.items)..add(item);
      
      final updatedPlaylist = Playlist(
        id: playlist.id,
        title: playlist.title,
        description: playlist.description,
        icon: playlist.icon,
        items: updatedItems,
        lastModified: DateTime.now(),
      );
      
      return await updatePlaylist(updatedPlaylist);
    } catch (e) {
      debugPrint('❌ Erro ao adicionar item à playlist: $e');
      return false;
    }
  }

  /// Adiciona múltiplos itens a uma playlist específica no Firebase
  Future<bool> addItemsToPlaylist(String playlistId, List<PresentationItem> items) async {
    try {
      final playlist = _playlists.firstWhere((p) => p.id == playlistId);
      final updatedItems = List<PresentationItem>.from(playlist.items)..addAll(items);
      
      final updatedPlaylist = Playlist(
        id: playlist.id,
        title: playlist.title,
        description: playlist.description,
        icon: playlist.icon,
        items: updatedItems,
        lastModified: DateTime.now(),
      );
      
      return await updatePlaylist(updatedPlaylist);
    } catch (e) {
      debugPrint('❌ Erro ao adicionar itens à playlist: $e');
      return false;
    }
  }

  /// Remove um item de uma playlist no Firebase
  Future<bool> removeItemFromPlaylist(String playlistId, String itemId) async {
    try {
      final playlist = _playlists.firstWhere((p) => p.id == playlistId);
      final updatedItems = playlist.items.where((item) => item.id != itemId).toList();
      
      final updatedPlaylist = Playlist(
        id: playlist.id,
        title: playlist.title,
        description: playlist.description,
        icon: playlist.icon,
        items: updatedItems,
        lastModified: DateTime.now(),
      );
      
      return await updatePlaylist(updatedPlaylist);
    } catch (e) {
      debugPrint('❌ Erro ao remover item da playlist: $e');
      return false;
    }
  }

  /// Encontra uma playlist pelo ID
  Playlist? findPlaylistById(String id) {
    try {
      return _playlists.firstWhere((playlist) => playlist.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Cria uma nova playlist e retorna seu ID do Firebase
  Future<String?> createPlaylist({
    required String title,
    String? description,
    required IconData icon,
    List<PresentationItem>? initialItems,
  }) async {
    try {
      if (!_firebaseService.isAuthenticated) {
        debugPrint('❌ Usuário não autenticado');
        return null;
      }

      final playlist = Playlist(
        id: '', // Será definido pelo Firebase
        title: title,
        description: description,
        icon: icon,
        items: initialItems ?? [],
      );
      
      final playlistModel = playlist.toFirebaseModel(_firebaseService.currentUserId!);
      final playlistId = await _firebaseService.createPlaylist(playlistModel);
      
      if (playlistId != null) {
        debugPrint('✅ Playlist criada com ID: $playlistId');
      }
      return playlistId;
    } catch (e) {
      debugPrint('❌ Erro ao criar playlist: $e');
      return null;
    }
  }

  /// Força recarregamento das playlists do Firebase
  Future<void> refreshPlaylists() async {
    if (_firebaseService.isAuthenticated) {
      _listenToPlaylistChanges();
    }
  }

  /// Reordena as playlists localmente (sem sincronizar com Firebase)
  void reorderPlaylists(List<Playlist> reorderedPlaylists) {
    try {
      _playlists.clear();
      _playlists.addAll(reorderedPlaylists);
      notifyListeners();
      debugPrint('✅ Playlists reordenadas localmente');
    } catch (e) {
      debugPrint('❌ Erro ao reordenar playlists: $e');
    }
  }

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => _firebaseService.isAuthenticated;

  /// Sincroniza com Riverpod - usado para bridge híbrida
  /// Este método é chamado quando o Riverpod muda o estado
  void syncWithRiverpod(List<dynamic> newPlaylists, bool initialized, bool loading, String? error) {
    debugPrint('🔄 [PROVIDER] Sincronizando com Riverpod (Playlist)');
    
    // Atualizar playlists com dados do Riverpod
    _playlists.clear();
    _playlists.addAll(newPlaylists.cast<Playlist>());
    
    // Notificar listeners para que todos os Provider.of<PlaylistService> reajam
    notifyListeners();
  }
  
  /// Função estática para acesso global à instância (bridge híbrida)
  static PlaylistService? get globalInstance => _globalPlaylistService;
}