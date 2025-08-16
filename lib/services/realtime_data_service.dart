import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:versee/firestore/firestore_data_schema.dart';
import 'package:versee/services/firebase_manager.dart';

/// Real-time data service for VERSEE
/// Provides live data updates using Firestore streams with proper error handling
class RealtimeDataService extends ChangeNotifier {
  final FirebaseManager _firebase = FirebaseManager();
  
  // Stream subscriptions for cleanup
  final Map<String, StreamSubscription> _subscriptions = {};
  
  // Cache for real-time data
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  
  // Loading states
  final Map<String, bool> _loadingStates = {};
  
  // Error states
  final Map<String, String?> _errorStates = {};

  String? get currentUserId => _firebase.currentUserId;

  // Getters for cached data
  List<Map<String, dynamic>> getPlaylists() => _cache['playlists'] ?? [];
  List<Map<String, dynamic>> getNotes({String? type}) {
    final notes = _cache['notes'] ?? [];
    if (type == null) return notes;
    return notes.where((note) => note['type'] == type).toList();
  }
  List<Map<String, dynamic>> getMedia({String? type}) {
    final media = _cache['media'] ?? [];
    if (type == null) return media;
    return media.where((item) => item['type'] == type).toList();
  }
  List<Map<String, dynamic>> getVerseCollections() => _cache['verseCollections'] ?? [];

  // Loading state getters
  bool isPlaylistsLoading() => _loadingStates['playlists'] ?? false;
  bool isNotesLoading() => _loadingStates['notes'] ?? false;
  bool isMediaLoading() => _loadingStates['media'] ?? false;
  bool isVerseCollectionsLoading() => _loadingStates['verseCollections'] ?? false;

  // Error state getters
  String? getPlaylistsError() => _errorStates['playlists'];
  String? getNotesError() => _errorStates['notes'];
  String? getMediaError() => _errorStates['media'];
  String? getVerseCollectionsError() => _errorStates['verseCollections'];

  /// Initialize real-time streams for user data
  void startListening() {
    if (currentUserId == null) {
      debugPrint('No user authenticated, cannot start real-time listening');
      return;
    }

    _startPlaylistsStream();
    _startNotesStream();
    _startMediaStream();
    _startVerseCollectionsStream();

    debugPrint('Real-time streams started for user: $currentUserId');
  }

  /// Stop all real-time streams
  void stopListening() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _cache.clear();
    _loadingStates.clear();
    _errorStates.clear();
    
