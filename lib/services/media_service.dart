import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/services/file_manager_service.dart';
import 'package:versee/services/firebase_manager.dart';
import 'package:versee/services/auth_service.dart';
import 'package:versee/services/native_mobile_media_service.dart';
// Platform abstraction imports
import 'package:versee/platform/platform.dart';
import 'package:versee/providers/riverpod_providers.dart';

// Platform-specific imports with conditional compilation
import 'dart:io' as io if (dart.library.io) 'dart:io';

// Instância global para bridge híbrida
MediaService? _globalMediaService;

class MediaService extends ChangeNotifier {
  final List<MediaItem> _mediaItems = [];
  final List<MediaCollection> _collections = [];
  final FileManagerService _fileManager = FileManagerService();
  final FirebaseManager _firebaseManager = FirebaseManager();
  final NativeMobileMediaService _nativeMediaService = NativeMobileMediaService();
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // Real-time sync variables
  StreamSubscription<QuerySnapshot>? _mediaStreamSubscription;
  bool _isListeningToChanges = false;

  // Getters
  List<MediaItem> get allItems => List.unmodifiable(_mediaItems);
  List<MediaCollection> get collections => List.unmodifiable(_collections);
  
  List<AudioItem> get audioItems => _mediaItems.whereType<AudioItem>().toList();
  List<VideoItem> get videoItems => _mediaItems.whereType<VideoItem>().toList();
  List<ImageItem> get imageItems => _mediaItems.whereType<ImageItem>().toList();

  // Constructor - initialize and load persisted data
  MediaService() {
    _globalMediaService = this;
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    try {
      await _loadPersistedMediaItems();
      await _startRealtimeSync();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing MediaService: $e');
    }
  }


  void _initializeSampleData() {
    // No longer adding sample data by default
    // This keeps the app clean for real usage
    notifyListeners();
  }

  // Media Management Methods
  void addMediaItem(MediaItem item) {
    debugPrint('Adicionando media item: ${item.title} (${item.id})');
    _mediaItems.add(item);
    // Persist to Firebase asynchronously
    _persistMediaItems([item]).catchError((e) => debugPrint('Error persisting single item: $e'));
    notifyListeners();
  }

  void removeMediaItem(String id) {
    _mediaItems.removeWhere((item) => item.id == id);
    // Remove from Firebase asynchronously
    _removeFromFirebase(id).catchError((e) => debugPrint('Error removing item from Firebase: $e'));
    notifyListeners();
  }

