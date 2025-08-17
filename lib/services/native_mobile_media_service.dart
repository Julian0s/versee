import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:versee/models/media_models.dart';
import 'package:versee/services/auth_service.dart';
import 'package:versee/services/firebase_manager.dart';
import 'package:versee/services/permission_service.dart';
import 'package:versee/services/compression_service.dart';

/// Serviço nativo robusto para upload de mídia em Android/iOS
/// Arquitetura simplificada e focada em mobile
class NativeMobileMediaService extends ChangeNotifier {
  final FirebaseManager _firebaseManager = FirebaseManager();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Upload state
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _currentFileName = '';
  int _totalFiles = 0;
  int _processedFiles = 0;
  
  // Getters
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get currentFileName => _currentFileName;
  int get totalFiles => _totalFiles;
  int get processedFiles => _processedFiles;
  
  /// Upload de arquivos de áudio
  Future<List<AudioItem>> uploadAudioFiles() async {
    return await _uploadFilesWithThumbnail<AudioItem>(
      MediaType.audio,
      ['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'],
      _createAudioItem,
    );
  }
  
  /// Upload de arquivos de vídeo
  Future<List<VideoItem>> uploadVideoFiles() async {
    return await _uploadFilesWithThumbnail<VideoItem>(
      MediaType.video,
      ['mp4', 'avi', 'mov', 'mkv', 'webm', 'm4v'],
      _createVideoItem,
    );
  }
  
  /// Upload de arquivos de imagem
  Future<List<ImageItem>> uploadImageFiles() async {
    return await _uploadFilesWithThumbnail<ImageItem>(
      MediaType.image,
      ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
      _createImageItem,
    );
  }
  
