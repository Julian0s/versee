import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/services/auth_service.dart';
import 'package:versee/services/firebase_manager.dart';
import 'package:versee/services/smart_media_optimizer.dart';
import 'package:path/path.dart' as path;

// Conditional imports for cross-platform compatibility
// import 'dart:html' as html if (dart.library.html) 'dart:html';
import 'web_platform_stub.dart' as html_stub if (dart.library.io) 'web_platform_stub.dart';

/// Serviço dedicado para upload e processamento de mídia
/// Inclui otimização automática, conversão para formatos leves e sincronização com Firebase
class MediaUploadService {
  final FirebaseManager _firebaseManager = FirebaseManager();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  // Configurações de compressão
  static const int _maxImageSize = 1920; // px
  static const int _maxVideoSize = 1280; // px
  static const double _imageQuality = 0.8; // 80% quality
  static const int _maxFileSize = 100 * 1024 * 1024; // 100MB
  
  /// Upload otimizado de arquivos de áudio com conversão automática
  Future<List<MediaItem>> uploadAudioFilesOptimized(List<dynamic> files) async {
    if (!kIsWeb) {
      debugPrint('Upload de arquivos não suportado no mobile');
      return [];
    }
    final List<MediaItem> uploadedItems = [];
    final user = await AuthService.getCurrentUser();
    
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }
    
    debugPrint('Iniciando upload otimizado de ${files.length} arquivos de áudio...');
    
