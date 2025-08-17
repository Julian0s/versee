import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:versee/services/permission_service.dart';

/// Serviço de compressão para otimização de arquivos de mídia
/// Focado em Android/iOS com algoritmos nativos
class CompressionService {
  
  // Configurações de compressão
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int imageQuality = 85;
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB
  static const int maxAudioSize = 20 * 1024 * 1024; // 20MB
  
  /// Comprimir arquivo baseado no tipo
  static Future<Uint8List> compressFile(
    Uint8List bytes, 
    MediaType type, 
    String extension,
  ) async {
    debugPrint('🗜️ Comprimindo ${type.name} (${bytes.length} bytes)...');
    
    try {
      Uint8List compressedBytes;
      
      switch (type) {
        case MediaType.image:
          compressedBytes = await _compressImage(bytes, extension);
          break;
        case MediaType.video:
          compressedBytes = await _compressVideo(bytes);
          break;
        case MediaType.audio:
          compressedBytes = await _compressAudio(bytes);
          break;
      }
      
      final compressionRatio = (1 - (compressedBytes.length / bytes.length)) * 100;
      
      debugPrint('🗜️ Compressão concluída: ${compressedBytes.length} bytes '
                 '(${compressionRatio.toStringAsFixed(1)}% redução)');
      
      return compressedBytes;
      
    } catch (e) {
      debugPrint('❌ Erro na compressão: $e');
      debugPrint('🔄 Retornando arquivo original');
      return bytes;
    }
  }
  
  /// Comprimir imagem
  static Future<Uint8List> _compressImage(Uint8List bytes, String extension) async {
    try {
      // Verificar se precisa comprimir
      if (bytes.length < 1024 * 1024) { // Menor que 1MB
        debugPrint('🖼️ Imagem pequena, sem compressão necessária');
        return bytes;
      }
      
      // Decodificar imagem
      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('❌ Não foi possível decodificar a imagem');
        return bytes;
      }
      
      // Verificar se precisa redimensionar
      bool needsResize = image.width > maxImageWidth || image.height > maxImageHeight;
      
      img.Image processedImage = image;
      
      if (needsResize) {
        // Calcular novas dimensões mantendo aspect ratio
        final aspectRatio = image.width / image.height;
        int newWidth, newHeight;
        
        if (image.width > image.height) {
          newWidth = maxImageWidth;
          newHeight = (maxImageWidth / aspectRatio).round();
        } else {
          newHeight = maxImageHeight;
          newWidth = (maxImageHeight * aspectRatio).round();
        }
        
        // Redimensionar
        processedImage = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
        
        debugPrint('🖼️ Redimensionado: ${image.width}x${image.height} → ${newWidth}x${newHeight}');
      }
      
      // Codificar com qualidade otimizada
      late Uint8List compressedBytes;
      
      if (extension.toLowerCase() == '.png') {
        // PNG - manter transparência se necessário
        compressedBytes = Uint8List.fromList(img.encodePng(processedImage));
      } else {
        // JPEG - aplicar compressão com qualidade
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(processedImage, quality: imageQuality)
        );
      }
      
