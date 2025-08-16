import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:versee/firestore/firestore_data_schema.dart';
import 'package:versee/models/user_models.dart';
import 'package:versee/models/playlist_models.dart';
import 'package:versee/models/bible_models.dart';
import 'package:versee/models/note_models.dart';
import 'package:versee/repositories/firebase_repository.dart';

/// Strongly-typed Firebase service that provides type-safe operations
/// for all VERSEE collections using proper models
class TypedFirebaseService {
  static final TypedFirebaseService _instance = TypedFirebaseService._internal();
  factory TypedFirebaseService() => _instance;
  TypedFirebaseService._internal();

  final FirebaseRepository _repository = FirebaseRepository();

  // Getters for common auth properties
  User? get currentUser => _repository.currentUser;
  String? get currentUserId => _repository.currentUserId;
  bool get isAuthenticated => _repository.isAuthenticated;
  Stream<User?> get authStateChanges => _repository.authStateChanges;

  /// USER OPERATIONS
  
  /// Create user document after authentication
  Future<bool> createUserDocument(UserModel user) async {
    try {
      await _repository.setDocument(
        FirestoreDataSchema.usersCollection,
        user.id,
        user.toFirestore(),
      );
      debugPrint('✅ User document created: ${user.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating user document: $e');
      return false;
    }
  }