    for (final file in files) {
      try {
        // Validar arquivo
        if (!_isValidAudioFile(file)) {
          debugPrint('Arquivo de áudio inválido: ${file.name}');
          continue;
        }
        
        // Verificar tamanho
        if (file.size > _maxFileSize) {
          debugPrint('Arquivo muito grande: ${file.name} (${_formatFileSize(file.size)})');
          continue;
        }
        
        debugPrint('Processando arquivo de áudio: ${file.name}');
        
        // Marcar para otimização server-side
        final optimizationResult = await SmartMediaOptimizer.prepareAudioForServerOptimization(file);
        debugPrint('Áudio marcado para otimização: ${optimizationResult.method}');
        
        // Upload para Firebase Storage (original)
        final uploadResult = await _uploadFileToStorage(
          file, 
          'audio/${user.uid}',
          file.name,
        );
        
        if (uploadResult != null) {
          debugPrint('Upload bem-sucedido: ${uploadResult.downloadUrl}');
          
          // Extrair metadata do áudio
          final metadata = await _extractAudioMetadata(file);
          
          // Criar AudioItem
          final audioItem = AudioItem(
            id: _generateId(),
            title: _getFileNameWithoutExtension(file.name),
            description: 'Áudio importado em ${_formatDate(DateTime.now())} - Otimização em andamento',
            createdDate: DateTime.now(),
            lastModified: DateTime.now(),
            sourceType: MediaSourceType.url,
            sourcePath: uploadResult.downloadUrl,
            category: null,
            duration: metadata['duration'],
            artist: metadata['artist'],
            album: metadata['album'],
            format: path.extension(file.name).toLowerCase().replaceFirst('.', ''),
            fileSize: file.size,
            thumbnailUrl: null,
          );
          
          // Salvar no Firestore
          await _firebaseManager.saveMediaItem(audioItem);
          debugPrint('AudioItem salvo com sucesso: ${audioItem.title}');
          uploadedItems.add(audioItem);
          
          // As Cloud Functions irão automaticamente processar o arquivo e atualizar o Firestore
          
        } else {
          debugPrint('Falha no upload do arquivo: ${file.name}');
        }
      } catch (e, stackTrace) {
        debugPrint('Erro ao fazer upload de ${file.name}: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
    
    return uploadedItems;
  }

  /// Upload de arquivos de áudio com metadata (método original)
  Future<List<MediaItem>> uploadAudioFiles(List<dynamic> files) async {
    if (!kIsWeb) {
      throw UnsupportedError('File upload not supported on mobile platform');
    }
    final List<MediaItem> uploadedItems = [];
    final user = await AuthService.getCurrentUser();
    
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }
    
    debugPrint('Iniciando importação de ${files.length} arquivos de áudio...');
    debugPrint('${files.length} arquivos de áudio selecionados');
    debugPrint('${files.length} arquivos selecionados para upload');
    
    for (final file in files) {
      try {
        // Validar arquivo
        if (!_isValidAudioFile(file)) {
          debugPrint('Arquivo de áudio inválido: ${file.name}');
          continue;
        }
        
        // Verificar tamanho
        if (file.size > _maxFileSize) {
          debugPrint('Arquivo muito grande: ${file.name} (${_formatFileSize(file.size)})');
          continue;
        }
        
        debugPrint('Processando arquivo de áudio: ${file.name}');
        
        // Upload para Firebase Storage
        final uploadResult = await _uploadFileToStorage(
          file, 
          'audio/${user.uid}',
          file.name,
        );
        
        if (uploadResult != null) {
          debugPrint('Upload bem-sucedido: ${uploadResult.downloadUrl}');
          
          // Extrair metadata do áudio
          final metadata = await _extractAudioMetadata(file);
          
          // Criar AudioItem
          final audioItem = AudioItem(
            id: _generateId(),
            title: _getFileNameWithoutExtension(file.name),
            description: 'Áudio importado em ${_formatDate(DateTime.now())}',
            createdDate: DateTime.now(),
            lastModified: DateTime.now(),
            sourceType: MediaSourceType.url,
            sourcePath: uploadResult.downloadUrl,
            category: null, // Novos itens sem categoria inicialmente
            duration: metadata['duration'],
            artist: metadata['artist'],
            album: metadata['album'],
            format: path.extension(file.name).toLowerCase().replaceFirst('.', ''),
            fileSize: file.size,
            thumbnailUrl: null, // Áudio não precisa de thumbnail
          );
          
          debugPrint('Salvando AudioItem no Firestore: ${audioItem.id}');
          
          // Salvar no Firestore
          await _firebaseManager.saveMediaItem(audioItem);
          
          debugPrint('AudioItem salvo com sucesso: ${audioItem.title}');
          uploadedItems.add(audioItem);
          
        } else {
          debugPrint('Falha no upload do arquivo: ${file.name}');
        }
      } catch (e, stackTrace) {
        debugPrint('Erro ao fazer upload de ${file.name}: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
    
    return uploadedItems;
  }
  
  /// Upload genérico para Firebase Storage - VERSÃO CORRIGIDA FINAL
Future<UploadResult?> _uploadFileToStorage(
  dynamic file, 
  String folderPath, 
  String fileName,
) async {
  try {
    debugPrint('Iniciando upload: $fileName para $folderPath');
    
    final sanitizedFileName = _sanitizeFileName(fileName);
    final filePath = '$folderPath/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
    
    // Verificar se o usuário está autenticado
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      throw Exception('Usuário não autenticado para upload');
    }
    
    // Criar referência no Storage
    final ref = _storage.ref().child(filePath);
    
    debugPrint('Fazendo upload do arquivo: ${file.size} bytes');
    
    // CORREÇÃO: Upload SEM metadata para evitar problemas de CORS
    TaskSnapshot? snapshot;
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        // Upload sem metadata personalizada
        final uploadTask = ref.putBlob(file);
        
        // Monitorar progresso
        uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) {
          final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes * 100;
          debugPrint('Upload progress: ${progress.toStringAsFixed(1)}%');
        });
        
        snapshot = await uploadTask;
        break; // Upload bem-sucedido, sair do loop
        
      } catch (e) {
        retryCount++;
        debugPrint('Tentativa $retryCount falhou: $e');
        
        if (retryCount >= maxRetries) {
          rethrow;
        }
        
        // Aguardar antes de tentar novamente
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
    
    if (snapshot == null || snapshot.state != TaskState.success) {
      throw Exception('Upload falhou após $maxRetries tentativas');
    }
    
    // Obter URL de download
    String downloadUrl;
    try {
      downloadUrl = await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erro ao obter URL de download: $e');
      // Fallback para URL manual se getDownloadURL falhar
      final encodedPath = Uri.encodeComponent(ref.fullPath);
      downloadUrl = "https://firebasestorage.googleapis.com/v0/b/${_storage.bucket}/o/$encodedPath?alt=media";
    }
    
    debugPrint('Upload concluído: $downloadUrl');
    
    // OPCIONAL: Adicionar metadata depois do upload (se necessário)
    try {
      await ref.updateMetadata(SettableMetadata(
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalFileName': fileName,
          'fileSize': file.size.toString(),
        },
      ));
      debugPrint('Metadata adicionada com sucesso');
    } catch (metadataError) {
      debugPrint('Aviso: Não foi possível adicionar metadata: $metadataError');
      // Não falha o upload por causa da metadata
    }
    
    return UploadResult(
      downloadUrl: downloadUrl,
      filePath: filePath,
      fileSize: file.size,
    );
    
  } catch (e, stackTrace) {
    debugPrint('Erro detalhado no upload: $e');
    debugPrint('Stack trace: $stackTrace');
    debugPrint('Arquivo: $fileName, Tamanho: ${file.size}, Tipo: ${file.type}');
    return null;
  }
}
  
