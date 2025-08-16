import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/services/local_media_cache_service.dart';
import 'package:versee/services/smart_media_compressor.dart';
import 'package:versee/services/auth_service.dart';
import 'package:versee/services/firebase_manager.dart';

// Platform-specific imports for mobile

/// Serviço híbrido que combina cache local + sincronização com Firebase
/// Estratégia: Local primeiro, sincronização em background
class HybridMediaService extends ChangeNotifier {
  final LocalMediaCacheService _cacheService = LocalMediaCacheService();
  final FirebaseManager _firebaseManager = FirebaseManager();
  final AuthService _authService = AuthService();
  
  final List<MediaItem> _mediaItems = [];
  bool _isInitialized = false;
  bool _isSyncing = false;
  
  // Getters
  List<MediaItem> get allItems => List.unmodifiable(_mediaItems);
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  
  List<AudioItem> get audioItems => _mediaItems.whereType<AudioItem>().toList();
  List<VideoItem> get videoItems => _mediaItems.whereType<VideoItem>().toList();
  List<ImageItem> get imageItems => _mediaItems.whereType<ImageItem>().toList();
  
  /// Inicializa o serviço híbrido
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🚀 Inicializando HybridMediaService...');
      
      // Inicializar cache local
      await _cacheService.initialize();
      
      // Registrar Service Worker se ainda não registrado
      await _registerServiceWorker();
      
      // Carregar mídia local primeiro (resposta rápida)
      await _loadLocalMedia();
      
      // Sincronizar com Firebase em background
      _syncWithFirebaseInBackground();
      
      _isInitialized = true;
      notifyListeners();
      