  /// Get user document
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _repository.getDocument(FirestoreDataSchema.usersCollection, userId);
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user: $e');
      return null;
    }
  }

  /// Get current user document
  Future<UserModel?> getCurrentUser() async {
    if (currentUserId == null) return null;
    return await getUser(currentUserId!);
  }

  /// Update user document
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now();
      await _repository.updateDocument(FirestoreDataSchema.usersCollection, userId, updates);
      debugPrint('✅ User updated: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user: $e');
      return false;
    }
  }

  /// Watch user document changes
  Stream<UserModel?> watchUser(String userId) {
    return _repository.watchDocument(FirestoreDataSchema.usersCollection, userId)
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  /// PLAYLIST OPERATIONS

  /// Create a new playlist
  Future<String?> createPlaylist(PlaylistModel playlist) async {
    try {
      final docRef = await _repository.addDocument(
        FirestoreDataSchema.playlistsCollection,
        playlist.toFirestore(),
      );
      debugPrint('✅ Playlist created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating playlist: $e');
      return null;
    }
  }

  /// Get playlist by ID
  Future<PlaylistModel?> getPlaylist(String playlistId) async {
    try {
      final doc = await _repository.getDocument(FirestoreDataSchema.playlistsCollection, playlistId);
      if (doc.exists) {
        return PlaylistModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting playlist: $e');
      return null;
    }
  }

  /// Update playlist
  Future<bool> updatePlaylist(String playlistId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now();
      await _repository.updateDocument(FirestoreDataSchema.playlistsCollection, playlistId, updates);
      debugPrint('✅ Playlist updated: $playlistId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating playlist: $e');
      return false;
    }
  }

  /// Delete playlist
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      await _repository.deleteDocument(FirestoreDataSchema.playlistsCollection, playlistId);
      debugPrint('✅ Playlist deleted: $playlistId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting playlist: $e');
      return false;
    }
  }

  /// Get user playlists as strongly-typed models
  Stream<List<PlaylistModel>> getUserPlaylists() {
    if (currentUserId == null) return Stream.value([]);
    
    return _repository.getUserCollection(FirestoreDataSchema.playlistsCollection, orderBy: 'updatedAt')
        .map((snapshot) => snapshot.docs
            .map((doc) => PlaylistModel.fromFirestore(doc))
            .toList());
  }

  /// Watch playlist changes
  Stream<PlaylistModel?> watchPlaylist(String playlistId) {
    return _repository.watchDocument(FirestoreDataSchema.playlistsCollection, playlistId)
        .map((doc) => doc.exists ? PlaylistModel.fromFirestore(doc) : null);
  }

  /// VERSE COLLECTION OPERATIONS

  /// Create verse collection from VerseCollection model
  Future<String?> createVerseCollection(VerseCollection verseCollection) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');
      
      final data = FirestoreDataSchema.verseCollectionDocument(
        userId: currentUserId!,
        title: verseCollection.title,
        verses: verseCollection.verses.map((verse) => verse.toJson()).toList(),
      );

      final docRef = await _repository.addDocument(FirestoreDataSchema.verseCollectionsCollection, data);
      debugPrint('✅ Verse collection created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating verse collection: $e');
      return null;
    }
  }

  /// Get verse collection by ID
  Future<VerseCollection?> getVerseCollection(String collectionId) async {
    try {
      final doc = await _repository.getDocument(FirestoreDataSchema.verseCollectionsCollection, collectionId);
      if (doc.exists) {
        final data = FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>);
        return VerseCollection.fromJson({...data, 'id': doc.id});
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting verse collection: $e');
      return null;
    }
  }

  /// Get user verse collections
  Stream<List<VerseCollection>> getUserVerseCollections() {
    if (currentUserId == null) return Stream.value([]);
    
    return _repository.getUserCollection(FirestoreDataSchema.verseCollectionsCollection, orderBy: 'updatedAt')
        .map((snapshot) => snapshot.docs.map((doc) {
            final data = FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>);
            return VerseCollection.fromJson({...data, 'id': doc.id});
          }).toList());
  }

  /// Update verse collection
  Future<bool> updateVerseCollection(String collectionId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now();
      await _repository.updateDocument(FirestoreDataSchema.verseCollectionsCollection, collectionId, updates);
      debugPrint('✅ Verse collection updated: $collectionId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating verse collection: $e');
      return false;
    }
  }

  /// Delete verse collection
  Future<bool> deleteVerseCollection(String collectionId) async {
    try {
      await _repository.deleteDocument(FirestoreDataSchema.verseCollectionsCollection, collectionId);
      debugPrint('✅ Verse collection deleted: $collectionId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting verse collection: $e');
      return false;
    }
  }

  /// NOTE OPERATIONS

  /// Create note from NoteItem model
  Future<String?> createNote(NoteItem noteItem) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');
      
      final data = FirestoreDataSchema.noteDocument(
        userId: currentUserId!,
        title: noteItem.title,
        description: noteItem.description,
        slides: noteItem.slides.map((slide) => FirestoreDataSchema.noteSlide(
          order: slide.order,
          content: slide.content,
          backgroundColor: slide.backgroundColor?.value.toRadixString(16),
          textColor: slide.textStyle?.color?.value.toRadixString(16),
        )).toList(),
      );

      final docRef = await _repository.addDocument(FirestoreDataSchema.notesCollection, data);
      debugPrint('✅ Note created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating note: $e');
      return null;
    }
  }

  /// Get user notes
  Stream<List<Map<String, dynamic>>> getUserNotes() {
    return _repository.getUserNotes();
  }

  /// Update note
  Future<bool> updateNote(String noteId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now();
      await _repository.updateDocument(FirestoreDataSchema.notesCollection, noteId, updates);
      debugPrint('✅ Note updated: $noteId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating note: $e');
      return false;
    }
  }

  /// Delete note
  Future<bool> deleteNote(String noteId) async {
    try {
      await _repository.deleteDocument(FirestoreDataSchema.notesCollection, noteId);
      debugPrint('✅ Note deleted: $noteId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting note: $e');
      return false;
    }
  }

  /// MEDIA OPERATIONS

  /// Get user media by type
  Stream<List<Map<String, dynamic>>> getUserMedia({String? type}) {
    return _repository.getUserMedia(type: type);
  }

  /// Create media record
  Future<String?> createMediaRecord({
    required String type,
    required String name,
    required String fileName,
    required String storagePath,
    required int fileSize,
    String? duration,
    String? thumbnailPath,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');
      
      final data = FirestoreDataSchema.mediaDocument(
        userId: currentUserId!,
        type: type,
        name: name,
        fileName: fileName,
        storagePath: storagePath,
        fileSize: fileSize,
        duration: duration,
        thumbnailPath: thumbnailPath,
      );

      final docRef = await _repository.addDocument(FirestoreDataSchema.mediaCollection, data);
      debugPrint('✅ Media record created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating media record: $e');
      return null;
    }
  }

  /// Update media record
  Future<bool> updateMedia(String mediaId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now();
      await _repository.updateDocument(FirestoreDataSchema.mediaCollection, mediaId, updates);
      debugPrint('✅ Media updated: $mediaId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating media: $e');
      return false;
    }
  }

  /// Delete media record
  Future<bool> deleteMedia(String mediaId) async {
    try {
      await _repository.deleteDocument(FirestoreDataSchema.mediaCollection, mediaId);
      debugPrint('✅ Media deleted: $mediaId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting media: $e');
      return false;
    }
  }

  /// SETTINGS OPERATIONS

  /// Get user settings
  Future<UserSettingsModel?> getUserSettings() async {
    try {
      if (currentUserId == null) return null;
      
      final doc = await _repository.getDocument(FirestoreDataSchema.settingsCollection, currentUserId!);
      if (doc.exists) {
        return UserSettingsModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user settings: $e');
      return null;
    }
  }

  /// Update user settings
  Future<bool> updateUserSettings(UserSettingsModel settings) async {
    try {
      await _repository.setDocument(
        FirestoreDataSchema.settingsCollection,
        settings.userId,
        settings.toFirestore(),
      );
      debugPrint('✅ User settings updated: ${settings.userId}');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user settings: $e');
      return false;
    }
  }

  /// Watch user settings changes
  Stream<UserSettingsModel?> watchUserSettings() {
    if (currentUserId == null) return Stream.value(null);
    
    return _repository.watchDocument(FirestoreDataSchema.settingsCollection, currentUserId!)
        .map((doc) => doc.exists ? UserSettingsModel.fromFirestore(doc) : null);
  }

  /// BATCH OPERATIONS

  /// Create a batch operation for multiple writes
  WriteBatch createBatch() => _repository.createBatch();

  /// Commit batch operation
  Future<void> commitBatch(WriteBatch batch) => _repository.commitBatch(batch);

  /// UTILITY METHODS

  /// Enable offline persistence
  Future<void> enableOfflinePersistence() => _repository.enableOfflinePersistence();

  /// Disable offline persistence
  Future<void> disableOfflinePersistence() => _repository.disableOfflinePersistence();

  /// Clear offline cache
  Future<void> clearOfflineCache() => _repository.clearOfflineCache();

  /// Get error message for Firebase Auth errors
  String getAuthErrorMessage(String code) => FirebaseRepository.getFirebaseAuthErrorMessage(code);

  /// Get error message for Firestore errors
  String getFirestoreErrorMessage(String message) => FirebaseRepository.getFirestoreErrorMessage(message);
}