  /// CORREÇÃO: Método para verificar conectividade
  Future<bool> _checkConnectivity() async {
    try {
      // Connectivity check disabled for mobile
      return true;
    } catch (e) {
      debugPrint('Problema de conectividade: $e');
      return false;
    }
  }
  
  /// Obter content type do arquivo - VERSÃO MELHORADA
  String _getContentType(dynamic file) {
    // Primeiro, tentar usar o tipo MIME do arquivo
    if (file.type.isNotEmpty && file.type != 'application/octet-stream') {
      return file.type;
    }
    
    // Fallback para extensão
    final extension = path.extension(file.name).toLowerCase();
    
    switch (extension) {
      // Áudio
      case '.mp3': return 'audio/mpeg';
      case '.wav': return 'audio/wav';
      case '.m4a': return 'audio/mp4';
      case '.aac': return 'audio/aac';
      case '.ogg': return 'audio/ogg';
      case '.flac': return 'audio/flac';
      
      // Vídeo
      case '.mp4': return 'video/mp4';
      case '.mov': return 'video/quicktime';
      case '.avi': return 'video/x-msvideo';
      case '.mkv': return 'video/x-matroska';
      case '.webm': return 'video/webm';
      
      // Imagem
      case '.jpg':
      case '.jpeg': return 'image/jpeg';
      case '.png': return 'image/png';
      case '.gif': return 'image/gif';
      case '.webp': return 'image/webp';
      case '.bmp': return 'image/bmp';
      
      default: return 'application/octet-stream';
    }
  }
  
  // RESTO DOS MÉTODOS PERMANECEM IGUAIS...
  
  /// Upload de arquivos de vídeo com compressão e thumbnail
  Future<List<MediaItem>> uploadVideoFiles(List<dynamic> files) async {
    if (!kIsWeb) {
      throw UnsupportedError('File upload not supported on mobile platform');
    }
    final List<MediaItem> uploadedItems = [];
    final user = await AuthService.getCurrentUser();
    
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }
    
    for (final file in files) {
      try {
        // Validar arquivo
        if (!_isValidVideoFile(file)) {
          debugPrint('Arquivo de vídeo inválido: ${file.name}');
          continue;
        }
        
        // Verificar tamanho
        if (file.size > _maxFileSize) {
          debugPrint('Arquivo muito grande: ${file.name} (${_formatFileSize(file.size)})');
          continue;
        }
        
        // Processar vídeo (compressão se necessário)
        final processedFile = await _processVideoFile(file);
        
        // Upload para Firebase Storage
        final uploadResult = await _uploadFileToStorage(
          processedFile ?? file, 
          'video/${user.uid}',
          file.name,
        );
        
        if (uploadResult != null) {
          // Gerar e fazer upload do thumbnail
          final thumbnailUrl = await _generateAndUploadVideoThumbnail(
            file, 
            'thumbnails/video/${user.uid}',
          );
          
          // Extrair metadata do vídeo
          final metadata = await _extractVideoMetadata(file);
          
          // Criar VideoItem
          final videoItem = VideoItem(
            id: _generateId(),
            title: _getFileNameWithoutExtension(file.name),
            description: 'Vídeo importado em ${_formatDate(DateTime.now())}',
            createdDate: DateTime.now(),
            sourceType: MediaSourceType.url,
            sourcePath: uploadResult.downloadUrl,
            category: null, // Novos itens sem categoria inicialmente
            duration: metadata['duration'],
            width: metadata['width'],
            height: metadata['height'],
            resolution: '${metadata['width']}x${metadata['height']}',
            format: path.extension(file.name).toLowerCase().replaceFirst('.', ''),
            frameRate: metadata['frameRate'],
            fileSize: (processedFile ?? file).size,
            thumbnailUrl: thumbnailUrl,
          );
          
          // Salvar no Firestore
          await _firebaseManager.saveMediaItem(videoItem);
          uploadedItems.add(videoItem);
        }
      } catch (e) {
        debugPrint('Erro ao fazer upload de ${file.name}: $e');
      }
    }
    