      print('✅ HybridMediaService inicializado');
      
    } catch (e) {
      print('❌ Erro ao inicializar HybridMediaService: $e');
      throw Exception('Falha na inicialização: $e');
    }
  }
  
  /// Adiciona novo item de mídia com cache otimizado
  Future<void> addMediaItem(MediaItem item, Uint8List? fileData) async {
    try {
      print('📥 Adicionando mídia: ${item.title}');
      
      // Adicionar à lista local imediatamente
      _mediaItems.add(item);
      notifyListeners();
      
      if (fileData != null) {
        // Processar em background
        _processAndCacheMediaInBackground(item, fileData);
      }
      
    } catch (e) {
      print('❌ Erro ao adicionar mídia: $e');
      throw Exception('Falha ao adicionar mídia: $e');
    }
  }
  
  /// Upload de arquivo com compressão multi-nível e cache
  Future<MediaItem?> uploadMediaFile(dynamic file) async {
    try {
      print('📤 Fazendo upload de: ${file.name}');
      
      // Ler dados do arquivo
      final fileData = await _readFileAsBytes(file);
      
      // Determinar tipo de mídia
      final mediaType = _getMediaTypeFromFile(file);
      
      // Gerar ID único
      final mediaId = _generateMediaId();
      
      // Compressão multi-nível imediata (para cache local rápido)
      final compressionResult = await _compressMediaMultiLevel(fileData, file.name, mediaType);
      
      // Criar item de mídia temporário com dados locais
      final mediaItem = _createMediaItemFromFile(file, mediaId, mediaType);
      
      // Salvar no cache local imediatamente
      await _cacheService.cacheMedia(
        mediaItem,
        compressionResult.thumbnailData,
      );
      
      // Adicionar à lista local
      _mediaItems.add(mediaItem);
      notifyListeners();
      
      // Upload para Firebase em background
      _uploadToFirebaseInBackground(mediaItem, compressionResult);
      
      print('✅ Mídia ${file.name} processada e cacheada localmente');
      return mediaItem;
      
    } catch (e) {
      print('❌ Erro no upload: $e');
      return null;
    }
  }
  
  /// Obtém dados de mídia com fallback inteligente
  Future<Uint8List?> getMediaData(String mediaId, {CompressionLevel level = CompressionLevel.compressed}) async {
    try {
      // 1. Tentar cache local primeiro (MUITO RÁPIDO)
      Uint8List? localData;
      
      switch (level) {
        case CompressionLevel.thumbnail:
          localData = await _cacheService.getThumbnail(mediaId);
          break;
        case CompressionLevel.preview:
        case CompressionLevel.compressed:
          localData = await _cacheService.getCompressedMedia(mediaId);
          break;
        case CompressionLevel.original:
          // Original media not supported in stub
          localData = null;
          break;
      }
      
      if (localData != null) {
        print('⚡ Mídia servida do cache local: $mediaId (${level.name})');
        return localData;
      }
      
      // 2. Se não tiver local, baixar do Firebase e cachear
      print('📥 Baixando mídia do Firebase: $mediaId');
      final firebaseData = await _downloadFromFirebase(mediaId, level);
      
      if (firebaseData != null) {
        // Cachear para próximas vezes
        await _cacheMediaFromFirebase(mediaId, firebaseData, level);
        print('💾 Mídia baixada e cacheada: $mediaId');
        return firebaseData;
      }
      
      print('❌ Mídia não encontrada: $mediaId');
      return null;
      
    } catch (e) {
      print('❌ Erro ao obter mídia: $e');
      return null;
    }
  }
  
  /// Cria URL blob otimizada para playback
  Future<String?> getOptimizedMediaUrl(String mediaId, {CompressionLevel level = CompressionLevel.compressed}) async {
    try {
      final mediaData = await getMediaData(mediaId, level: level);
      if (mediaData == null) return null;
      
      // Criar blob URL para playback
      final mediaItem = _mediaItems.firstWhere((item) => item.id == mediaId);
      final mimeType = _getMimeTypeForMedia(mediaItem);
      
      // Blob and URL creation not supported on mobile
      final blobUrl = null;
      
      print('🔗 URL blob criada para: $mediaId');
      return blobUrl;
      
    } catch (e) {
      print('❌ Erro ao criar URL: $e');
      return null;
    }
  }
  
  /// Remove mídia do cache e Firebase
  Future<void> removeMediaItem(String mediaId) async {
    try {
      // Remover da lista local
      _mediaItems.removeWhere((item) => item.id == mediaId);
      notifyListeners();
      
      // Remover do cache local
      await _cacheService.removeFromCache(mediaId);
      
      // Remover do Firebase em background
      _removeFromFirebaseInBackground(mediaId);
      
      print('🗑️ Mídia removida: $mediaId');
      
    } catch (e) {
      print('❌ Erro ao remover mídia: $e');
    }
  }
  
  /// Força sincronização com Firebase
  Future<void> syncWithFirebase() async {
    if (_isSyncing) return;
    
    try {
      _isSyncing = true;
      notifyListeners();
      
      print('🔄 Iniciando sincronização com Firebase...');
      
      if (_authService.isAuthenticated) {
        // Sincronizar metadados
        await _syncMetadataWithFirebase();
        
        // Sincronizar arquivos pendentes
        await _syncPendingUploads();
        
        print('✅ Sincronização concluída');
      } else {
        print('⚠️ Usuário não autenticado - pulando sincronização');
      }
      
    } catch (e) {
      print('❌ Erro na sincronização: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  /// Obtém informações sobre cache e uso de armazenamento
  Future<MediaStorageInfo> getStorageInfo() async {
    try {
      final cacheInfo = await _cacheService.getCacheInfo();
      
      // Calcular estatísticas por tipo
      final audioCount = audioItems.length;
      final videoCount = videoItems.length;
      final imageCount = imageItems.length;
      
      return MediaStorageInfo(
        localCacheSize: cacheInfo['totalSize'] ?? 0,
        localItemCount: cacheInfo['totalItems'] ?? 0,
        totalItemCount: _mediaItems.length,
        audioCount: audioCount,
        videoCount: videoCount,
        imageCount: imageCount,
        storageQuota: 0,
        cacheHitRate: _calculateCacheHitRate(),
      );
      
    } catch (e) {
      print('❌ Erro ao obter informações de armazenamento: $e');
      return MediaStorageInfo.empty();
    }
  }
  
  /// Limpa cache local
  Future<void> clearLocalCache() async {
    try {
      await _cacheService.clearAllCache();
      print('🧹 Cache local limpo');
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao limpar cache: $e');
    }
  }
  
  // MÉTODOS AUXILIARES
  
  /// Registra Service Worker para cache avançado (stub para mobile)
  Future<void> _registerServiceWorker() async {
    if (kIsWeb) {
      try {
        // Service worker registration commented out for mobile compatibility
        // await html.window.navigator.serviceWorker!.register('/sw_media_cache.js');
        print('✅ Service Worker registration skipped on mobile');
      } catch (e) {
        print('⚠️ Erro ao registrar Service Worker: $e');
      }
    }
  }
  
  /// Carrega mídia do cache local
  Future<void> _loadLocalMedia() async {
    try {
      // Por enquanto, lista vazia - em implementação real, carregaria do IndexedDB
      print('📁 Mídia local carregada: ${_mediaItems.length} itens');
    } catch (e) {
      print('❌ Erro ao carregar mídia local: $e');
    }
  }
  
  /// Sincroniza com Firebase em background
  void _syncWithFirebaseInBackground() {
    Timer(const Duration(seconds: 2), () {
      syncWithFirebase().catchError((e) {
        print('⚠️ Erro na sincronização em background: $e');
      });
    });
  }
  
  /// Processa e cacheia mídia em background
  void _processAndCacheMediaInBackground(MediaItem item, Uint8List fileData) {
    Timer(const Duration(milliseconds: 100), () async {
      try {
        final compressionResult = await _compressMediaMultiLevel(
          fileData, 
          item.title, 
          item.type
        );
        
        await _cacheService.cacheMedia(
          item,
          compressionResult.thumbnailData,
        );
        
        print('✅ Mídia processada em background: ${item.title}');
      } catch (e) {
        print('❌ Erro no processamento em background: $e');
      }
    });
  }
  
  /// Upload para Firebase em background
  void _uploadToFirebaseInBackground(MediaItem item, MultiLevelMediaResult compressionResult) {
    Timer(const Duration(seconds: 1), () async {
      try {
        if (_authService.isAuthenticated && compressionResult.originalData != null) {
          // Upload da versão original para Firebase Storage
          final downloadUrl = await _uploadToFirebaseStorage(
            item.id, 
            compressionResult.originalData!, 
            item.title
          );
          
          // Atualizar item com URL do Firebase
          final updatedItem = _updateItemWithFirebaseUrl(item, downloadUrl);
          
          // Salvar metadados no Firestore
          await _firebaseManager.saveMediaItem(updatedItem);
          
          print('☁️ Upload para Firebase concluído: ${item.title}');
        }
      } catch (e) {
        print('❌ Erro no upload para Firebase: $e');
      }
    });
  }
  
  /// Comprime mídia em múltiplos níveis
  Future<MultiLevelMediaResult> _compressMediaMultiLevel(
    Uint8List fileData, 
    String fileName, 
    MediaContentType mediaType
  ) async {
    switch (mediaType) {
      case MediaContentType.image:
        return await SmartMediaCompressor.compressImageMultiLevel(fileData, fileName);
      case MediaContentType.audio:
        return await SmartMediaCompressor.compressAudioMultiLevel(fileData, fileName);
      case MediaContentType.video:
        return await SmartMediaCompressor.compressVideoMultiLevel(fileData, fileName);
      default:
        throw Exception('Tipo de mídia não suportado: $mediaType');
    }
  }
  
  /// Lê arquivo como bytes (stub para mobile)
  Future<Uint8List> _readFileAsBytes(dynamic file) async {
    // Stub para mobile - retorna bytes vazios
    return Uint8List(0);
  }
  
  /// Determina tipo de mídia do arquivo
  MediaContentType _getMediaTypeFromFile(dynamic file) {
    final extension = file.name.split('.').last.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return MediaContentType.image;
    } else if (['mp3', 'wav', 'ogg', 'm4a', 'aac'].contains(extension)) {
      return MediaContentType.audio;
    } else if (['mp4', 'webm', 'mov', 'avi'].contains(extension)) {
      return MediaContentType.video;
    }
    
    return MediaContentType.image; // Fallback
  }
  
  /// Cria item de mídia a partir do arquivo
  MediaItem _createMediaItemFromFile(dynamic file, String mediaId, MediaContentType mediaType) {
    final now = DateTime.now();
    
    switch (mediaType) {
      case MediaContentType.audio:
        return AudioItem(
          id: mediaId,
          title: _getFileNameWithoutExtension(file.name),
          description: 'Áudio importado',
          createdDate: now,
          lastModified: now,
          sourceType: MediaSourceType.local,
          sourcePath: 'local://$mediaId',
          fileSize: file.size,
          format: file.name.split('.').last.toLowerCase(),
        );
        
      case MediaContentType.video:
        return VideoItem(
          id: mediaId,
          title: _getFileNameWithoutExtension(file.name),
          description: 'Vídeo importado',
          createdDate: now,
          lastModified: now,
          sourceType: MediaSourceType.local,
          sourcePath: 'local://$mediaId',
          fileSize: file.size,
          format: file.name.split('.').last.toLowerCase(),
        );
        
      case MediaContentType.image:
        return ImageItem(
          id: mediaId,
          title: _getFileNameWithoutExtension(file.name),
          description: 'Imagem importada',
          createdDate: now,
          lastModified: now,
          sourceType: MediaSourceType.local,
          sourcePath: 'local://$mediaId',
          fileSize: file.size,
          format: file.name.split('.').last.toLowerCase(),
        );
        
      default:
        throw Exception('Tipo de mídia não suportado');
    }
  }
  
  String _getFileNameWithoutExtension(String fileName) {
    return fileName.split('.').first;
  }
  
  String _generateMediaId() {
    return 'media_${DateTime.now().millisecondsSinceEpoch}_${(1000 + DateTime.now().microsecond % 9000)}';
  }
  
  String _getMimeTypeForMedia(MediaItem item) {
    switch (item.type) {
      case MediaContentType.audio:
        return 'audio/${(item as AudioItem).format}';
      case MediaContentType.video:
        return 'video/${(item as VideoItem).format}';
      case MediaContentType.image:
        return 'image/${(item as ImageItem).format}';
      default:
        return 'application/octet-stream';
    }
  }
  
  // Métodos placeholder para implementação futura
  Future<Uint8List?> _downloadFromFirebase(String mediaId, CompressionLevel level) async {
    // TODO: Implementar download do Firebase Storage
    return null;
  }
  
  Future<void> _cacheMediaFromFirebase(String mediaId, Uint8List data, CompressionLevel level) async {
    // TODO: Implementar cache de dados baixados do Firebase
  }
  
  Future<String> _uploadToFirebaseStorage(String mediaId, Uint8List data, String fileName) async {
    // TODO: Implementar upload para Firebase Storage
    return 'https://example.com/placeholder';
  }
  
  MediaItem _updateItemWithFirebaseUrl(MediaItem item, String downloadUrl) {
    // TODO: Implementar atualização do item com URL do Firebase
    return item;
  }
  
  void _removeFromFirebaseInBackground(String mediaId) {
    // TODO: Implementar remoção do Firebase
  }
  
  Future<void> _syncMetadataWithFirebase() async {
    // TODO: Implementar sincronização de metadados
  }
  
  Future<void> _syncPendingUploads() async {
    // TODO: Implementar sincronização de uploads pendentes
  }
  
  double _calculateCacheHitRate() {
    // TODO: Implementar cálculo de taxa de acerto do cache
    return 0.0;
  }
}

/// Informações sobre uso de armazenamento de mídia
class MediaStorageInfo {
  final int localCacheSize;
  final int localItemCount;
  final int totalItemCount;
  final int audioCount;
  final int videoCount;
  final int imageCount;
  final int storageQuota;
  final double cacheHitRate;
  
  const MediaStorageInfo({
    required this.localCacheSize,
    required this.localItemCount,
    required this.totalItemCount,
    required this.audioCount,
    required this.videoCount,
    required this.imageCount,
    required this.storageQuota,
    required this.cacheHitRate,
  });
  
  factory MediaStorageInfo.empty() => const MediaStorageInfo(
    localCacheSize: 0,
    localItemCount: 0,
    totalItemCount: 0,
    audioCount: 0,
    videoCount: 0,
    imageCount: 0,
    storageQuota: 0,
    cacheHitRate: 0.0,
  );
  
  double get cacheUsagePercentage {
    if (storageQuota == 0) return 0.0;
    return (localCacheSize / storageQuota) * 100;
  }
  
  String get formattedCacheSize {
    if (localCacheSize < 1024) return '${localCacheSize}B';
    if (localCacheSize < 1024 * 1024) return '${(localCacheSize / 1024).toStringAsFixed(1)}KB';
    if (localCacheSize < 1024 * 1024 * 1024) return '${(localCacheSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(localCacheSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}