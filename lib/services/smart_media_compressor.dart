import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:versee/models/media_models.dart';

// Web-specific imports
// import 'dart:html' as html if (dart.library.io) 'web_platform_stub.dart';

/// Serviço de compressão inteligente multi-nível para mídias
/// Gera versões otimizadas para diferentes usos (thumbnail, preview, original)
class SmartMediaCompressor {
  
  // Configurações de qualidade por nível
  static const Map<CompressionLevel, CompressionSettings> _settings = {
    CompressionLevel.thumbnail: CompressionSettings(
      maxWidth: 200,
      maxHeight: 200,
      quality: 60,
      maxSizeBytes: 50 * 1024, // 50KB
    ),
    CompressionLevel.preview: CompressionSettings(
      maxWidth: 800,
      maxHeight: 600,
      quality: 75,
      maxSizeBytes: 500 * 1024, // 500KB
    ),
    CompressionLevel.compressed: CompressionSettings(
      maxWidth: 1920,
      maxHeight: 1080,
      quality: 80,
      maxSizeBytes: 2 * 1024 * 1024, // 2MB
    ),
    CompressionLevel.original: CompressionSettings(
      maxWidth: 4096,
      maxHeight: 4096,
      quality: 90,
      maxSizeBytes: 10 * 1024 * 1024, // 10MB
    ),
  };
  
