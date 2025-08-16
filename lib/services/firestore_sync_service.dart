import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:versee/firestore/firestore_data_schema.dart';
import 'package:versee/services/auth_service.dart';

/// Serviço de sincronização com Firestore
/// Gerencia operações CRUD para todas as coleções do VERSEE
class FirestoreSyncService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  FirestoreSyncService(this._authService);

  String? get _currentUserId => _authService.user?.uid;

  // Métodos para Playlists

  /// Criar nova playlist
  Future<String?> createPlaylist({
    required String title,
    required String description,
    List<Map<String, dynamic>>? items,
  }) async {
    if (_currentUserId == null) return null;

    try {
      _setLoading(true);
      _clearError();

      final playlistData = FirestoreDataSchema.playlistDocument(
        userId: _currentUserId!,
        title: title,
        description: description,
        items: items ?? [],
      );

      final docRef = await _firestore
          .collection(FirestoreDataSchema.playlistsCollection)
          .add(FirestoreConverter.prepareForFirestore(playlistData));

      return docRef.id;
    } catch (e) {
      _setError('Erro ao criar playlist: \${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Obter playlists do usuário
  Stream<List<Map<String, dynamic>>> getUserPlaylists() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestoreDataSchema.playlistsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = FirestoreConverter.parseFromFirestore(doc.data());
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Atualizar playlist
  Future<bool> updatePlaylist(String playlistId, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _clearError();

      updates['updatedAt'] = DateTime.now();

      await _firestore
          .collection(FirestoreDataSchema.playlistsCollection)
          .doc(playlistId)
          .update(FirestoreConverter.prepareForFirestore(updates));

      return true;
    } catch (e) {
      _setError('Erro ao atualizar playlist: \${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Excluir playlist
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore
          .collection(FirestoreDataSchema.playlistsCollection)
          .doc(playlistId)
          .delete();

      return true;
    } catch (e) {
      _setError('Erro ao excluir playlist: \${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos para Notes

  /// Criar nova nota
  Future<String?> createNote({
    required String title,
    required String type,
    List<Map<String, dynamic>>? slides,
  }) async {
    if (_currentUserId == null) return null;

    try {
      _setLoading(true);
      _clearError();

      final noteData = FirestoreDataSchema.noteDocument(
        userId: _currentUserId!,
        title: title,
        slides: slides ?? [],
      );

      final docRef = await _firestore
          .collection(FirestoreDataSchema.notesCollection)
          .add(FirestoreConverter.prepareForFirestore(noteData));

      return docRef.id;
    } catch (e) {
      _setError('Erro ao criar nota: \${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Obter notas do usuário
  Stream<List<Map<String, dynamic>>> getUserNotes({String? type}) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection(FirestoreDataSchema.notesCollection)
        .where('userId', isEqualTo: _currentUserId);

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>);
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Atualizar nota
  Future<bool> updateNote(String noteId, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _clearError();

      updates['updatedAt'] = DateTime.now();

      await _firestore
          .collection(FirestoreDataSchema.notesCollection)
          .doc(noteId)
          .update(FirestoreConverter.prepareForFirestore(updates));

      return true;
    } catch (e) {
      _setError('Erro ao atualizar nota: \${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Excluir nota
  Future<bool> deleteNote(String noteId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore
          .collection(FirestoreDataSchema.notesCollection)
          .doc(noteId)
          .delete();

      return true;
    } catch (e) {
      _setError('Erro ao excluir nota: \${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos para Media

  /// Criar registro de mídia
  Future<String?> createMedia({
    required String type,
    required String name,
    required String fileName,
    required String storagePath,
    required int fileSize,
    String? duration,
    String? thumbnailPath,
  }) async {
    if (_currentUserId == null) return null;

    try {
      _setLoading(true);
      _clearError();

      final mediaData = FirestoreDataSchema.mediaDocument(
        userId: _currentUserId!,
        type: type,
        name: name,
        fileName: fileName,
        storagePath: storagePath,
        fileSize: fileSize,
        duration: duration,
        thumbnailPath: thumbnailPath,
      );

      final docRef = await _firestore
          .collection(FirestoreDataSchema.mediaCollection)
          .add(FirestoreConverter.prepareForFirestore(mediaData));

      return docRef.id;
    } catch (e) {
      _setError('Erro ao criar registro de mídia: \${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Obter mídia do usuário
  Stream<List<Map<String, dynamic>>> getUserMedia({String? type}) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection(FirestoreDataSchema.mediaCollection)
        .where('userId', isEqualTo: _currentUserId);

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>);
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Excluir mídia
  Future<bool> deleteMedia(String mediaId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore
          .collection(FirestoreDataSchema.mediaCollection)
          .doc(mediaId)
          .delete();

      return true;
    } catch (e) {
      _setError('Erro ao excluir mídia: \${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos para Verse Collections

  /// Criar coleção de versículos
  Future<String?> createVerseCollection({
    required String title,
    required List<Map<String, dynamic>> verses,
  }) async {
    if (_currentUserId == null) return null;

    try {
      _setLoading(true);
      _clearError();

      final verseCollectionData = FirestoreDataSchema.verseCollectionDocument(
        userId: _currentUserId!,
        title: title,
        verses: verses,
      );

      final docRef = await _firestore
          .collection(FirestoreDataSchema.verseCollectionsCollection)
          .add(FirestoreConverter.prepareForFirestore(verseCollectionData));

      return docRef.id;
    } catch (e) {
      _setError('Erro ao criar coleção de versículos: \${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Obter coleções de versículos do usuário
  Stream<List<Map<String, dynamic>>> getUserVerseCollections() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestoreDataSchema.verseCollectionsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = FirestoreConverter.parseFromFirestore(doc.data());
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Atualizar coleção de versículos
  Future<bool> updateVerseCollection(String collectionId, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _clearError();

      updates['updatedAt'] = DateTime.now();

      await _firestore
          .collection(FirestoreDataSchema.verseCollectionsCollection)
          .doc(collectionId)
          .update(FirestoreConverter.prepareForFirestore(updates));

      return true;
    } catch (e) {
      _setError('Erro ao atualizar coleção de versículos: \${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Excluir coleção de versículos
  Future<bool> deleteVerseCollection(String collectionId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore
          .collection(FirestoreDataSchema.verseCollectionsCollection)
          .doc(collectionId)
          .delete();

      return true;
    } catch (e) {
      _setError('Erro ao excluir coleção de versículos: \${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos para Settings

  /// Obter configurações do usuário
  Future<Map<String, dynamic>?> getUserSettings() async {
    if (_currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection(FirestoreDataSchema.settingsCollection)
          .doc(_currentUserId)
          .get();

      if (doc.exists) {
        return FirestoreConverter.parseFromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      _setError('Erro ao obter configurações: \${e.toString()}');
      return null;
    }
  }

  /// Atualizar configurações do usuário
  Future<bool> updateUserSettings(Map<String, dynamic> settings) async {
    if (_currentUserId == null) return false;

    try {
      _setLoading(true);
      _clearError();

      settings['updatedAt'] = DateTime.now();

      await _firestore
          .collection(FirestoreDataSchema.settingsCollection)
          .doc(_currentUserId)
          .update(FirestoreConverter.prepareForFirestore(settings));

      return true;
    } catch (e) {
      _setError('Erro ao atualizar configurações: \${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos auxiliares

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Método para sincronização offline (quando voltar online)
  Future<void> syncOfflineData() async {
    try {
      _setLoading(true);
      _clearError();

      // Habilitar persistência offline do Firestore
      await _firestore.enableNetwork();

      debugPrint('Sincronização offline ativada');
    } catch (e) {
      _setError('Erro na sincronização: \${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Limpar cache local
  Future<void> clearOfflineCache() async {
    try {
      await _firestore.clearPersistence();
      debugPrint('Cache offline limpo');
    } catch (e) {
      debugPrint('Erro ao limpar cache: \$e');
    }
  }
}