  /// Método genérico para upload de arquivos com suporte a thumbnail
  Future<List<T>> _uploadFilesWithThumbnail<T extends MediaItem>(
    MediaType type,
    List<String> extensions,
    T Function(String id, String title, String downloadUrl, int fileSize, String format, [String? thumbnailUrl]) itemCreator,
  ) async {
    try {
      debugPrint('🚀 Iniciando upload de ${type.name}...');
      
      // 1. Verificar permissões
      final hasPermission = await PermissionService.requestMediaPermission(type);
      if (!hasPermission) {
        throw Exception('Permissão negada para acessar ${type.name}');
      }
      
      // 2. Verificar autenticação
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // 3. Abrir file picker
      final files = await _pickFiles(extensions);
      if (files.isEmpty) {
        throw Exception('Nenhum arquivo selecionado');
      }
      
      // 4. Inicializar estado de upload
      _initializeUploadState(files.length);
      
      // 5. Processar arquivos
      final List<T> uploadedItems = [];
      
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        try {
          _updateProgress(i, file.name);
          
          // Ler arquivo como bytes
          final bytes = await _readFileBytes(file);
          
          // Comprimir se necessário
          final compressedBytes = await _compressFile(bytes, type, file.extension ?? '');
          
          // Upload para Firebase
          final downloadUrl = await _uploadToFirebase(
            compressedBytes,
            type,
            user.uid,
            file.name,
          );
          
          // Gerar thumbnail se necessário
          String? thumbnailUrl;
          if (type == MediaType.image) {
            // Gerar thumbnail otimizada para imagens
            thumbnailUrl = await _generateImageThumbnail(
              compressedBytes,
              user.uid,
              file.name,
            );
            // Se falhar, usar a própria imagem
            thumbnailUrl ??= downloadUrl;
          } else if (type == MediaType.video) {
            // TODO: Implementar geração de thumbnail para vídeos
            thumbnailUrl = null;
          }
          
          // Criar item de mídia
          final item = itemCreator(
            _generateId(),
            _getFileNameWithoutExtension(file.name),
            downloadUrl,
            compressedBytes.length,
            file.extension?.replaceFirst('.', '') ?? '',
            thumbnailUrl,
          );
          
          // Salvar no Firestore
          await _firebaseManager.saveMediaItem(item);
          
          uploadedItems.add(item);
          debugPrint('✅ Upload concluído: ${file.name}');
          
        } catch (e) {
          debugPrint('❌ Erro no upload de ${file.name}: $e');
          // Continua com próximo arquivo
        }
      }
      
      _completeUpload();
      
      debugPrint('🎉 Upload finalizado: ${uploadedItems.length}/${files.length} arquivos');
      return uploadedItems;
      
    } catch (e) {
      _resetUploadState();
      debugPrint('💥 Erro no upload: $e');
      rethrow;
    }
  }
  
  /// Abrir file picker nativo
  Future<List<PlatformFile>> _pickFiles(List<String> extensions) async {
    debugPrint('📁 Abrindo file picker...');
    debugPrint('📁 Extensões permitidas: $extensions');
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        allowMultiple: true,
        withData: false, // Não precisamos dos bytes aqui
      );
      
      debugPrint('📁 Resultado do file picker: ${result != null ? 'sucesso' : 'cancelado'}');
      
      if (result == null || result.files.isEmpty) {
        debugPrint('📁 Nenhum arquivo selecionado ou picker cancelado');
        return [];
      }
      
      debugPrint('📁 Total de arquivos retornados: ${result.files.length}');
      
      // Filtrar apenas arquivos com path válido
      final validFiles = result.files.where((file) => file.path != null).toList();
      final invalidFiles = result.files.where((file) => file.path == null).toList();
      
      if (invalidFiles.isNotEmpty) {
        debugPrint('⚠️ ${invalidFiles.length} arquivos sem path válido foram ignorados');
        for (final file in invalidFiles) {
          debugPrint('⚠️ Arquivo inválido: ${file.name}');
        }
      }
      
      debugPrint('📁 ${validFiles.length} arquivos válidos selecionados:');
      for (final file in validFiles) {
        debugPrint('📁 - ${file.name} (${file.size} bytes) - ${file.path}');
      }
      
      return validFiles;
      
    } catch (e) {
      debugPrint('❌ Erro ao abrir file picker: $e');
      rethrow;
    }
  }
  
  /// Ler arquivo como bytes
  Future<Uint8List> _readFileBytes(PlatformFile file) async {
    if (file.path == null) {
      throw Exception('Caminho do arquivo inválido');
    }
    
    final ioFile = File(file.path!);
    if (!await ioFile.exists()) {
      throw Exception('Arquivo não encontrado: ${file.path}');
    }
    
    return await ioFile.readAsBytes();
  }
  
  /// Comprimir arquivo baseado no tipo
  Future<Uint8List> _compressFile(Uint8List bytes, MediaType type, String extension) async {
    return await CompressionService.compressFile(bytes, type, extension);
  }
  
  /// Gerar thumbnail para imagem
  Future<String?> _generateImageThumbnail(
    Uint8List imageBytes,
    String userId,
    String fileName,
  ) async {
    try {
      debugPrint('🖼️ Gerando thumbnail para imagem...');
      
      // Comprimir imagem para thumbnail (max 400x400, qualidade 70%)
      final thumbnailBytes = await CompressionService.generateThumbnail(imageBytes);
      
      if (thumbnailBytes == null) {
        debugPrint('⚠️ Não foi possível gerar thumbnail');
        return null;
      }
      
      // Upload da thumbnail para Firebase
      final sanitizedFileName = _sanitizeFileName(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final thumbnailPath = 'users/$userId/thumbnails/${timestamp}_thumb_$sanitizedFileName';
      
      debugPrint('📁 Upload thumbnail path: $thumbnailPath');
      final ref = _storage.ref().child(thumbnailPath);
      
      final uploadTask = ref.putData(
        thumbnailBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'isThumbnail': 'true'},
        ),
      );
      
      final snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        final thumbnailUrl = await ref.getDownloadURL();
        debugPrint('✅ Thumbnail criada: $thumbnailUrl');
        return thumbnailUrl;
      }
      
      return null;
      
    } catch (e) {
      debugPrint('❌ Erro ao gerar thumbnail: $e');
      return null;
    }
  }
  
  /// Upload para Firebase Storage
  Future<String> _uploadToFirebase(
    Uint8List bytes,
    MediaType type,
    String userId,
    String fileName,
  ) async {
    debugPrint('☁️ Fazendo upload para Firebase...');
    
    final sanitizedFileName = _sanitizeFileName(fileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = 'users/$userId/${type.name}/${timestamp}_$sanitizedFileName';
    
    debugPrint('📁 Upload path: $filePath');
    final ref = _storage.ref().child(filePath);
    
    // Upload com retry
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(
            contentType: _getContentType(type, path.extension(fileName)),
          ),
        );
        
        // Monitor progress
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          _updateUploadProgress(progress);
        });
        
        final snapshot = await uploadTask;
        
        if (snapshot.state == TaskState.success) {
          final downloadUrl = await ref.getDownloadURL();
          debugPrint('✅ Upload Firebase concluído: $downloadUrl');
          return downloadUrl;
        } else {
          throw Exception('Upload falhou: ${snapshot.state}');
        }
        
      } catch (e) {
        retryCount++;
        debugPrint('⚠️ Tentativa $retryCount falhou: $e');
        
        if (retryCount >= maxRetries) {
          throw Exception('Upload falhou após $maxRetries tentativas: $e');
        }
        
        // Aguardar antes de tentar novamente
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
    
    throw Exception('Upload falhou após todas as tentativas');
  }
  
  /// Criar AudioItem
  AudioItem _createAudioItem(String id, String title, String downloadUrl, int fileSize, String format, [String? thumbnailUrl]) {
    return AudioItem(
      id: id,
      title: title,
      description: 'Áudio importado em ${_formatDate(DateTime.now())}',
      createdDate: DateTime.now(),
      lastModified: DateTime.now(),
      sourceType: MediaSourceType.url,
      sourcePath: downloadUrl,
      category: null,
      format: format.toUpperCase(),
      duration: null, // TODO: Extrair duração
      fileSize: fileSize,
      bitrate: null,
      artist: null,
      album: null,
      thumbnailUrl: thumbnailUrl, // Usar thumbnail se fornecida
    );
  }
  
  /// Criar VideoItem
  VideoItem _createVideoItem(String id, String title, String downloadUrl, int fileSize, String format, [String? thumbnailUrl]) {
    return VideoItem(
      id: id,
      title: title,
      description: 'Vídeo importado em ${_formatDate(DateTime.now())}',
      createdDate: DateTime.now(),
      lastModified: DateTime.now(),
      sourceType: MediaSourceType.url,
      sourcePath: downloadUrl,
      category: null,
      format: format.toUpperCase(),
      duration: null, // TODO: Extrair duração
      width: null, // TODO: Extrair dimensões
      height: null,
      resolution: null,
      frameRate: null,
      fileSize: fileSize,
      bitrate: null,
      thumbnailUrl: thumbnailUrl, // Usar thumbnail se fornecida
    );
  }
  
  /// Criar ImageItem
  ImageItem _createImageItem(String id, String title, String downloadUrl, int fileSize, String format, [String? thumbnailUrl]) {
    return ImageItem(
      id: id,
      title: title,
      description: 'Imagem importada em ${_formatDate(DateTime.now())}',
      createdDate: DateTime.now(),
      lastModified: DateTime.now(),
      sourceType: MediaSourceType.url,
      sourcePath: downloadUrl,
      category: null,
      format: format.toUpperCase(),
      width: null, // TODO: Extrair dimensões
      height: null,
      resolution: null,
      fileSize: fileSize,
      thumbnailUrl: thumbnailUrl ?? downloadUrl, // Para imagens, usar a própria URL como thumbnail
    );
  }
  
  // UTILITY METHODS
  
  void _initializeUploadState(int totalFiles) {
    _isUploading = true;
    _totalFiles = totalFiles;
    _processedFiles = 0;
    _uploadProgress = 0.0;
    _currentFileName = '';
    notifyListeners();
  }
  
  void _updateProgress(int fileIndex, String fileName) {
    _processedFiles = fileIndex;
    _currentFileName = fileName;
    _uploadProgress = 0.0;
    notifyListeners();
  }
  
  void _updateUploadProgress(double progress) {
    _uploadProgress = progress;
    notifyListeners();
  }
  
  void _completeUpload() {
    _isUploading = false;
    _uploadProgress = 1.0;
    notifyListeners();
  }
  
  void _resetUploadState() {
    _isUploading = false;
    _uploadProgress = 0.0;
    _currentFileName = '';
    _totalFiles = 0;
    _processedFiles = 0;
    notifyListeners();
  }
  
  String _generateId() {
    return 'media_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
  
  String _getFileNameWithoutExtension(String fileName) {
    return path.basenameWithoutExtension(fileName);
  }
  
  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  String _getContentType(MediaType type, String extension) {
    switch (type) {
      case MediaType.audio:
        switch (extension.toLowerCase()) {
          case '.mp3': return 'audio/mpeg';
          case '.wav': return 'audio/wav';
          case '.aac': return 'audio/aac';
          case '.m4a': return 'audio/mp4';
          case '.ogg': return 'audio/ogg';
          case '.flac': return 'audio/flac';
          default: return 'audio/mpeg';
        }
      case MediaType.video:
        switch (extension.toLowerCase()) {
          case '.mp4': return 'video/mp4';
          case '.mov': return 'video/quicktime';
          case '.avi': return 'video/x-msvideo';
          case '.mkv': return 'video/x-matroska';
          case '.webm': return 'video/webm';
          default: return 'video/mp4';
        }
      case MediaType.image:
        switch (extension.toLowerCase()) {
          case '.jpg':
          case '.jpeg': return 'image/jpeg';
          case '.png': return 'image/png';
          case '.gif': return 'image/gif';
          case '.webp': return 'image/webp';
          case '.bmp': return 'image/bmp';
          default: return 'image/jpeg';
        }
    }
  }
}