  /// Comprime uma imagem em múltiplos níveis
  static Future<MultiLevelMediaResult> compressImageMultiLevel(
    Uint8List originalBytes,
    String fileName,
  ) async {
    try {
      print('🖼️ Iniciando compressão multi-nível de imagem: $fileName');
      
      // Decodificar imagem original
      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) {
        throw Exception('Não foi possível decodificar a imagem');
      }
      
      final format = _getImageFormat(fileName);
      final results = <CompressionLevel, Uint8List>{};
      
      // Gerar cada nível de compressão
      for (final level in CompressionLevel.values) {
        if (level == CompressionLevel.original) {
          // Para original, aplicar apenas otimização leve
          results[level] = await _optimizeOriginalImage(originalBytes, originalImage, format);
        } else {
          results[level] = await _compressImageForLevel(originalImage, format, level);
        }
        
        print('✅ Nível ${level.name}: ${_formatBytes(results[level]!.length)}');
      }
      
      return MultiLevelMediaResult(
        mediaType: MediaContentType.image,
        thumbnailData: results[CompressionLevel.thumbnail],
        previewData: results[CompressionLevel.preview],
        compressedData: results[CompressionLevel.compressed],
        originalData: results[CompressionLevel.original],
        metadata: {
          'originalWidth': originalImage.width,
          'originalHeight': originalImage.height,
          'format': format,
          'originalSize': originalBytes.length,
        },
      );
      
    } catch (e) {
      print('❌ Erro na compressão multi-nível: $e');
      throw Exception('Falha na compressão: $e');
    }
  }
  
  /// Comprime um áudio em múltiplos níveis
  static Future<MultiLevelMediaResult> compressAudioMultiLevel(
    Uint8List originalBytes,
    String fileName,
  ) async {
    try {
      print('🎵 Iniciando compressão multi-nível de áudio: $fileName');
      
      // Para áudio, usamos estratégias diferentes
      final format = _getAudioFormat(fileName);
      final results = <CompressionLevel, Uint8List>{};
      
      // Thumbnail: Gerar waveform visual como imagem
      results[CompressionLevel.thumbnail] = await _generateAudioThumbnail(originalBytes);
      
      // Preview: Versão de baixa qualidade para preview rápido
      results[CompressionLevel.preview] = await _compressAudioForPreview(originalBytes, format);
      
      // Compressed: Qualidade balanceada
      results[CompressionLevel.compressed] = await _compressAudioForQuality(originalBytes, format);
      
      // Original: Manter original ou aplicar compressão sem perdas
      results[CompressionLevel.original] = originalBytes;
      
      return MultiLevelMediaResult(
        mediaType: MediaContentType.audio,
        thumbnailData: results[CompressionLevel.thumbnail],
        previewData: results[CompressionLevel.preview],
        compressedData: results[CompressionLevel.compressed],
        originalData: results[CompressionLevel.original],
        metadata: {
          'format': format,
          'originalSize': originalBytes.length,
        },
      );
      
    } catch (e) {
      print('❌ Erro na compressão de áudio: $e');
      throw Exception('Falha na compressão de áudio: $e');
    }
  }
  
  /// Comprime um vídeo em múltiplos níveis
  static Future<MultiLevelMediaResult> compressVideoMultiLevel(
    Uint8List originalBytes,
    String fileName,
  ) async {
    try {
      print('🎬 Iniciando compressão multi-nível de vídeo: $fileName');
      
      final format = _getVideoFormat(fileName);
      final results = <CompressionLevel, Uint8List>{};
      
      // Thumbnail: Frame do meio como imagem
      results[CompressionLevel.thumbnail] = await _generateVideoThumbnail(originalBytes);
      
      // Preview: Baixa resolução para preview rápido  
      results[CompressionLevel.preview] = await _compressVideoForPreview(originalBytes, format);
      
      // Compressed: Qualidade balanceada
      results[CompressionLevel.compressed] = await _compressVideoForQuality(originalBytes, format);
      
      // Original: Manter original
      results[CompressionLevel.original] = originalBytes;
      
      return MultiLevelMediaResult(
        mediaType: MediaContentType.video,
        thumbnailData: results[CompressionLevel.thumbnail],
        previewData: results[CompressionLevel.preview], 
        compressedData: results[CompressionLevel.compressed],
        originalData: results[CompressionLevel.original],
        metadata: {
          'format': format,
          'originalSize': originalBytes.length,
        },
      );
      
    } catch (e) {
      print('❌ Erro na compressão de vídeo: $e');
      throw Exception('Falha na compressão de vídeo: $e');
    }
  }
  
  // MÉTODOS DE COMPRESSÃO PARA IMAGENS
  
  static Future<Uint8List> _compressImageForLevel(
    img.Image originalImage,
    String format,
    CompressionLevel level,
  ) async {
    final settings = _settings[level]!;
    
    // Redimensionar se necessário
    img.Image processedImage = originalImage;
    
    if (originalImage.width > settings.maxWidth || originalImage.height > settings.maxHeight) {
      processedImage = img.copyResize(
        originalImage,
        width: settings.maxWidth,
        height: settings.maxHeight,
        interpolation: img.Interpolation.average,
      );
    }
    
    // Aplicar compressão com qualidade apropriada
    Uint8List compressedBytes;
    
    switch (format.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(processedImage, quality: settings.quality)
        );
        break;
      case 'png':
        // Para PNG, manter PNG mas com menor qualidade se necessário
        compressedBytes = Uint8List.fromList(img.encodePng(processedImage));
        break;
      case 'webp':
        // WebP não suportado nesta versão, usar JPEG
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(processedImage, quality: settings.quality)
        );
        break;
      default:
        // Fallback para JPEG
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(processedImage, quality: settings.quality)
        );
    }
    
    // Se ainda muito grande, reduzir qualidade iterativamente
    if (compressedBytes.length > settings.maxSizeBytes && settings.quality > 30) {
      int quality = settings.quality - 10;
      while (compressedBytes.length > settings.maxSizeBytes && quality > 30) {
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(processedImage, quality: quality)
        );
        quality -= 10;
      }
    }
    
    return compressedBytes;
  }
  
  static Future<Uint8List> _optimizeOriginalImage(
    Uint8List originalBytes,
    img.Image originalImage,
    String format,
  ) async {
    // Para imagem original, aplicar apenas otimização sem perdas quando possível
    if (originalBytes.length <= _settings[CompressionLevel.original]!.maxSizeBytes) {
      return originalBytes; // Manter original se dentro do limite
    }
    
    // Caso contrário, aplicar compressão leve
    final optimized = Uint8List.fromList(
      img.encodeJpg(originalImage, quality: 90)
    );
    
    return optimized.length < originalBytes.length ? optimized : originalBytes;
  }
  
  // MÉTODOS DE COMPRESSÃO PARA ÁUDIO
  
  static Future<Uint8List> _generateAudioThumbnail(Uint8List audioBytes) async {
    // Gerar uma visualização simples do waveform como imagem
    const width = 200;
    const height = 100;
    
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(240, 240, 240));
    
    // Simular waveform (em implementação real, analisaria o áudio)
    final centerY = height ~/ 2;
    for (int x = 0; x < width; x++) {
      final amplitude = (audioBytes.length > x) ? 
        (audioBytes[x % audioBytes.length] / 255.0) * (height / 4) : 0.0;
      
      final y1 = (centerY - amplitude).round().clamp(0, height - 1);
      final y2 = (centerY + amplitude).round().clamp(0, height - 1);
      
      // Simular pixel setting (método setPixel não disponível nesta versão)
      // for (int y = y1; y <= y2; y++) {
      //   img.setPixel(image, x, y, img.ColorRgb8(60, 120, 200));
      // }
    }
    
    return Uint8List.fromList(img.encodeJpg(image, quality: 80));
  }
  
  static Future<Uint8List> _compressAudioForPreview(Uint8List audioBytes, String format) async {
    // Para preview, retornar uma versão menor (simulação - implementação real usaria codec)
    if (audioBytes.length <= 100 * 1024) return audioBytes; // Já pequeno
    
    // Simular compressão reduzindo bitrate (implementação simplificada)
    final targetSize = 100 * 1024; // 100KB para preview
    final ratio = targetSize / audioBytes.length;
    
    if (ratio >= 1.0) return audioBytes;
    
    final step = (1.0 / ratio).round();
    final compressedData = <int>[];
    
    for (int i = 0; i < audioBytes.length; i += step) {
      compressedData.add(audioBytes[i]);
    }
    
    return Uint8List.fromList(compressedData);
  }
  
  static Future<Uint8List> _compressAudioForQuality(Uint8List audioBytes, String format) async {
    // Para versão de qualidade, aplicar compressão moderada
    if (audioBytes.length <= 500 * 1024) return audioBytes; // Já em tamanho bom
    
    // Implementação simplificada - em produção usaria FFmpeg ou similar
    return audioBytes; // Por enquanto manter original
  }
  
  // MÉTODOS DE COMPRESSÃO PARA VÍDEO
  
  static Future<Uint8List> _generateVideoThumbnail(Uint8List videoBytes) async {
    // Extrair frame do meio do vídeo como thumbnail
    // Implementação simplificada - retorna placeholder
    const width = 200;
    const height = 150;
    
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(50, 50, 50));
    
    // Adicionar ícone de play
    final centerX = width ~/ 2;
    final centerY = height ~/ 2;
    final playSize = 30;
    
    // Triângulo de play
    for (int i = 0; i < playSize; i++) {
      for (int j = 0; j < i; j++) {
        // Simular desenho do triângulo (setPixel não disponível)
        // final x = centerX - playSize ~/ 2 + i;
        // final y = centerY - i ~/ 2 + j;
        // if (x >= 0 && x < width && y >= 0 && y < height) {
        //   img.setPixel(image, x, y, img.ColorRgb8(255, 255, 255));
        // }
      }
    }
    
    return Uint8List.fromList(img.encodeJpg(image, quality: 80));
  }
  
  static Future<Uint8List> _compressVideoForPreview(Uint8List videoBytes, String format) async {
    // Para preview de vídeo, reduzir drasticamente o tamanho
    // Implementação simplificada - em produção usaria FFmpeg
    if (videoBytes.length <= 1024 * 1024) return videoBytes; // 1MB
    
    // Simular compressão pesada
    final targetSize = 1024 * 1024; // 1MB
    final ratio = targetSize / videoBytes.length;
    
    if (ratio >= 1.0) return videoBytes;
    
    // Simplificação: manter apenas metadados e início do vídeo
    final previewSize = (videoBytes.length * 0.1).round().clamp(targetSize ~/ 2, targetSize);
    return videoBytes.sublist(0, previewSize);
  }
  
  static Future<Uint8List> _compressVideoForQuality(Uint8List videoBytes, String format) async {
    // Para vídeo de qualidade, aplicar compressão moderada
    if (videoBytes.length <= 5 * 1024 * 1024) return videoBytes; // 5MB
    
    // Implementação simplificada - em produção usaria codecs específicos
    return videoBytes; // Por enquanto manter original
  }
  
  // MÉTODOS AUXILIARES
  
  static String _getImageFormat(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpg';
      case 'png':
        return 'png';
      case 'webp':
        return 'webp';
      case 'gif':
        return 'gif';
      default:
        return 'jpg'; // Fallback
    }
  }
  
  static String _getAudioFormat(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp3':
        return 'mp3';
      case 'wav':
        return 'wav';
      case 'ogg':
        return 'ogg';
      case 'm4a':
        return 'm4a';
      case 'aac':
        return 'aac';
      default:
        return 'mp3'; // Fallback
    }
  }
  
  static String _getVideoFormat(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp4':
        return 'mp4';
      case 'webm':
        return 'webm';
      case 'mov':
        return 'mov';
      case 'avi':
        return 'avi';
      default:
        return 'mp4'; // Fallback
    }
  }
  
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

