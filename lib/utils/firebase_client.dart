import 'package:flutter/foundation.dart';
import 'package:versee/services/firebase_manager.dart';
import 'package:versee/services/realtime_data_service.dart';
import 'package:versee/services/data_sync_manager.dart';
import 'package:versee/services/typed_firebase_service.dart';
import 'package:versee/services/firebase_error_service.dart';
import 'package:versee/repositories/firebase_repository.dart';
import 'package:versee/firestore/firestore_data_schema.dart';

/// Unified Firebase client for VERSEE
/// Provides a simplified interface for all Firebase operations
class FirebaseClient {
  static final FirebaseClient _instance = FirebaseClient._internal();
  factory FirebaseClient() => _instance;
  FirebaseClient._internal();

  late final FirebaseManager _manager;
  late final RealtimeDataService _realtimeService;
  late final DataSyncManager _syncManager;
  late final FirebaseRepository _repository;
  late final TypedFirebaseService _typedService;

  bool _isInitialized = false;

  /// Initialize the Firebase client
  Future<void> initialize({
    RealtimeDataService? realtimeService,
    DataSyncManager? syncManager,
  }) async {
    if (_isInitialized) return;

    _manager = FirebaseManager();
    _realtimeService = realtimeService ?? RealtimeDataService();
    _syncManager = syncManager ?? DataSyncManager();
    _repository = FirebaseRepository();
    _typedService = TypedFirebaseService();

    await _manager.initialize();
    await _syncManager.initialize();

    _isInitialized = true;
    debugPrint('Firebase client initialized successfully');
  }

  /// Authentication operations
  AuthOperations get auth => AuthOperations._(_repository);

  /// Playlist operations
  PlaylistOperations get playlists => PlaylistOperations._(_manager, _repository, _syncManager);

  /// Note operations
  NoteOperations get notes => NoteOperations._(_repository, _syncManager);

  /// Media operations
  MediaOperations get media => MediaOperations._(_manager, _repository, _syncManager);

  /// Verse collection operations
  VerseCollectionOperations get verseCollections => VerseCollectionOperations._(_manager, _repository, _syncManager);

  /// Settings operations
  SettingsOperations get settings => SettingsOperations._(_manager, _repository, _syncManager);

  /// Real-time data access
  RealtimeDataService get realtime => _realtimeService;

  /// Sync manager access
  DataSyncManager get sync => _syncManager;

  /// Direct manager access (for advanced operations)
  FirebaseManager get manager => _manager;

  /// Direct repository access (for advanced operations)
  FirebaseRepository get repository => _repository;

  /// Strongly-typed Firebase service access
  TypedFirebaseService get typed => _typedService;

  /// Firebase error handling
  FirebaseErrorService get errors => FirebaseErrorService();

  /// Check if client is properly initialized
  bool get isInitialized => _isInitialized;

  /// Get current user information
  Map<String, dynamic>? get currentUser {
    final user = _manager.auth.currentUser;
    if (user == null) return null;
    
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'emailVerified': user.emailVerified,
      'photoURL': user.photoURL,
      'creationTime': user.metadata.creationTime?.toIso8601String(),
      'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
    };
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await _manager.cleanup();
    _realtimeService.dispose();
    _syncManager.dispose();
    _isInitialized = false;
  }
}

/// Authentication operations wrapper
class AuthOperations {
  final FirebaseRepository _repository;

