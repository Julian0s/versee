import 'package:flutter/foundation.dart';
import 'package:versee/repositories/firebase_repository.dart';
import 'package:versee/firestore/firestore_data_schema.dart';

/// Comprehensive Firebase client service for Versee app
/// Provides high-level operations for all Firebase collections
class FirebaseClientService {
  static final FirebaseClientService _instance = FirebaseClientService._internal();
  factory FirebaseClientService() => _instance;
  FirebaseClientService._internal();

  final FirebaseRepository _repository = FirebaseRepository();

  // Getters
  bool get isAuthenticated => _repository.isAuthenticated;
  String? get currentUserId => _repository.currentUserId;

  /// Authentication Operations
  
  Future<bool> signIn(String email, String password) async {
    try {
      final result = await _repository.signInWithEmailAndPassword(email, password);
      return result != null;
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    try {
      final result = await _repository.createUserWithEmailAndPassword(email, password);
      if (result != null) {
        // Create user profile document
        await _repository.setDocument(
          FirestoreDataSchema.usersCollection,
          result.user!.uid,
          FirestoreDataSchema.userDocument(
            email: email,
            displayName: displayName,
            plan: 'free',
            language: 'pt',
            theme: 'dark',
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _repository.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      debugPrint('❌ Reset password error: $e');
      return false;
    }
  }

  /// Notes Operations
  
  Future<String?> createNote({
    required String title,
    String? description,
    required List<Map<String, dynamic>> slides,
  }) async {
    try {
      final noteData = FirestoreDataSchema.noteDocument(
        userId: currentUserId!,
        title: title,
        description: description,
        slides: slides,
      );
      return await _repository.createNote(noteData);
    } catch (e) {
      debugPrint('❌ Create note error: $e');
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> watchNotes() {
    return _repository.getUserNotes();
  }

  Future<Map<String, dynamic>?> getNote(String noteId) async {
    return await _repository.getNote(noteId);
  }

  Future<bool> updateNote(String noteId, {
    String? title,
    String? description,
    List<Map<String, dynamic>>? slides,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (slides != null) {
        updates['slides'] = slides;
        updates['slideCount'] = slides.length;
      }
      
      await _repository.updateNote(noteId, updates);
      return true;
    } catch (e) {
      debugPrint('❌ Update note error: $e');
      return false;
    }
  }

  Future<bool> deleteNote(String noteId) async {
    try {
      await _repository.deleteNote(noteId);
      return true;
    } catch (e) {
      debugPrint('❌ Delete note error: $e');
      return false;
    }
  }

  /// Lyrics Operations
  
  Future<String?> createLyrics({
    required String title,
    String? description,
    required List<Map<String, dynamic>> slides,
  }) async {
    try {
      final lyricsData = FirestoreDataSchema.lyricsDocument(
        userId: currentUserId!,
        title: title,
        description: description,
        slides: slides,
      );
      return await _repository.createLyrics(lyricsData);
    } catch (e) {
      debugPrint('❌ Create lyrics error: $e');
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> watchLyrics() {
    return _repository.getUserLyrics();
  }

  Future<Map<String, dynamic>?> getLyrics(String lyricsId) async {
    return await _repository.getLyrics(lyricsId);
  }

  Future<bool> updateLyrics(String lyricsId, {
    String? title,
    String? description,
    List<Map<String, dynamic>>? slides,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (slides != null) {
        updates['slides'] = slides;
        updates['slideCount'] = slides.length;
      }
      
      await _repository.updateLyrics(lyricsId, updates);
      return true;
    } catch (e) {
      debugPrint('❌ Update lyrics error: $e');
      return false;
    }
  }

  Future<bool> deleteLyrics(String lyricsId) async {
    try {
      await _repository.deleteLyrics(lyricsId);
      return true;
    } catch (e) {
      debugPrint('❌ Delete lyrics error: $e');
      return false;
    }
  }

  /// Media Operations
  
  Future<String?> createMedia({
    required String type,
    required String name,
    required String fileName,
    required String storagePath,
    required int fileSize,
    String? duration,
    String? thumbnailPath,
  }) async {
    try {
      final mediaData = FirestoreDataSchema.mediaDocument(
        userId: currentUserId!,
        type: type,
        name: name,
        fileName: fileName,
        storagePath: storagePath,
        fileSize: fileSize,
        duration: duration,
        thumbnailPath: thumbnailPath,
      );
      return await _repository.createMedia(mediaData);
    } catch (e) {
      debugPrint('❌ Create media error: $e');
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> watchMedia({String? type}) {
    return _repository.getUserMedia(type: type);
  }

  Future<Map<String, dynamic>?> getMedia(String mediaId) async {
    return await _repository.getMedia(mediaId);
  }

  Future<bool> updateMedia(String mediaId, Map<String, dynamic> updates) async {
    try {
      await _repository.updateMedia(mediaId, updates);
      return true;
    } catch (e) {
      debugPrint('❌ Update media error: $e');
      return false;
    }
  }

  Future<bool> deleteMedia(String mediaId) async {
    try {
      await _repository.deleteMedia(mediaId);
      return true;
    } catch (e) {
      debugPrint('❌ Delete media error: $e');
      return false;
    }
  }

  /// Playlist Operations
  
  Future<String?> createPlaylist({
    required String title,
    required String description,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final playlistData = FirestoreDataSchema.playlistDocument(
        userId: currentUserId!,
        title: title,
        description: description,
        items: items,
      );
      return await _repository.createPlaylist(playlistData);
    } catch (e) {
      debugPrint('❌ Create playlist error: $e');
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> watchPlaylists() {
    return _repository.getUserPlaylists();
  }

  Future<Map<String, dynamic>?> getPlaylist(String playlistId) async {
    return await _repository.getPlaylist(playlistId);
  }

  Future<bool> updatePlaylist(String playlistId, {
    String? title,
    String? description,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (items != null) {
        updates['items'] = items;
        updates['itemCount'] = items.length;
      }
      
      await _repository.updatePlaylist(playlistId, updates);
      return true;
    } catch (e) {
      debugPrint('❌ Update playlist error: $e');
      return false;
    }
  }

  Future<bool> deletePlaylist(String playlistId) async {
    try {
      await _repository.deletePlaylist(playlistId);
      return true;
    } catch (e) {
      debugPrint('❌ Delete playlist error: $e');
      return false;
    }
  }

  /// Verse Collection Operations
  
  Future<String?> createVerseCollection({
    required String title,
    required List<Map<String, dynamic>> verses,
  }) async {
    try {
      final collectionData = FirestoreDataSchema.verseCollectionDocument(
        userId: currentUserId!,
        title: title,
        verses: verses,
      );
      return await _repository.createVerseCollection(collectionData);
    } catch (e) {
      debugPrint('❌ Create verse collection error: $e');
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> watchVerseCollections() {
    return _repository.getUserVerseCollections();
  }

  Future<Map<String, dynamic>?> getVerseCollection(String collectionId) async {
    return await _repository.getVerseCollection(collectionId);
  }

  Future<bool> updateVerseCollection(String collectionId, {
    String? title,
    List<Map<String, dynamic>>? verses,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (verses != null) {
        updates['verses'] = verses;
        updates['verseCount'] = verses.length;
      }
      
      await _repository.updateVerseCollection(collectionId, updates);
      return true;
    } catch (e) {
      debugPrint('❌ Update verse collection error: $e');
      return false;
    }
  }

  Future<bool> deleteVerseCollection(String collectionId) async {
    try {
      await _repository.deleteVerseCollection(collectionId);
      return true;
    } catch (e) {
      debugPrint('❌ Delete verse collection error: $e');
      return false;
    }
  }

  /// Storage Operations
  
  Future<String?> uploadFile(String fileName, Uint8List data, {String? contentType}) async {
    try {
      return await _repository.uploadUserFile(fileName, data, contentType: contentType);
    } catch (e) {
      debugPrint('❌ Upload file error: $e');
      return null;
    }
  }

  Future<bool> deleteFile(String path) async {
    try {
      await _repository.deleteFile(path);
      return true;
    } catch (e) {
      debugPrint('❌ Delete file error: $e');
      return false;
    }
  }

  Future<String?> getDownloadURL(String path) async {
    try {
      return await _repository.getDownloadURL(path);
    } catch (e) {
      debugPrint('❌ Get download URL error: $e');
      return null;
    }
  }

  /// Settings Operations
  
  Future<Map<String, dynamic>?> getUserSettings() async {
    return await _repository.getUserSettings();
  }

  Future<bool> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      await _repository.updateUserSettings(settings);
      return true;
    } catch (e) {
      debugPrint('❌ Update settings error: $e');
      return false;
    }
  }

  /// Utility Methods
  
  Future<void> enableOfflinePersistence() async {
    await _repository.enableOfflinePersistence();
  }

  Future<void> disableOfflinePersistence() async {
    await _repository.disableOfflinePersistence();
  }

  Future<void> clearOfflineCache() async {
    await _repository.clearOfflineCache();
  }

  /// Batch Operations
  
  Future<bool> performBatchOperation(Function(dynamic) operation) async {
    try {
      final batch = _repository.createBatch();
      await operation(batch);
      await _repository.commitBatch(batch);
      return true;
    } catch (e) {
      debugPrint('❌ Batch operation error: $e');
      return false;
    }
  }

  /// Helper Methods for Data Creation
  
  Map<String, dynamic> createNoteSlide({
    required int order,
    required String content,
    String? backgroundColor,
    String? textColor,
    String? fontSize,
  }) {
    return FirestoreDataSchema.noteSlide(
      order: order,
      content: content,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: fontSize,
    );
  }

  Map<String, dynamic> createVerse({
    required String book,
    required int chapter,
    required int verse,
    required String text,
    required String version,
  }) {
    return FirestoreDataSchema.verse(
      book: book,
      chapter: chapter,
      verse: verse,
      text: text,
      version: version,
    );
  }

  Map<String, dynamic> createPlaylistItem({
    required int order,
    required String type,
    required String itemId,
    required String title,
    Map<String, dynamic>? metadata,
  }) {
    return FirestoreDataSchema.playlistItem(
      order: order,
      type: type,
      itemId: itemId,
      title: title,
      metadata: metadata,
    );
  }
}