/// Níveis de compressão disponíveis
enum CompressionLevel {
  thumbnail,  // Muito pequeno para visualização rápida
  preview,    // Pequeno para preview rápido
  compressed, // Tamanho balanceado para uso geral
  original,   // Qualidade máxima/original
}

/// Configurações para cada nível de compressão
class CompressionSettings {
  final int maxWidth;
  final int maxHeight;
  final int quality;
  final int maxSizeBytes;
  
  const CompressionSettings({
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
    required this.maxSizeBytes,
  });
}

/// Resultado da compressão multi-nível
class MultiLevelMediaResult {
  final MediaContentType mediaType;
  final Uint8List? thumbnailData;
  final Uint8List? previewData;
  final Uint8List? compressedData;
  final Uint8List? originalData;
  final Map<String, dynamic> metadata;
  
  const MultiLevelMediaResult({
    required this.mediaType,
    this.thumbnailData,
    this.previewData,
    this.compressedData,
    this.originalData,
    this.metadata = const {},
  });
  
  /// Obtém dados para um nível específico
  Uint8List? getDataForLevel(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.thumbnail:
        return thumbnailData;
      case CompressionLevel.preview:
        return previewData;
      case CompressionLevel.compressed:
        return compressedData;
      case CompressionLevel.original:
        return originalData;
    }
  }
  
  /// Obtém o melhor nível disponível
  CompressionLevel getBestAvailableLevel() {
    if (originalData != null) return CompressionLevel.original;
    if (compressedData != null) return CompressionLevel.compressed;
    if (previewData != null) return CompressionLevel.preview;
    if (thumbnailData != null) return CompressionLevel.thumbnail;
    throw Exception('Nenhum dado disponível');
  }
  
  /// Tamanho total de todos os níveis
  int get totalSize {
    return (thumbnailData?.length ?? 0) +
           (previewData?.length ?? 0) +
           (compressedData?.length ?? 0) +
           (originalData?.length ?? 0);
  }
  
  @override
  String toString() {
    return 'MultiLevelMediaResult(type: $mediaType, levels: ${_availableLevels()}, total: ${_formatBytes(totalSize)})';
  }
  
  List<CompressionLevel> _availableLevels() {
    final levels = <CompressionLevel>[];
    if (thumbnailData != null) levels.add(CompressionLevel.thumbnail);
    if (previewData != null) levels.add(CompressionLevel.preview);
    if (compressedData != null) levels.add(CompressionLevel.compressed);
    if (originalData != null) levels.add(CompressionLevel.original);
    return levels;
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}