  AuthOperations._(this._repository);

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      final credential = await _repository.signInWithEmailAndPassword(email, password);
      return credential != null;
    } catch (e) {
      debugPrint('Sign in error: $e');
      return false;
    }
  }

  /// Register new user
  Future<bool> register(String email, String password, String displayName) async {
    try {
      final credential = await _repository.createUserWithEmailAndPassword(email, password);
      if (credential?.user != null) {
        await credential!.user!.updateDisplayName(displayName);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _repository.signOut();
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _repository.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      debugPrint('Reset password error: $e');
      return false;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _repository.isAuthenticated;

  /// Get current user ID
  String? get currentUserId => _repository.currentUserId;
}

/// Playlist operations wrapper
class PlaylistOperations {
  final FirebaseManager _manager;
  final FirebaseRepository _repository;
  final DataSyncManager _syncManager;

  PlaylistOperations._(this._manager, this._repository, this._syncManager);

  /// Create a new playlist
  Future<String> create({
    required String title,
    required String description,
    List<Map<String, dynamic>>? items,
  }) async {
    final data = FirestoreDataSchema.playlistDocument(
      userId: _repository.currentUserId!,
      title: title,
      description: description,
      items: items ?? [],
    );

    return await _syncManager.createWithSync(
      collection: FirestoreDataSchema.playlistsCollection,
      data: data,
    );
  }

  /// Update a playlist
  Future<bool> update(String playlistId, Map<String, dynamic> updates) async {
    return await _syncManager.updateWithSync(
      collection: FirestoreDataSchema.playlistsCollection,
      documentId: playlistId,
      data: updates,
    );
  }

  /// Delete a playlist
  Future<bool> delete(String playlistId) async {
    return await _syncManager.deleteWithSync(
      collection: FirestoreDataSchema.playlistsCollection,
      documentId: playlistId,
    );
  }

  /// Get all user playlists (stream)
  Stream<List<Map<String, dynamic>>> getAll() {
    return _repository.getUserPlaylists();
  }

  /// Get a specific playlist (stream)
  Stream<Map<String, dynamic>?> get(String playlistId) {
    return _repository.watchDocument(FirestoreDataSchema.playlistsCollection, playlistId)
        .map((doc) => doc.exists ? {...doc.data() as Map<String, dynamic>, 'id': doc.id} : null);
  }

  /// Add item to playlist
  Future<bool> addItem(String playlistId, Map<String, dynamic> item) async {
    // This would need to fetch current playlist, add item, and update
    // Implementation would depend on your specific playlist structure
    return await update(playlistId, {'items': 'append_item_logic_here'});
  }

  /// Remove item from playlist
  Future<bool> removeItem(String playlistId, String itemId) async {
    // Implementation would depend on your specific playlist structure
    return await update(playlistId, {'items': 'remove_item_logic_here'});
  }
}

/// Note operations wrapper
class NoteOperations {
  final FirebaseRepository _repository;
  final DataSyncManager _syncManager;

  NoteOperations._(this._repository, this._syncManager);

  /// Create a new note
  Future<String> create({
    required String title,
    String? description,
    List<Map<String, dynamic>>? slides,
  }) async {
    final data = FirestoreDataSchema.noteDocument(
      userId: _repository.currentUserId!,
      title: title,
      description: description,
      slides: slides ?? [],
    );

    return await _syncManager.createWithSync(
      collection: FirestoreDataSchema.notesCollection,
      data: data,
    );
  }

  /// Update a note
  Future<bool> update(String noteId, Map<String, dynamic> updates) async {
    return await _syncManager.updateWithSync(
      collection: FirestoreDataSchema.notesCollection,
      documentId: noteId,
      data: updates,
    );
  }

  /// Delete a note
  Future<bool> delete(String noteId) async {
    return await _syncManager.deleteWithSync(
      collection: FirestoreDataSchema.notesCollection,
      documentId: noteId,
    );
  }

  /// Get all user notes (stream)
  Stream<List<Map<String, dynamic>>> getAll() {
    return _repository.getUserNotes();
  }

  /// Get a specific note (stream)
  Stream<Map<String, dynamic>?> get(String noteId) {
    return _repository.watchDocument(FirestoreDataSchema.notesCollection, noteId)
        .map((doc) => doc.exists ? {...doc.data() as Map<String, dynamic>, 'id': doc.id} : null);
  }

  /// Get notes by type
  Stream<List<Map<String, dynamic>>> getByType(String type) {
    return _repository.getUserNotes();
  }
}

/// Media operations wrapper
class MediaOperations {
  final FirebaseManager _manager;
  final FirebaseRepository _repository;
  final DataSyncManager _syncManager;

  MediaOperations._(this._manager, this._repository, this._syncManager);

  /// Create a new media record
  Future<String> create({
    required String type,
    required String name,
    required String fileName,
    required String storagePath,
    required int fileSize,
    String? duration,
    String? thumbnailPath,
  }) async {
    final data = FirestoreDataSchema.mediaDocument(
      userId: _repository.currentUserId!,
      type: type,
      name: name,
      fileName: fileName,
      storagePath: storagePath,
      fileSize: fileSize,
      duration: duration,
      thumbnailPath: thumbnailPath,
    );

    return await _syncManager.createWithSync(
      collection: FirestoreDataSchema.mediaCollection,
      data: data,
    );
  }

  /// Upload file and create media record
  Future<String> upload({
    required String fileName,
    required Uint8List data,
    required String type,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    // Upload file to storage
    final downloadUrl = await _manager.uploadUserFile(
      _repository.currentUserId!,
      fileName,
      data,
      contentType: contentType,
      onProgress: onProgress,
    );

    // Create media record
    return await create(
      type: type,
      name: fileName,
      fileName: fileName,
      storagePath: _manager.getUserStoragePath(fileName),
      fileSize: data.length,
    );
  }

  /// Delete a media item
  Future<bool> delete(String mediaId) async {
    return await _syncManager.deleteWithSync(
      collection: FirestoreDataSchema.mediaCollection,
      documentId: mediaId,
    );
  }

  /// Get all user media (stream)
  Stream<List<Map<String, dynamic>>> getAll({String? type}) {
    return _repository.getUserMedia(type: type);
  }

  /// Get media by type
  Stream<List<Map<String, dynamic>>> getByType(String type) {
    return _repository.getUserMedia(type: type);
  }
}

/// Verse collection operations wrapper
class VerseCollectionOperations {
  final FirebaseManager _manager;
  final FirebaseRepository _repository;
  final DataSyncManager _syncManager;

  VerseCollectionOperations._(this._manager, this._repository, this._syncManager);

  /// Create a new verse collection
  Future<String> create({
    required String title,
    required List<Map<String, dynamic>> verses,
  }) async {
    final data = FirestoreDataSchema.verseCollectionDocument(
      userId: _repository.currentUserId!,
      title: title,
      verses: verses,
    );

    return await _syncManager.createWithSync(
      collection: FirestoreDataSchema.verseCollectionsCollection,
      data: data,
    );
  }

  /// Update a verse collection
  Future<bool> update(String collectionId, Map<String, dynamic> updates) async {
    return await _syncManager.updateWithSync(
      collection: FirestoreDataSchema.verseCollectionsCollection,
      documentId: collectionId,
      data: updates,
    );
  }

  /// Delete a verse collection
  Future<bool> delete(String collectionId) async {
    return await _syncManager.deleteWithSync(
      collection: FirestoreDataSchema.verseCollectionsCollection,
      documentId: collectionId,
    );
  }

  /// Get all user verse collections (stream)
  Stream<List<Map<String, dynamic>>> getAll() {
    return _repository.getUserVerseCollections();
  }
}

/// Settings operations wrapper
class SettingsOperations {
  final FirebaseManager _manager;
  final FirebaseRepository _repository;
  final DataSyncManager _syncManager;

  SettingsOperations._(this._manager, this._repository, this._syncManager);

  /// Get user settings
  Future<Map<String, dynamic>?> get() async {
    return await _repository.getUserSettings();
  }

  /// Update user settings
  Future<bool> update(Map<String, dynamic> settings) async {
    return await _syncManager.updateWithSync(
      collection: FirestoreDataSchema.settingsCollection,
      documentId: _repository.currentUserId!,
      data: settings,
    );
  }

  /// Get user settings (stream)
  Stream<Map<String, dynamic>?> getStream() {
    if (_repository.currentUserId == null) return Stream.value(null);
    
    return _repository.watchDocument(FirestoreDataSchema.settingsCollection, _repository.currentUserId!)
        .map((doc) => doc.exists ? doc.data() as Map<String, dynamic> : null);
  }
}