    debugPrint('Real-time streams stopped');
    notifyListeners();
  }

  /// Start playlists real-time stream
  void _startPlaylistsStream() {
    if (currentUserId == null) return;

    _setLoadingState('playlists', true);
    
    final stream = _firebase.firestore
        .collection(FirestoreDataSchema.playlistsCollection)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    _subscriptions['playlists'] = stream.listen(
      (snapshot) {
        final playlists = snapshot.docs.map((doc) {
          final data = FirestoreConverter.parseFromFirestore(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();

        _cache['playlists'] = playlists;
        _setLoadingState('playlists', false);
        _clearError('playlists');
        notifyListeners();
      },
      onError: (error) {
        _setError('playlists', 'Erro ao carregar playlists: $error');
        _setLoadingState('playlists', false);
        notifyListeners();
      },
    );
  }

  /// Start notes real-time stream
  void _startNotesStream() {
    if (currentUserId == null) return;

    _setLoadingState('notes', true);
    
    final stream = _firebase.firestore
        .collection(FirestoreDataSchema.notesCollection)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    _subscriptions['notes'] = stream.listen(
      (snapshot) {
        final notes = snapshot.docs.map((doc) {
          final data = FirestoreConverter.parseFromFirestore(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();

        _cache['notes'] = notes;
        _setLoadingState('notes', false);
        _clearError('notes');
        notifyListeners();
      },
      onError: (error) {
        _setError('notes', 'Erro ao carregar notas: $error');
        _setLoadingState('notes', false);
        notifyListeners();
      },
    );
  }

  /// Start media real-time stream
  void _startMediaStream() {
    if (currentUserId == null) return;

    _setLoadingState('media', true);
    
    final stream = _firebase.firestore
        .collection(FirestoreDataSchema.mediaCollection)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    _subscriptions['media'] = stream.listen(
      (snapshot) {
        final media = snapshot.docs.map((doc) {
          final data = FirestoreConverter.parseFromFirestore(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();

        _cache['media'] = media;
        _setLoadingState('media', false);
        _clearError('media');
        notifyListeners();
      },
      onError: (error) {
        _setError('media', 'Erro ao carregar mídia: $error');
        _setLoadingState('media', false);
        notifyListeners();
      },
    );
  }

  /// Start verse collections real-time stream
  void _startVerseCollectionsStream() {
    if (currentUserId == null) return;

    _setLoadingState('verseCollections', true);
    
    final stream = _firebase.firestore
        .collection(FirestoreDataSchema.verseCollectionsCollection)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    _subscriptions['verseCollections'] = stream.listen(
      (snapshot) {
        final collections = snapshot.docs.map((doc) {
          final data = FirestoreConverter.parseFromFirestore(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();

        _cache['verseCollections'] = collections;
        _setLoadingState('verseCollections', false);
        _clearError('verseCollections');
        notifyListeners();
      },
      onError: (error) {
        _setError('verseCollections', 'Erro ao carregar coleções de versículos: $error');
        _setLoadingState('verseCollections', false);
        notifyListeners();
      },
    );
  }

  /// Get real-time stream for a specific playlist
  Stream<Map<String, dynamic>?> getPlaylistStream(String playlistId) {
    return _firebase.firestore
        .collection(FirestoreDataSchema.playlistsCollection)
        .doc(playlistId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = FirestoreConverter.parseFromFirestore(doc.data()!);
      data['id'] = doc.id;
      return data;
    });
  }

  /// Get real-time stream for a specific note
  Stream<Map<String, dynamic>?> getNoteStream(String noteId) {
    return _firebase.firestore
        .collection(FirestoreDataSchema.notesCollection)
        .doc(noteId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = FirestoreConverter.parseFromFirestore(doc.data()!);
      data['id'] = doc.id;
      return data;
    });
  }

  /// Get real-time stream for user settings
  Stream<Map<String, dynamic>?> getUserSettingsStream() {
    if (currentUserId == null) return Stream.value(null);
    
    return _firebase.firestore
        .collection(FirestoreDataSchema.settingsCollection)
        .doc(currentUserId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return FirestoreConverter.parseFromFirestore(doc.data()!);
    });
  }

  /// Listen to connectivity changes and reconnect streams
  void handleConnectivityChange(bool isConnected) {
    if (isConnected) {
      debugPrint('Connectivity restored, restarting streams');
      stopListening();
      startListening();
    } else {
      debugPrint('Connectivity lost, streams will work offline');
    }
  }

  /// Get statistics about user's data
  Map<String, int> getDataStatistics() {
    return {
      'playlists': getPlaylists().length,
      'notes': getNotes().length,
      'lyrics': getNotes(type: 'lyrics').length,
      'media': getMedia().length,
      'audio': getMedia(type: 'audio').length,
      'video': getMedia(type: 'video').length,
      'image': getMedia(type: 'image').length,
      'verseCollections': getVerseCollections().length,
    };
  }

  /// Search across all cached data
  List<Map<String, dynamic>> searchAll(String query) {
    final results = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase();

    // Search playlists
    for (final playlist in getPlaylists()) {
      if (_matchesQuery(playlist, lowerQuery, ['title', 'description'])) {
        results.add({...playlist, '_type': 'playlist'});
      }
    }

    // Search notes
    for (final note in getNotes()) {
      if (_matchesQuery(note, lowerQuery, ['title'])) {
        results.add({...note, '_type': 'note'});
      }
    }

    // Search media
    for (final media in getMedia()) {
      if (_matchesQuery(media, lowerQuery, ['name', 'fileName'])) {
        results.add({...media, '_type': 'media'});
      }
    }

    // Search verse collections
    for (final collection in getVerseCollections()) {
      if (_matchesQuery(collection, lowerQuery, ['title'])) {
        results.add({...collection, '_type': 'verseCollection'});
      }
    }

    return results;
  }

  bool _matchesQuery(Map<String, dynamic> item, String query, List<String> fields) {
    for (final field in fields) {
      final value = item[field]?.toString().toLowerCase();
      if (value != null && value.contains(query)) {
        return true;
      }
    }
    return false;
  }

  /// Helper methods for state management
  void _setLoadingState(String key, bool loading) {
    _loadingStates[key] = loading;
  }

  void _setError(String key, String error) {
    _errorStates[key] = error;
  }

  void _clearError(String key) {
    _errorStates[key] = null;
  }

  /// Refresh specific data type
  Future<void> refreshPlaylists() async {
    _subscriptions['playlists']?.cancel();
    _startPlaylistsStream();
  }

  Future<void> refreshNotes() async {
    _subscriptions['notes']?.cancel();
    _startNotesStream();
  }

  Future<void> refreshMedia() async {
    _subscriptions['media']?.cancel();
    _startMediaStream();
  }

  Future<void> refreshVerseCollections() async {
    _subscriptions['verseCollections']?.cancel();
    _startVerseCollectionsStream();
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    stopListening();
    await Future.delayed(const Duration(milliseconds: 500));
    startListening();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}