      return compressedBytes;
      
    } catch (e) {
      debugPrint('❌ Erro na compressão de imagem: $e');
      
      // Fallback para flutter_image_compress
      try {
        final result = await FlutterImageCompress.compressWithList(
          bytes,
          quality: imageQuality,
          minWidth: maxImageWidth,
          minHeight: maxImageHeight,
        );
        
        debugPrint('🖼️ Compressão alternativa bem-sucedida');
        return result;
        
      } catch (e2) {
        debugPrint('❌ Fallback também falhou: $e2');
        return bytes;
      }
    }
  }
  
  /// Comprimir vídeo (placeholder - compressão básica por tamanho)
  static Future<Uint8List> _compressVideo(Uint8List bytes) async {
    debugPrint('🎥 Processando vídeo...');
    
    if (bytes.length <= maxVideoSize) {
      debugPrint('🎥 Vídeo dentro do limite de tamanho');
      return bytes;
    }
    
    // TODO: Implementar compressão de vídeo real
    // Por ora, apenas verificar tamanho
    debugPrint('⚠️ Vídeo muito grande: ${bytes.length} bytes > $maxVideoSize bytes');
    debugPrint('🔄 Compressão de vídeo não implementada - retornando original');
    
    return bytes;
  }
  
  /// Comprimir áudio (placeholder - verificação de tamanho)
  static Future<Uint8List> _compressAudio(Uint8List bytes) async {
    debugPrint('🎵 Processando áudio...');
    
    if (bytes.length <= maxAudioSize) {
      debugPrint('🎵 Áudio dentro do limite de tamanho');
      return bytes;
    }
    
    // TODO: Implementar compressão de áudio real
    // Por ora, apenas verificar tamanho
    debugPrint('⚠️ Áudio muito grande: ${bytes.length} bytes > $maxAudioSize bytes');
    debugPrint('🔄 Compressão de áudio não implementada - retornando original');
    
    return bytes;
  }
  
  /// Gerar thumbnail para imagem
  static Future<Uint8List?> generateThumbnail(Uint8List imageBytes) async {
    try {
      debugPrint('🖼️ Gerando thumbnail...');
      
      // Decodificar imagem
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('❌ Não foi possível decodificar a imagem para thumbnail');
        return null;
      }
      
      // Calcular novas dimensões para thumbnail (máximo 400x400)
      const maxThumbSize = 400;
      final aspectRatio = image.width / image.height;
      int thumbWidth, thumbHeight;
      
      if (image.width > image.height) {
        thumbWidth = image.width > maxThumbSize ? maxThumbSize : image.width;
        thumbHeight = (thumbWidth / aspectRatio).round();
      } else {
        thumbHeight = image.height > maxThumbSize ? maxThumbSize : image.height;
        thumbWidth = (thumbHeight * aspectRatio).round();
      }
      
      // Se a imagem já é pequena, não precisa de thumbnail
      if (image.width <= maxThumbSize && image.height <= maxThumbSize) {
        debugPrint('🖼️ Imagem já é pequena, usando como thumbnail');
        return Uint8List.fromList(img.encodeJpg(image, quality: 70));
      }
      
      // Redimensionar para thumbnail
      final thumbnail = img.copyResize(
        image,
        width: thumbWidth,
        height: thumbHeight,
        interpolation: img.Interpolation.linear,
      );
      
      // Codificar como JPEG com qualidade 70%
      final thumbnailBytes = Uint8List.fromList(
        img.encodeJpg(thumbnail, quality: 70)
      );
      
      debugPrint('🖼️ Thumbnail gerada: ${image.width}x${image.height} → ${thumbWidth}x${thumbHeight}');
      debugPrint('🖼️ Tamanho: ${imageBytes.length} → ${thumbnailBytes.length} bytes');
      
      return thumbnailBytes;
      
    } catch (e) {
      debugPrint('❌ Erro ao gerar thumbnail: $e');
      
      // Fallback para flutter_image_compress
      try {
        final result = await FlutterImageCompress.compressWithList(
          imageBytes,
          quality: 70,
          minWidth: 400,
          minHeight: 400,
        );
        
        debugPrint('🖼️ Thumbnail gerada via fallback');
        return result;
        
      } catch (e2) {
        debugPrint('❌ Fallback também falhou: $e2');
        return null;
      }
    }
  }
  
  /// Verificar se arquivo precisa de compressão
  static bool needsCompression(Uint8List bytes, MediaType type) {
    switch (type) {
      case MediaType.image:
        return bytes.length > 1024 * 1024; // > 1MB
      case MediaType.video:
        return bytes.length > maxVideoSize;
      case MediaType.audio:
        return bytes.length > maxAudioSize;
    }
  }
  
  /// Estimar tamanho após compressão
  static int estimateCompressedSize(Uint8List bytes, MediaType type) {
    switch (type) {
      case MediaType.image:
        // Estimativa: 30-70% de redução
        return (bytes.length * 0.5).round();
      case MediaType.video:
        // Estimativa: 20-50% de redução
        return (bytes.length * 0.7).round();
      case MediaType.audio:
        // Estimativa: 10-40% de redução
        return (bytes.length * 0.8).round();
    }
  }
  
  /// Formatar tamanho de arquivo
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}