  Future<void> _removeFromFirebase(String itemId) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        await _firebaseManager.deleteMediaItem(itemId);
      }
    } catch (e) {
      debugPrint('Error removing item from Firebase: $e');
    }
  }

  void updateMediaItem(MediaItem updatedItem) {
    final index = _mediaItems.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _mediaItems[index] = updatedItem;
      notifyListeners();
    }
  }

  MediaItem? getMediaItemById(String id) {
    return _mediaItems.where((item) => item.id == id).firstOrNull;
  }

  /// Valida todos os itens de mídia e remove os que têm fontes inválidas
  Future<int> validateAndCleanupInvalidItems() async {
    debugPrint('Iniciando validação de itens de mídia...');
    final invalidItems = <MediaItem>[];
    
    for (final item in _mediaItems) {
      final isValid = await _validateMediaItem(item);
      if (!isValid) {
        debugPrint('Item inválido encontrado: ${item.title} - ${item.sourcePath}');
        invalidItems.add(item);
      }
    }
    
    // Remover itens inválidos
    for (final invalidItem in invalidItems) {
      _mediaItems.removeWhere((item) => item.id == invalidItem.id);
      // Remover do Firebase também
      _removeFromFirebase(invalidItem.id).catchError((e) => 
        debugPrint('Erro ao remover item inválido do Firebase: $e'));
    }
    
    if (invalidItems.isNotEmpty) {
      debugPrint('Removidos ${invalidItems.length} itens inválidos');
      notifyListeners();
    }
    
    return invalidItems.length;
  }

  /// Valida se um item de mídia tem uma fonte válida e acessível
  Future<bool> _validateMediaItem(MediaItem item) async {
    try {
      final sourcePath = item.sourcePath.trim();
      
      if (sourcePath.isEmpty) {
        return false;
      }
      
      if (item.sourceType == MediaSourceType.url) {
        // Validar URL
        final uri = Uri.tryParse(sourcePath);
        if (uri == null || (!uri.hasScheme) || 
            (uri.scheme != 'http' && uri.scheme != 'https' && uri.scheme != 'blob')) {
          return false;
        }
        
        // Para URLs HTTP/HTTPS, fazer uma verificação básica de conectividade
        if (uri.scheme == 'http' || uri.scheme == 'https') {
          try {
            // Timeout curto para não travar a interface
            if (kIsWeb) {
              // Web platform HTTP check - temporariamente desabilitado
              if (item.type == MediaContentType.audio) {
                return _isWebAudioFormatSupported(sourcePath, null);
              }
              return true; // Assume success for web
            } else {
              // Mobile platform HTTP check  
              final httpClient = io.HttpClient();
              final response = await httpClient.headUrl(uri)
                .timeout(const Duration(seconds: 5));
              final httpResponse = await response.close();
              return httpResponse.statusCode == 200;
            }
          } catch (e) {
            debugPrint('URL inacessível: $sourcePath - $e');
            return false;
          }
        }
        
        return true; // URLs blob são assumidas como válidas
      } else {
        // Validar arquivo local
        final file = io.File(sourcePath);
        return await file.exists();
      }
    } catch (e) {
      debugPrint('Erro ao validar item ${item.title}: $e');
      return false;
    }
  }

  /// Check if audio format is supported on web
  bool _isWebAudioFormatSupported(String url, String? contentType) {
    // Web browsers have limited audio format support
    final supportedFormats = {
      'audio/mpeg', // MP3
      'audio/mp4',  // M4A, AAC
      'audio/ogg',  // OGG Vorbis
      'audio/wav',  // WAV (limited)
      'audio/webm', // WebM Audio
    };

    // Check content type
    if (contentType != null && supportedFormats.contains(contentType.toLowerCase())) {
      return true;
    }

    // Check URL extension
    final urlLower = url.toLowerCase();
    if (urlLower.contains('.mp3') || urlLower.contains('audio%2Fmpeg')) return true;
    if (urlLower.contains('.m4a') || urlLower.contains('audio%2Fmp4')) return true;
    if (urlLower.contains('.ogg') || urlLower.contains('audio%2Fogg')) return true;
    if (urlLower.contains('.webm') || urlLower.contains('audio%2Fwebm')) return true;

    // Warn about potentially unsupported formats
    if (urlLower.contains('.flac') || urlLower.contains('.wav') || urlLower.contains('.aac')) {
      debugPrint('Warning: Format may have limited web browser support: $url');
      return true; // Still try to play, but warn
    }

    return true; // Default to allowing, let the player handle the error
  }

  List<MediaItem> getMediaItemsByType(MediaContentType type) {
    return _mediaItems.where((item) => item.type == type).toList();
  }

  List<MediaItem> searchMediaItems(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _mediaItems.where((item) {
      return item.title.toLowerCase().contains(lowercaseQuery) ||
             (item.description?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Collection Management Methods
  void createCollection(String title, List<MediaItem> items, {String? description}) {
    final collection = MediaCollection(
      id: 'collection_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      items: items,
      createdDate: DateTime.now(),
    );
    _collections.add(collection);
    notifyListeners();
  }

  void removeCollection(String id) {
    _collections.removeWhere((collection) => collection.id == id);
    notifyListeners();
  }

  void updateCollection(MediaCollection updatedCollection) {
    final index = _collections.indexWhere((collection) => collection.id == updatedCollection.id);
    if (index != -1) {
      _collections[index] = updatedCollection;
      notifyListeners();
    }
  }

  MediaCollection? getCollectionById(String id) {
    return _collections.where((collection) => collection.id == id).firstOrNull;
  }

  // Statistics and utility methods
  int get totalMediaCount => _mediaItems.length;
  int get audioCount => audioItems.length;
  int get videoCount => videoItems.length;
  int get imageCount => imageItems.length;
  
  Duration get totalAudioDuration {
    return audioItems.fold(Duration.zero, (total, item) {
      return total + (item.duration ?? Duration.zero);
    });
  }

  Duration get totalVideoDuration {
    return videoItems.fold(Duration.zero, (total, item) {
      return total + (item.duration ?? Duration.zero);
    });
  }

  // Utility method to get items sorted by creation date
  List<MediaItem> getRecentItems({int limit = 10}) {
    final sortedItems = List<MediaItem>.from(_mediaItems);
    sortedItems.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return sortedItems.take(limit).toList();
  }

  // File import methods - MOBILE ONLY
  Future<List<AudioItem>> importAudioFiles() async {
    try {
      debugPrint('🎵 Iniciando importação de arquivos de áudio...');
      
      // Usar o novo serviço nativo
      final uploadedItems = await _nativeMediaService.uploadAudioFiles();
      
      debugPrint('🎵 ${uploadedItems.length} arquivos processados com sucesso');
      
      // Add to local list and force UI update
      for (final item in uploadedItems) {
        addMediaItem(item);
      }
      
      // Force refresh from Firebase to ensure sync
      await Future.delayed(const Duration(milliseconds: 500));
      await refreshFromFirebase();
      
      return uploadedItems;
    } catch (e) {
      debugPrint('❌ Erro na importação de áudio: $e');
      rethrow;
    }
  }

  Future<List<VideoItem>> importVideoFiles() async {
    try {
      debugPrint('🎥 Iniciando importação de arquivos de vídeo...');
      
      // Usar o novo serviço nativo
      final uploadedItems = await _nativeMediaService.uploadVideoFiles();
      
      debugPrint('🎥 ${uploadedItems.length} arquivos processados com sucesso');
      
      // Add to local list and force UI update
      for (final item in uploadedItems) {
        addMediaItem(item);
      }
      
      // Force refresh from Firebase to ensure sync
      await Future.delayed(const Duration(milliseconds: 500));
      await refreshFromFirebase();
      
      return uploadedItems;
    } catch (e) {
      debugPrint('❌ Erro na importação de vídeo: $e');
      rethrow;
    }
  }

  Future<List<ImageItem>> importImageFiles() async {
    try {
      debugPrint('🖼️ Iniciando importação de imagens...');
      
      // Usar o novo serviço nativo
      final uploadedItems = await _nativeMediaService.uploadImageFiles();
      
      debugPrint('🖼️ ${uploadedItems.length} imagens processadas com sucesso');
      
      // Add to local list and force UI update
      for (final item in uploadedItems) {
        addMediaItem(item);
      }
      
      // Force refresh from Firebase to ensure sync
      await Future.delayed(const Duration(milliseconds: 500));
      await refreshFromFirebase();
      
      return uploadedItems;
    } catch (e) {
      debugPrint('❌ Erro na importação de imagem: $e');
      rethrow;
    }
  }

  // Get native media service for direct access
  NativeMobileMediaService get nativeMediaService => _nativeMediaService;

  // Storage management simplified for mobile-only architecture
  
  // Get storage information (compatibility method)
  Future<Map<String, dynamic>> getStorageInfo() async {
    // Simplified storage info for mobile
    int totalSize = 0;
    int audioFiles = 0;
    int videoFiles = 0;
    int imageFiles = 0;
    int audioSize = 0;
    int videoSize = 0;
    int imageSize = 0;
    
    for (final item in _mediaItems) {
      switch (item.type) {
        case MediaContentType.audio:
          audioFiles++;
          audioSize += (item as AudioItem).fileSize ?? 0;
          break;
        case MediaContentType.video:
          videoFiles++;
          videoSize += (item as VideoItem).fileSize ?? 0;
          break;
        case MediaContentType.image:
          imageFiles++;
          imageSize += (item as ImageItem).fileSize ?? 0;
          break;
      }
    }
    
    totalSize = audioSize + videoSize + imageSize;
    
    return {
      'totalSize': totalSize,
      'audioSize': audioSize,
      'videoSize': videoSize,
      'imageSize': imageSize,
      'audioFiles': audioFiles,
      'videoFiles': videoFiles,
      'imageFiles': imageFiles,
    };
  }

  // Clear all data (for testing or reset)
  void clearAllData() {
    _mediaItems.clear();
    _collections.clear();
    notifyListeners();
  }
  
  // Force UI update (useful after background operations)
  void forceNotifyListeners() {
    notifyListeners();
  }
  
  // MOBILE-ONLY SERVICE - Upload gerenciado pelo NativeMobileMediaService
  
  // Check if media items are being persisted to Firebase
  bool get isUploadingToFirebase => _nativeMediaService.isUploading;
  
  // Upload progress getters
  double get uploadProgress => _nativeMediaService.uploadProgress;
  String get currentUploadFile => _nativeMediaService.currentFileName;
  int get totalUploadFiles => _nativeMediaService.totalFiles;
  int get processedUploadFiles => _nativeMediaService.processedFiles;

  // Reset to sample data
  void resetToSampleData() {
    clearAllData();
    _initializeSampleData();
  }

  // PERSISTENCE METHODS

  // Upload files to Firebase Storage and persist metadata
  Future<void> _uploadAndPersistMediaItems(List<MediaItem> items) async {
    try {
      final results = await _uploadAndSaveMediaItems(items);
      final successCount = results.where((r) => r).length;
      
      // Remove failed items from local list
      final failedIndices = <int>[];
      for (int i = 0; i < results.length; i++) {
        if (!results[i]) {
          final itemId = items[i].id;
          final index = _mediaItems.indexWhere((item) => item.id == itemId);
          if (index != -1) {
            failedIndices.add(index);
          }
        }
      }
      
      // Remove failed items in reverse order to maintain indices
      failedIndices.sort((a, b) => b.compareTo(a));
      for (final index in failedIndices) {
        _mediaItems.removeAt(index);
      }
      
      // Force UI update to reflect changes
      notifyListeners();
    } catch (e) {
      // Remove all items that failed to upload
      for (final item in items) {
        _mediaItems.removeWhere((localItem) => localItem.id == item.id);
      }
      notifyListeners();
    }
  }

  // Persist media items to Firebase asynchronously (non-blocking) - DEPRECATED

  // Persist media items to Firebase
  Future<List<bool>> _persistMediaItems(List<MediaItem> items) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        return List.filled(items.length, false);
      }

      // Process items in smaller batches to avoid Firebase limits
      const batchSize = 3; // Reduced batch size for better reliability
      final results = <bool>[];
      
      for (int i = 0; i < items.length; i += batchSize) {
        final end = (i + batchSize < items.length) ? i + batchSize : items.length;
        final batch = items.sublist(i, end);
        
        final batchResults = await Future.wait(
          batch.map((item) => _persistSingleItemWithRetry(item)),
          eagerError: false, // Continue even if some fail
        );
        
        results.addAll(batchResults);
        
        // Small delay between batches to avoid overwhelming Firebase
        if (end < items.length) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      final successCount = results.where((success) => success).length;
      
      // Force a UI update to show the latest state
      notifyListeners();
      
      return results;
    } catch (e) {
      // Return all false to indicate failures
      return List.filled(items.length, false);
    }
  }
  
  // Persist a single media item with retry logic
  Future<bool> _persistSingleItemWithRetry(MediaItem item) async {
    const maxRetries = 3;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _firebaseManager.saveMediaItem(item);
        return true;
      } catch (e) {
        
        if (attempt < maxRetries) {
          // Wait before retrying with exponential backoff
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    
    return false;
  }
  
  // Persist a single media item with better error handling (legacy method)

  // Load persisted media items from Firebase
  Future<void> _loadPersistedMediaItems() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        return;
      }

      final persistedItems = await _firebaseManager.loadUserMediaItems();
      
      if (persistedItems.isEmpty) {
        return;
      }
      
      // Remove duplicates by ID before adding
      final existingIds = _mediaItems.map((item) => item.id).toSet();
      final newItems = persistedItems.where((item) => !existingIds.contains(item.id)).toList();
      
      _mediaItems.addAll(newItems);
      
      
      // Notify listeners if new items were added
      if (newItems.isNotEmpty) {
        notifyListeners();
      }
    } catch (e) {
      // Don't rethrow - app should still work without Firebase data
    }
  }

  // Sync local items with Firebase
  Future<void> syncWithFirebase() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        return;
      }

      // Load latest from Firebase
      final firebaseItems = await _firebaseManager.loadUserMediaItems();
      
      // Merge with local items (prefer local if conflicts)
      final localIds = _mediaItems.map((item) => item.id).toSet();
      final newFirebaseItems = firebaseItems.where((item) => !localIds.contains(item.id)).toList();
      
      _mediaItems.addAll(newFirebaseItems);
      
      // Save any local items not in Firebase
      final firebaseIds = firebaseItems.map((item) => item.id).toSet();
      final localOnlyItems = _mediaItems.where((item) => !firebaseIds.contains(item.id)).toList();
      
      for (final item in localOnlyItems) {
        await _firebaseManager.saveMediaItem(item);
      }
      
      notifyListeners();
    } catch (e) {
    }
  }

  // Force refresh from Firebase
  Future<void> refreshFromFirebase() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        return;
      }

      // Store local items temporarily to avoid losing recent uploads
      final localItems = List<MediaItem>.from(_mediaItems);
      _mediaItems.clear();
      
      // Load from Firebase
      final firebaseItems = await _firebaseManager.loadUserMediaItems();
      _mediaItems.addAll(firebaseItems);
      
      // Re-add any local items that might not be in Firebase yet
      final firebaseIds = firebaseItems.map((item) => item.id).toSet();
      final localOnlyItems = localItems.where((item) => !firebaseIds.contains(item.id)).toList();
      _mediaItems.addAll(localOnlyItems);
      
      notifyListeners();
      
    } catch (e) {
    }
  }
  
  // Force a complete sync - useful for debugging
  Future<void> forceSyncAll() async {
    try {
      
      // First, try to load from Firebase
      await _loadPersistedMediaItems();
      
      // Then, sync any local items to Firebase
      final allItems = List<MediaItem>.from(_mediaItems);
      if (allItems.isNotEmpty) {
        await _persistMediaItems(allItems);
      }
      
      // Finally, refresh from Firebase to ensure consistency
      await refreshFromFirebase();
      
      
    } catch (e) {
    }
  }

  // NEW METHOD: Upload media files to Firebase Storage and save metadata
  Future<List<bool>> _uploadAndSaveMediaItems(List<MediaItem> items) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        return List.filled(items.length, false);
      }

      final results = <bool>[];
      
      for (final item in items) {
        try {
          // Upload file to Firebase Storage if it's a local file
          String finalSourcePath = item.sourcePath;
          
          if (item.sourceType == MediaSourceType.file) {
            // For mobile/desktop files, upload to Firebase Storage
            final file = io.File(item.sourcePath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final fileName = '${item.type.name}/${item.id}_${path.basename(item.sourcePath)}';
              
              finalSourcePath = await _firebaseManager.uploadUserFile(
                user.uid,
                fileName,
                bytes,
                contentType: _getContentType(item),
              );
            }
          } else if (item.sourceType == MediaSourceType.url && item.sourcePath.startsWith('blob:')) {
            // For web blob files, get the bytes and upload to Firebase Storage
            final bytes = await _getBlobBytes(item.sourcePath);
            if (bytes != null) {
              final fileName = '${item.type.name}/${item.id}_${item.title}.${_getFileExtension(item)}';
              
              finalSourcePath = await _firebaseManager.uploadUserFile(
                user.uid,
                fileName,
                bytes,
                contentType: _getContentType(item),
              );
            }
          }
          
          // Update item with Firebase Storage URL
          final updatedItem = _updateItemSourcePath(item, finalSourcePath, MediaSourceType.url);
          
          // Update in local list
          final index = _mediaItems.indexWhere((localItem) => localItem.id == item.id);
          if (index != -1) {
            _mediaItems[index] = updatedItem;
          }
          
          // Save metadata to Firestore
          await _firebaseManager.saveMediaItem(updatedItem);
          results.add(true);
          
        } catch (e) {
          results.add(false);
        }
      }
      
      return results;
    } catch (e) {
      return List.filled(items.length, false);
    }
  }

  // Helper method to get content type based on media item
  String _getContentType(MediaItem item) {
    switch (item.type) {
      case MediaContentType.audio:
        final format = (item is AudioItem) ? item.format?.toLowerCase() : null;
        switch (format) {
          case 'mp3': return 'audio/mpeg';
          case 'wav': return 'audio/wav';
          case 'aac': return 'audio/aac';
          case 'm4a': return 'audio/mp4';
          case 'ogg': return 'audio/ogg';
          case 'flac': return 'audio/flac';
          default: return 'audio/mpeg';
        }
      case MediaContentType.video:
        final format = (item is VideoItem) ? item.format?.toLowerCase() : null;
        switch (format) {
          case 'mp4': return 'video/mp4';
          case 'avi': return 'video/x-msvideo';
          case 'mov': return 'video/quicktime';
          case 'mkv': return 'video/x-matroska';
          case 'webm': return 'video/webm';
          default: return 'video/mp4';
        }
      case MediaContentType.image:
        final format = (item is ImageItem) ? item.format?.toLowerCase() : null;
        switch (format) {
          case 'jpg':
          case 'jpeg': return 'image/jpeg';
          case 'png': return 'image/png';
          case 'gif': return 'image/gif';
          case 'webp': return 'image/webp';
          case 'bmp': return 'image/bmp';
          default: return 'image/jpeg';
        }
    }
  }

  // Helper method to get file extension
  String _getFileExtension(MediaItem item) {
    if (item is AudioItem && item.format != null) {
      return item.format!.toLowerCase();
    } else if (item is VideoItem && item.format != null) {
      return item.format!.toLowerCase();
    } else if (item is ImageItem && item.format != null) {
      return item.format!.toLowerCase();
    }
    
    switch (item.type) {
      case MediaContentType.audio: return 'mp3';
      case MediaContentType.video: return 'mp4';
      case MediaContentType.image: return 'jpg';
    }
  }

  // Helper method to get bytes from blob URL (web only)
  Future<Uint8List?> _getBlobBytes(String blobUrl) async {
    try {
      if (kIsWeb && blobUrl.startsWith('blob:')) {
        // Web-only blob handling would go here
        return null;
      }
    } catch (e) {
      debugPrint('Error getting blob bytes: $e');
    }
    return null;
  }

  // Helper method to update item source path
  MediaItem _updateItemSourcePath(MediaItem item, String newSourcePath, MediaSourceType newSourceType) {
    if (item is AudioItem) {
      return AudioItem(
        id: item.id,
        title: item.title,
        description: item.description,
        createdDate: item.createdDate,
        lastModified: DateTime.now(),
        sourceType: newSourceType,
        sourcePath: newSourcePath,
        category: item.category,
        format: item.format,
        duration: item.duration,
        fileSize: item.fileSize,
        bitrate: item.bitrate,
        artist: item.artist,
        album: item.album,
        thumbnailUrl: item.thumbnailUrl,
      );
    } else if (item is VideoItem) {
      return VideoItem(
        id: item.id,
        title: item.title,
        description: item.description,
        createdDate: item.createdDate,
        lastModified: DateTime.now(),
        sourceType: newSourceType,
        sourcePath: newSourcePath,
        category: item.category,
        format: item.format,
        width: item.width,
        height: item.height,
        resolution: item.resolution,
        duration: item.duration,
        fileSize: item.fileSize,
        bitrate: item.bitrate,
        frameRate: item.frameRate,
        thumbnailUrl: item.thumbnailUrl,
      );
    } else if (item is ImageItem) {
      return ImageItem(
        id: item.id,
        title: item.title,
        description: item.description,
        createdDate: item.createdDate,
        lastModified: DateTime.now(),
        sourceType: newSourceType,
        sourcePath: newSourcePath,
        category: item.category,
        format: item.format,
        width: item.width,
        height: item.height,
        fileSize: item.fileSize,
        thumbnailUrl: item.thumbnailUrl,
      );
    }
    return item;
  }

  // REAL-TIME SYNC METHODS

  /// Start real-time synchronization with Firebase
  Future<void> _startRealtimeSync() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        return;
      }

      if (_isListeningToChanges) {
        return;
      }

      
      _mediaStreamSubscription = _firebaseManager.firestore
          .collection('users')
          .doc(user.uid)
          .collection('media')
          .snapshots()
          .listen(
            _handleFirebaseSnapshot,
            onError: (error) {
              debugPrint('Error in real-time media sync: $error');
              // Try to restart sync after delay
              Future.delayed(const Duration(seconds: 10), () {
                if (!_isListeningToChanges) {
                  _startRealtimeSync();
                }
              });
            },
          );

      _isListeningToChanges = true;
      debugPrint('Real-time sync started successfully');
    } catch (e) {
      debugPrint('Error starting real-time sync: $e');
    }
  }

  /// Handle Firebase snapshot changes
  void _handleFirebaseSnapshot(QuerySnapshot snapshot) {
    try {
      debugPrint('Processing Firebase snapshot with ${snapshot.docs.length} documents');
      
      // Get all current Firebase IDs
      final firebaseIds = snapshot.docs.map((doc) => doc.id).toSet();
      final localIds = _mediaItems.map((item) => item.id).toSet();
      
      // Find items deleted from Firebase
      final deletedIds = localIds.difference(firebaseIds);
      bool hasChanges = false;
      
      // Remove deleted items from local list
      for (final deletedId in deletedIds) {
        final removedCount = _mediaItems.where((item) => item.id == deletedId).length;
        if (removedCount > 0) {
          _mediaItems.removeWhere((item) => item.id == deletedId);
          debugPrint('Item deleted from Firebase, removed locally: $deletedId');
          hasChanges = true;
        }
      }
      
      // Process document changes
      for (final change in snapshot.docChanges) {
        final doc = change.doc;
        final data = doc.data() as Map<String, dynamic>?;
        
        if (data == null) continue;
        
        switch (change.type) {
          case DocumentChangeType.added:
            if (_handleItemAdded(data)) hasChanges = true;
            break;
          case DocumentChangeType.modified:
            if (_handleItemModified(data)) hasChanges = true;
            break;
          case DocumentChangeType.removed:
            if (_handleItemRemoved(doc.id)) hasChanges = true;
            break;
        }
      }
      
      if (hasChanges) {
        notifyListeners();
      }
    } catch (e) {
    }
  }

  /// Handle item added from Firebase
  bool _handleItemAdded(Map<String, dynamic> data) {
    try {
      final item = _firebaseManager.mapToMediaItem(data);
      if (item != null && !_mediaItems.any((existing) => existing.id == item.id)) {
        _mediaItems.add(item);
        return true;
      }
    } catch (e) {
    }
    return false;
  }

  /// Handle item modified from Firebase
  bool _handleItemModified(Map<String, dynamic> data) {
    try {
      final item = _firebaseManager.mapToMediaItem(data);
      if (item != null) {
        final index = _mediaItems.indexWhere((existing) => existing.id == item.id);
        if (index != -1) {
          _mediaItems[index] = item;
          return true;
        } else {
          // Item doesn't exist locally, add it
          _mediaItems.add(item);
          return true;
        }
      }
    } catch (e) {
    }
    return false;
  }

  /// Handle item removed from Firebase
  bool _handleItemRemoved(String itemId) {
    try {
      final initialLength = _mediaItems.length;
      _mediaItems.removeWhere((item) => item.id == itemId);
      if (_mediaItems.length < initialLength) {
        return true;
      }
    } catch (e) {
    }
    return false;
  }

  /// Stop real-time synchronization
  void _stopRealtimeSync() {
    if (_mediaStreamSubscription != null) {
      _mediaStreamSubscription!.cancel();
      _mediaStreamSubscription = null;
      _isListeningToChanges = false;
    }
  }

  /// Restart real-time synchronization (useful after auth changes)
  Future<void> restartRealtimeSync() async {
    _stopRealtimeSync();
    await _startRealtimeSync();
  }


  /// Delete a media item completely (local and Firebase)
  Future<bool> deleteMediaItem(String id) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        return false;
      }

      // Get the item before deletion to access sourcePath
      final item = getMediaItemById(id);
      
      // Remove from Firestore first with timeout
      await _firebaseManager.deleteMediaItem(id).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout');
        },
      );
      
      // Delete the file from Firebase Storage if it exists
      if (item != null && item.sourcePath.isNotEmpty) {
        try {
          // Check if sourcePath is a Firebase Storage URL
          if (item.sourcePath.startsWith('https://firebasestorage.googleapis.com') ||
              item.sourcePath.startsWith('gs://')) {
            await FirebaseStorage.instance.refFromURL(item.sourcePath).delete().timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw Exception('File deletion timeout');
              },
            );
          }
        } catch (e) {
          // Continue with item deletion even if file deletion fails
        }
      }
      
      // Remove from local list
      final initialLength = _mediaItems.length;
      _mediaItems.removeWhere((item) => item.id == id);
      
      if (_mediaItems.length < initialLength) {
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Update media item title
  Future<bool> updateMediaItemTitle(String id, String newTitle) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        return false;
      }

      final index = _mediaItems.indexWhere((item) => item.id == id);
      if (index == -1) {
        return false;
      }

      final item = _mediaItems[index];
      final updatedItem = _createUpdatedItem(item, newTitle);
      
      // Update in Firebase
      await _firebaseManager.saveMediaItem(updatedItem);
      
      // Update locally
      _mediaItems[index] = updatedItem;
      notifyListeners();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMediaItemCategory(String id, String? newCategory) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        return false;
      }

      final index = _mediaItems.indexWhere((item) => item.id == id);
      if (index == -1) {
        return false;
      }

      final item = _mediaItems[index];
      final updatedItem = _createUpdatedItemWithCategory(item, newCategory);
      
      // Update in Firebase
      await _firebaseManager.saveMediaItem(updatedItem);
      
      // Update locally
      _mediaItems[index] = updatedItem;
      notifyListeners();
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Helper method to create updated item with new title
  MediaItem _createUpdatedItem(MediaItem item, String newTitle) {
    if (item is AudioItem) {
      return AudioItem(
        id: item.id,
        title: newTitle,
        description: item.description,
        createdDate: item.createdDate,
        lastModified: DateTime.now(),
        sourceType: item.sourceType,
        sourcePath: item.sourcePath,
        category: item.category,
        format: item.format,
        duration: item.duration,
        fileSize: item.fileSize,
        bitrate: item.bitrate,
        artist: item.artist,
        album: item.album,
        thumbnailUrl: item.thumbnailUrl,
      );
    } else if (item is VideoItem) {
      return VideoItem(
        id: item.id,
        title: newTitle,
        description: item.description,
        createdDate: item.createdDate,
        lastModified: DateTime.now(),
        sourceType: item.sourceType,
        sourcePath: item.sourcePath,
        category: item.category,
        format: item.format,
        width: item.width,
        height: item.height,
        resolution: item.resolution,
        duration: item.duration,
        fileSize: item.fileSize,
        bitrate: item.bitrate,
        frameRate: item.frameRate,
        thumbnailUrl: item.thumbnailUrl,
      );
    } else if (item is ImageItem) {
      return ImageItem(
        id: item.id,
        title: newTitle,
        description: item.description,
        createdDate: item.createdDate,
        lastModified: DateTime.now(),
        sourceType: item.sourceType,
        sourcePath: item.sourcePath,
        category: item.category,
        format: item.format,
        width: item.width,
        height: item.height,
        fileSize: item.fileSize,
        thumbnailUrl: item.thumbnailUrl,
      );
    }
    return item;
  }

  /// Helper method to create updated item with new category
  MediaItem _createUpdatedItemWithCategory(MediaItem item, String? newCategory) {
    // Normalizar categoria: string vazia ou null vira null
    final normalizedCategory = (newCategory == null || newCategory.isEmpty) ? null : newCategory;
    
    if (item is AudioItem) {
      return item.copyWith(
        category: normalizedCategory,
        lastModified: DateTime.now(),
      );
    } else if (item is VideoItem) {
      return item.copyWith(
        category: normalizedCategory,
        lastModified: DateTime.now(),
      );
    } else if (item is ImageItem) {
      return item.copyWith(
        category: normalizedCategory,
        lastModified: DateTime.now(),
      );
    }
    return item;
  }

  // Getter estático para acesso global
  static MediaService? get globalInstance => _globalMediaService;
  
  // Método de sincronização com Riverpod
  void syncWithRiverpod(MediaState state) {
    bool hasChanged = false;
    
    if (_mediaItems.length != state.mediaItems.length ||
        _collections.length != state.collections.length ||
        _isInitialized != state.isInitialized) {
      
      _mediaItems.clear();
      _mediaItems.addAll(state.mediaItems);
      _collections.clear();
      _collections.addAll(state.collections);
      _isInitialized = state.isInitialized;
      
      hasChanged = true;
    }
    
    if (hasChanged) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopRealtimeSync();
    
    if (_globalMediaService == this) {
      _globalMediaService = null;
    }
    
    super.dispose();
  }
}