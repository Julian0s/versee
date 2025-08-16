import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:versee/firebase_options.dart';
import 'package:versee/models/media_models.dart';

/// Central manager for Firebase services initialization and configuration
/// Provides a unified interface for Firebase operations across the VERSEE app
class FirebaseManager {
  static final FirebaseManager _instance = FirebaseManager._internal();
  factory FirebaseManager() => _instance;
  FirebaseManager._internal();

  bool _isInitialized = false;
  bool _isOfflineEnabled = false;

  // Firebase service instances
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  bool get isInitialized => _isInitialized;
  bool get isOfflineEnabled => _isOfflineEnabled;
  String? get currentUserId => auth.currentUser?.uid;

  /// Initialize Firebase with proper configuration for VERSEE
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure Firestore settings
      await _configureFirestore();
      
      // Configure Auth settings
      _configureAuth();

      _isInitialized = true;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      rethrow;
    }
  }

  /// Configure Firestore with optimal settings for VERSEE
  Future<void> _configureFirestore() async {
    try {
      // For Android/iOS, persistence is enabled by default
      // We just need to ensure network is enabled
      if (!kIsWeb) {
        // On mobile platforms, just ensure network is enabled
        await firestore.enableNetwork().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Firestore enableNetwork timeout - continuing anyway');
          },
        );
      } else {
        // Configure Firestore settings for web
        firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: 100 * 1024 * 1024, // 100MB cache instead of unlimited
        );
      }
      
      _isOfflineEnabled = true;
      debugPrint('Firestore configured with offline persistence');
    } catch (e) {
      debugPrint('Firestore configuration error: $e');
      // Don't throw error, just log it
      _isOfflineEnabled = false;
    }
  }

  /// Configure Firebase Auth settings
  void _configureAuth() {
    try {
      // Configure Auth settings for better security
      auth.setSettings(
        appVerificationDisabledForTesting: false,
      );
      
      debugPrint('Firebase Auth configured');
    } catch (e) {
      debugPrint('Firebase Auth configuration error: $e');
    }
  }

  /// Enable offline persistence manually (if not already enabled)
  Future<bool> enableOfflinePersistence() async {
    if (_isOfflineEnabled) return true;

    try {
      await firestore.enableNetwork();
      _isOfflineEnabled = true;
      debugPrint('Offline persistence enabled');
      return true;
    } catch (e) {
      debugPrint('Failed to enable offline persistence: $e');
      return false;
    }
  }

  /// Disable offline persistence (for testing or troubleshooting)
  Future<bool> disableOfflinePersistence() async {
    if (!_isOfflineEnabled) return true;

    try {
      await firestore.disableNetwork();
      _isOfflineEnabled = false;
      debugPrint('Offline persistence disabled');
      return true;
    } catch (e) {
      debugPrint('Failed to disable offline persistence: $e');
      return false;
    }
  }

  /// Clear offline cache (useful for troubleshooting)
  Future<bool> clearOfflineCache() async {
    try {
      await firestore.clearPersistence();
      debugPrint('Offline cache cleared');
      return true;
    } catch (e) {
      debugPrint('Failed to clear offline cache: $e');
      return false;
    }
  }

  /// Check Firebase services connectivity
  Future<Map<String, bool>> checkConnectivity() async {
    final results = <String, bool>{};

    // Check Auth
    try {
      await auth.signOut();
      results['auth'] = true;
    } catch (e) {
      results['auth'] = false;
    }

    // Check Firestore
    try {
      await firestore.collection('_test').limit(1).get();
      results['firestore'] = true;
    } catch (e) {
      results['firestore'] = false;
    }

    // Check Storage
    try {
      await storage.ref('_test').getMetadata();
      results['storage'] = true;
    } catch (e) {
      results['storage'] = false;
    }

    return results;
  }

  /// Get Firebase service status for debugging
  Map<String, dynamic> getServiceStatus() {
    return {
      'initialized': _isInitialized,
      'offlineEnabled': _isOfflineEnabled,
      'authUser': auth.currentUser?.uid,
      'projectId': firestore.app.options.projectId,
      'storageBucket': storage.bucket,
    };
  }

  /// Batch operation helper for Firestore
  WriteBatch createBatch() => firestore.batch();

  /// Transaction helper for Firestore
  Future<T> runTransaction<T>(
    TransactionHandler<T> updateFunction, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    return firestore.runTransaction(updateFunction, timeout: timeout);
  }

  /// Helper method to get a storage reference with user path
  Reference getUserStorageRef(String userId, String path) {
    return storage.ref().child('users').child(userId).child(path);
  }

  /// Helper method to get a media storage reference with user path (follows rules)
  Reference getMediaStorageRef(String userId, String path) {
    return storage.ref().child('media').child(userId).child(path);
  }

  /// Helper method to get a public storage reference
  Reference getPublicStorageRef(String path) {
    return storage.ref().child('public').child(path);
  }

  /// Get user storage path
  String getUserStoragePath(String fileName) {
    return 'users/${currentUserId}/$fileName';
  }

  /// Upload file to user's storage with progress tracking
  Future<String> uploadUserFile(
    String userId,
    String fileName,
    Uint8List data, {
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    if (!isUserAuthenticated || currentUserId != userId) {
      throw Exception('User not authenticated or userId mismatch');
    }

    try {
      // Use media storage path that matches security rules: /media/{userId}/...
      final ref = getMediaStorageRef(userId, fileName);
      
      final uploadTask = ref.putData(
        data,
        SettableMetadata(contentType: contentType),
      );

      // Track progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }, onError: (error) {
          debugPrint('Error in upload progress tracking: $error');
        });
      }

      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('File uploaded successfully: $fileName -> $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file $fileName: $e');
      rethrow;
    }
  }

  /// Download file from storage
  Future<Uint8List?> downloadFile(String path) async {
    try {
      final ref = storage.ref(path);
      return await ref.getData();
    } catch (e) {
      debugPrint('Failed to download file: $e');
      return null;
    }
  }

  /// Delete file from storage
  Future<bool> deleteFile(String path) async {
    try {
      await storage.ref(path).delete();
      return true;
    } catch (e) {
      debugPrint('Failed to delete file: $e');
      return false;
    }
  }

  /// Delete file from Firebase Storage using download URL
  Future<bool> deleteFileByUrl(String downloadUrl) async {
    try {
      final storagePath = _extractStoragePathFromUrl(downloadUrl);
      if (storagePath != null) {
        await storage.ref(storagePath).delete().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Timeout ao excluir arquivo do Storage');
          },
        );
        debugPrint('Successfully deleted file from Firebase Storage: $storagePath');
        return true;
      } else {
        debugPrint('Could not extract storage path from URL: $downloadUrl');
        return false;
      }
    } catch (e) {
      debugPrint('Failed to delete file by URL: $e');
      return false;
    }
  }

  /// Extract storage path from Firebase Storage download URL
  String? _extractStoragePathFromUrl(String downloadUrl) {
    try {
      if (!downloadUrl.contains('firebasestorage.googleapis.com')) {
        return null;
      }

      final uri = Uri.parse(downloadUrl);
      
      // Method 1: Standard Firebase Storage URL format: /v0/b/{bucket}/o/{encoded_path}
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 4 && pathSegments[2] == 'o') {
        final encodedPath = pathSegments[3];
        return Uri.decodeComponent(encodedPath);
      }
      
      // Method 2: Extract from URL using regex
      final regex = RegExp(r'/o/([^?]+)');
      final match = regex.firstMatch(downloadUrl);
      if (match != null) {
        return Uri.decodeComponent(match.group(1)!);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error extracting storage path from URL: $e');
      return null;
    }
  }

  /// Get file metadata
  Future<FullMetadata?> getFileMetadata(String path) async {
    try {
      return await storage.ref(path).getMetadata();
    } catch (e) {
      debugPrint('Failed to get file metadata: $e');
      return null;
    }
  }

  /// Cleanup resources (call on app shutdown)
  Future<void> cleanup() async {
    try {
      if (_isOfflineEnabled) {
        await firestore.disableNetwork();
      }
      await auth.signOut();
      debugPrint('Firebase resources cleaned up');
    } catch (e) {
      debugPrint('Error during Firebase cleanup: $e');
    }
  }

  // MEDIA MANAGEMENT METHODS

  /// Save media item to Firestore with retry logic
  Future<void> saveMediaItem(MediaItem mediaItem) async {
    const maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        if (!isUserAuthenticated) {
          throw Exception('User not authenticated');
        }

        final data = _mediaItemToMap(mediaItem);
        
        // Add upload timestamp and status
        data['uploadedAt'] = FieldValue.serverTimestamp();
        data['syncStatus'] = 'synced';
        
        await firestore
            .collection('users')
            .doc(currentUserId)
            .collection('media')
            .doc(mediaItem.id)
            .set(data, SetOptions(merge: true))
            .timeout(const Duration(seconds: 15));
        
        debugPrint('Successfully saved media item: ${mediaItem.id}');
        return;
      } catch (e) {
        retryCount++;
        debugPrint('Error saving media item (attempt $retryCount): $e');
        
        if (retryCount >= maxRetries) {
          debugPrint('Failed to save media item after $maxRetries attempts: ${mediaItem.id}');
          rethrow;
        }
        
        // Wait before retry with exponential backoff
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
  }

  /// Load all user media items from Firestore
  Future<List<MediaItem>> loadUserMediaItems() async {
    try {
      if (!isUserAuthenticated) {
        return [];
      }

      final snapshot = await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('media')
          .get();

      final items = <MediaItem>[];
      for (final doc in snapshot.docs) {
        try {
          final item = mapToMediaItem(doc.data());
          if (item != null) {
            items.add(item);
          }
        } catch (e) {
          debugPrint('Error parsing media item ${doc.id}: $e');
        }
      }

      debugPrint('Loaded ${items.length} media items from Firebase');
      return items;
    } catch (e) {
      debugPrint('Error loading media items: $e');
      return [];
    }
  }

  /// Delete media item from Firestore AND Firebase Storage
  Future<void> deleteMediaItem(String mediaItemId) async {
    try {
      if (!isUserAuthenticated) {
        throw Exception('User not authenticated');
      }

      // First, get the media item to extract the storage path
      final doc = await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('media')
          .doc(mediaItemId)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final sourcePath = data['sourcePath'] as String?;
          
          // If it's a Firebase Storage URL, delete the file
          if (sourcePath != null && sourcePath.contains('firebasestorage.googleapis.com')) {
            try {
              debugPrint('Attempting to delete file from Firebase Storage: $sourcePath');
              final deleted = await deleteFileByUrl(sourcePath);
              if (!deleted) {
                debugPrint('Warning: Could not delete file from Firebase Storage');
              }
            } catch (storageError) {
              debugPrint('Warning: Could not delete file from Firebase Storage: $storageError');
              // Continue with Firestore deletion even if Storage deletion fails
            }
          }
        }
      }

      // Delete the metadata from Firestore
      await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('media')
          .doc(mediaItemId)
          .delete();
      
      debugPrint('Deleted media item and associated files: $mediaItemId');
    } catch (e) {
      debugPrint('Error deleting media item: $e');
      rethrow;
    }
  }

  /// Upload media file to Firebase Storage and return download URL
  Future<String> uploadMediaFile(
    String fileName,
    Uint8List data, {
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (!isUserAuthenticated) {
        throw Exception('User not authenticated');
      }

      final path = 'media/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      return await uploadUserFile(
        currentUserId!,
        path,
        data,
        contentType: contentType,
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('Error uploading media file: $e');
      rethrow;
    }
  }

  // HELPER METHODS FOR DATA CONVERSION

  /// Convert MediaItem to Map for Firestore
  Map<String, dynamic> _mediaItemToMap(MediaItem item) {
    final baseData = {
      'id': item.id,
      'title': item.title,
      'description': item.description,
      'createdDate': item.createdDate,
      'lastModified': item.lastModified ?? item.createdDate,
      'sourceType': item.sourceType.name,
      'sourcePath': item.sourcePath,
      'type': item.type.name,
      'userId': currentUserId, // Add userId for security rules
    };

    // Add type-specific data with correct types
    if (item is AudioItem) {
      baseData.addAll({
        'format': item.format,
        'duration': item.duration?.inMilliseconds, // Store as int, not string
        'fileSize': item.fileSize, // Store as int, not string
        'bitrate': item.bitrate, // Store as int, not string
        'artist': item.artist,
        'album': item.album,
        'thumbnailUrl': item.thumbnailUrl,
      });
    } else if (item is VideoItem) {
      baseData.addAll({
        'format': item.format,
        'width': item.width, // Store as int, not string
        'height': item.height, // Store as int, not string
        'resolution': item.resolution,
        'duration': item.duration?.inMilliseconds, // Store as int, not string
        'fileSize': item.fileSize, // Store as int, not string
        'bitrate': item.bitrate, // Store as int, not string
        'frameRate': item.frameRate, // Store as double, not string
        'thumbnailUrl': item.thumbnailUrl,
      });
    } else if (item is ImageItem) {
      baseData.addAll({
        'format': item.format,
        'width': item.width, // Store as int, not string
        'height': item.height, // Store as int, not string
        'fileSize': item.fileSize, // Store as int, not string
        'thumbnailUrl': item.thumbnailUrl,
      });
    }

    return baseData;
  }

  /// Convert Map from Firestore to MediaItem
  MediaItem? mapToMediaItem(Map<String, dynamic> data) {
    try {
      final typeString = data['type'] as String;
      
      // Handle both string and Timestamp for createdDate
      final createdDate = _parseDateTime(data['createdDate']);
      final lastModified = _parseDateTime(data['lastModified']);
      
      final sourceType = MediaSourceType.values.firstWhere(
        (e) => e.name == data['sourceType'] || e.toString() == data['sourceType'],
        orElse: () => MediaSourceType.file,
      );

      if (typeString.contains('audio') || typeString == 'MediaContentType.audio') {
        return AudioItem(
          id: data['id'] as String,
          title: data['title'] as String,
          description: data['description'] as String?,
          createdDate: createdDate,
          lastModified: lastModified,
          sourceType: sourceType,
          sourcePath: data['sourcePath'] as String,
          category: data['category'] as String?,
          format: data['format'] as String?,
          duration: _parseDuration(data['duration']),
          fileSize: _parseInt(data['fileSize']),
          bitrate: _parseInt(data['bitrate']),
          artist: data['artist'] as String?,
          album: data['album'] as String?,
          thumbnailUrl: data['thumbnailUrl'] as String?,
        );
      } else if (typeString.contains('video') || typeString == 'MediaContentType.video') {
        return VideoItem(
          id: data['id'] as String,
          title: data['title'] as String,
          description: data['description'] as String?,
          createdDate: createdDate,
          lastModified: lastModified,
          sourceType: sourceType,
          sourcePath: data['sourcePath'] as String,
          category: data['category'] as String?,
          format: data['format'] as String?,
          width: _parseInt(data['width']),
          height: _parseInt(data['height']),
          resolution: data['resolution'] as String? ?? 'Desconhecida',
          duration: _parseDuration(data['duration']),
          fileSize: _parseInt(data['fileSize']),
          bitrate: _parseInt(data['bitrate']),
          frameRate: _parseDouble(data['frameRate']),
          thumbnailUrl: data['thumbnailUrl'] as String?,
        );
      } else if (typeString.contains('image') || typeString == 'MediaContentType.image') {
        return ImageItem(
          id: data['id'] as String,
          title: data['title'] as String,
          description: data['description'] as String?,
          createdDate: createdDate,
          lastModified: lastModified,
          sourceType: sourceType,
          sourcePath: data['sourcePath'] as String,
          category: data['category'] as String?,
          format: data['format'] as String?,
          width: _parseInt(data['width']),
          height: _parseInt(data['height']),
          fileSize: _parseInt(data['fileSize']),
          thumbnailUrl: data['thumbnailUrl'] as String?,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error converting map to MediaItem (${data['id'] ?? 'unknown'}): $e');
      debugPrint('Data: $data');
      return null;
    }
  }

  /// Helper method to parse DateTime from various formats
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('Error parsing date string: $value');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Helper method to parse Duration from various formats
  Duration? _parseDuration(dynamic value) {
    if (value == null) return null;
    if (value is int) return Duration(milliseconds: value);
    if (value is String) {
      try {
        final int? ms = int.tryParse(value);
        return ms != null ? Duration(milliseconds: ms) : null;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Helper method to parse int from various formats
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is double) return value.toInt();
    return null;
  }

  /// Helper method to parse double from various formats
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

/// Extension methods for common Firebase operations
extension FirebaseManagerExtensions on FirebaseManager {
  /// Quick method to check if user is authenticated
  bool get isUserAuthenticated => auth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => auth.currentUser?.uid;

  /// Get current user email
  String? get currentUserEmail => auth.currentUser?.email;

  /// Get current user display name
  String? get currentUserDisplayName => auth.currentUser?.displayName;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Stream of user changes (including profile updates)
  Stream<User?> get userChanges => auth.userChanges();

  /// Quick method to get user's Firestore document reference
  DocumentReference? get currentUserDoc {
    final userId = currentUserId;
    if (userId == null) return null;
    return firestore.collection('users').doc(userId);
  }
}

/// Utility class for Firebase error handling
class FirebaseErrorHandler {
  static String getReadableError(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error.code);
    } else if (error is FirebaseException) {
      return _getFirestoreErrorMessage(error.code);
    } else {
      return error.toString();
    }
  }

  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-disabled':
        return 'Esta conta foi desabilitada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'requires-recent-login':
        return 'Esta operação requer um login recente.';
      default:
        return 'Erro de autenticação: $code';
    }
  }

  static String _getFirestoreErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Acesso negado. Verifique suas permissões.';
      case 'unavailable':
        return 'Serviço temporariamente indisponível.';
      case 'deadline-exceeded':
        return 'Tempo limite excedido. Tente novamente.';
      case 'not-found':
        return 'Documento não encontrado.';
      case 'already-exists':
        return 'Documento já existe.';
      default:
        return 'Erro no banco de dados: $code';
    }
  }
}