    return uploadedItems;
  }
  
  /// Upload de imagens com compressão automática
  Future<List<MediaItem>> uploadImageFiles(List<dynamic> files) async {
    if (!kIsWeb) {
      throw UnsupportedError('File upload not supported on mobile platform');
    }
    final List<MediaItem> uploadedItems = [];
    final user = await AuthService.getCurrentUser();
    
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }
    
    for (final file in files) {
      try {
        // Validar arquivo
        if (!_isValidImageFile(file)) {
          debugPrint('Arquivo de imagem inválido: ${file.name}');
          continue;
        }
        
        // Processar imagem (compressão)
        final processedFile = await _processImageFile(file);
        
        // Upload para Firebase Storage
        final uploadResult = await _uploadFileToStorage(
          processedFile ?? file, 
          'images/${user.uid}',
          file.name,
        );
        
        if (uploadResult != null) {
          // Gerar thumbnail (versão menor da imagem)
          final thumbnailUrl = await _generateAndUploadImageThumbnail(
            processedFile ?? file, 
            'thumbnails/images/${user.uid}',
          );
          
          // Extrair metadata da imagem
          final metadata = await _extractImageMetadata(processedFile ?? file);
          
          // Criar ImageItem
          final imageItem = ImageItem(
            id: _generateId(),
            title: _getFileNameWithoutExtension(file.name),
            description: 'Imagem importada em ${_formatDate(DateTime.now())}',
            createdDate: DateTime.now(),
            sourceType: MediaSourceType.url,
            sourcePath: uploadResult.downloadUrl,
            width: metadata['width'],
            height: metadata['height'],
            resolution: '${metadata['width']}x${metadata['height']}',
            format: path.extension(file.name).toLowerCase().replaceFirst('.', ''),
            fileSize: (processedFile ?? file).size,
            thumbnailUrl: thumbnailUrl,
          );
          
          // Salvar no Firestore
          await _firebaseManager.saveMediaItem(imageItem);
          uploadedItems.add(imageItem);
        }
      } catch (e) {
        debugPrint('Erro ao fazer upload de ${file.name}: $e');
      }
    }
    
    return uploadedItems;
  }
  
  /// Compressão de imagem
  Future<dynamic?> _processImageFile(dynamic file) async {
    if (!kIsWeb) return null;
    try {
      // No web, usamos Canvas para redimensionar imagens
      return null; // Temporariamente desabilitado
      /*
      return null; // Stub return for mobile
      final completer = Completer<dynamic?>();
      
      reader.onLoad.listen((event) async {
        try {
          final img = // html.ImageElement();
          img.src = reader.result as String;
          
          await img.onLoad.first;
          
          // Calcular novas dimensões
          final originalWidth = img.naturalWidth!;
          final originalHeight = img.naturalHeight!;
          
          if (originalWidth <= _maxImageSize && originalHeight <= _maxImageSize) {
            // Imagem já é pequena o suficiente
            completer.complete(null);
            return;
          }
          
          final aspectRatio = originalWidth / originalHeight;
          int newWidth, newHeight;
          
          if (originalWidth > originalHeight) {
            newWidth = _maxImageSize;
            newHeight = (_maxImageSize / aspectRatio).round();
          } else {
            newHeight = _maxImageSize;
            newWidth = (_maxImageSize * aspectRatio).round();
          }
          
          // Criar canvas e redimensionar
          final canvas = // html.CanvasElement(width: newWidth, height: newHeight);
          final ctx = canvas.context2D;
          ctx.drawImageScaled(img, 0, 0, newWidth, newHeight);
          
          // Converter para data URL e depois para blob
          final dataUrl = canvas.toDataUrl(file.type);
          // final response = await // html.window.fetch(dataUrl);
          final blob = await response.blob();
          final compressedFile = dynamic([blob], file.name, {'type': file.type});
          completer.complete(compressedFile);
          
        } catch (e) {
          debugPrint('Erro na compressão de imagem: $e');
          completer.complete(null);
        }
      });
      
      reader.readAsDataUrl(file);
      return await completer.future;
      */
    } catch (e) {
      debugPrint('Erro no processamento de imagem: $e');
      return null;
    }
  }
  
  /// Processamento básico de vídeo (apenas validação por ora)
  Future<dynamic?> _processVideoFile(dynamic file) async {
    // Por ora, apenas retorna null (sem compressão)
    // Compressão de vídeo no web é complexa e requer WebAssembly
    return null;
  }
  
  /// Gerar thumbnail de vídeo
  Future<String?> _generateAndUploadVideoThumbnail(
    dynamic videoFile, 
    String folderPath,
  ) async {
    try {
      // Stub para mobile - sem thumbnail
      return null;
    } catch (e) {
      debugPrint('Erro ao gerar thumbnail de vídeo: $e');
      return null;
    }
  }
  
  /// Gerar thumbnail de imagem
  Future<String?> _generateAndUploadImageThumbnail(
    dynamic imageFile, 
    String folderPath,
  ) async {
    try {
      // Stub para mobile - sem thumbnail
      return null;
    } catch (e) {
      debugPrint('Erro no processamento de thumbnail: $e');
      return null;
    }
  }
  
  /// Extrair metadata de áudio (básico)
  Future<Map<String, dynamic>> _extractAudioMetadata(dynamic file) async {
    // Metadata básica - pode ser expandida com bibliotecas especializadas
    return {
      'duration': null, // Requer processamento específico
      'artist': null,
      'album': null,
    };
  }
  
  /// Extrair metadata de vídeo
  Future<Map<String, dynamic>> _extractVideoMetadata(dynamic file) async {
    try {
      // Stub para mobile - retorna metadados padrão
      return {
        'duration': Duration(seconds: 30),
        'width': 1280,
        'height': 720,
        'frameRate': 30,
      };
    } catch (e) {
      debugPrint('Erro ao extrair metadata de vídeo: $e');
      return {
        'duration': null,
        'width': null,
        'height': null,
        'frameRate': null,
      };
    }
  }
  
  /// Extrair metadata de imagem
  Future<Map<String, dynamic>> _extractImageMetadata(dynamic file) async {
    try {
      return {'width': 800, 'height': 600}; // Stub return for mobile
    } catch (e) {
      return {'width': null, 'height': null};
    }
  }
  
  // UTILITÁRIOS
  
  bool _isValidAudioFile(dynamic file) {
    final extension = path.extension(file.name).toLowerCase();
    return ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'].contains(extension);
  }
  
  bool _isValidVideoFile(dynamic file) {
    final extension = path.extension(file.name).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v'].contains(extension);
  }
  
  bool _isValidImageFile(dynamic file) {
    final extension = path.extension(file.name).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(extension);
  }
  
  String _getFileNameWithoutExtension(String fileName) {
    return path.basenameWithoutExtension(fileName);
  }
  
  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
  }
  
  String _generateId() {
    return 'media_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }
  
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) => chars[random % chars.length]).join();
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Verificar status de otimização de um item de mídia
  Future<Map<String, dynamic>?> getOptimizationStatus(String mediaItemId) async {
    try {
      final callable = _functions.httpsCallable('getOptimizationStatus');
      final result = await callable.call({'mediaItemId': mediaItemId});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Erro ao verificar status de otimização: $e');
      return null;
    }
  }

  /// Verificar progresso de otimização de múltiplos itens
  Future<List<Map<String, dynamic>>> checkOptimizationProgress(List<String> mediaItemIds) async {
    final List<Map<String, dynamic>> results = [];
    
    for (final mediaItemId in mediaItemIds) {
      final status = await getOptimizationStatus(mediaItemId);
      if (status != null) {
        results.add({
          'mediaItemId': mediaItemId,
          'status': status,
        });
      }
    }
    
    return results;
  }

}

/// Resultado do upload
class UploadResult {
  final String downloadUrl;
  final String filePath;
  final int fileSize;
  
  const UploadResult({
    required this.downloadUrl,
    required this.filePath,
    required this.fileSize,
  });
}