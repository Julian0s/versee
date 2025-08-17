import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Gerar thumbnail para vídeo
  static Future<Uint8List?> generateVideoThumbnail(String videoPath) async {
    try {
      debugPrint('🎥 Gerando thumbnail para vídeo...');
      
      // Obter diretório temporário
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Gerar thumbnail usando video_thumbnail
      final thumbnailFile = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 400,
        quality: 75,
        timeMs: 1000, // Pegar frame após 1 segundo
      );
      
      if (thumbnailFile == null) {
        debugPrint('❌ Não foi possível gerar thumbnail do vídeo');
        return null;
      }
      
      // Ler arquivo de thumbnail
      final file = File(thumbnailFile);
      if (!await file.exists()) {
        debugPrint('❌ Arquivo de thumbnail não encontrado');
        return null;
      }
      
      final thumbnailBytes = await file.readAsBytes();
      
      // Limpar arquivo temporário
      try {
        await file.delete();
      } catch (e) {
        debugPrint('⚠️ Não foi possível deletar arquivo temporário: $e');
      }
      
      debugPrint('🎥 Thumbnail de vídeo gerada: ${thumbnailBytes.length} bytes');
      return thumbnailBytes;
      
    } catch (e) {
      debugPrint('❌ Erro ao gerar thumbnail de vídeo: $e');
      return null;
    }
  }

  /// Gerar ou extrair capa para áudio
  static Future<Uint8List?> generateAudioCover(Uint8List audioBytes, String fileName) async {
    try {
      debugPrint('🎵 Processando capa de áudio...');
      
      // TODO: Implementar extração de metadata/artwork do arquivo de áudio
      // Por enquanto, vamos criar uma capa padrão
      
      // Criar uma imagem padrão para áudio (gradiente com ícone de música)
      final defaultCover = await _createDefaultAudioCover(fileName);
      
      if (defaultCover != null) {
        debugPrint('🎵 Capa padrão criada para áudio: ${defaultCover.length} bytes');
      }
      
      return defaultCover;
      
    } catch (e) {
      debugPrint('❌ Erro ao gerar capa de áudio: $e');
      return null;
    }
  }

  /// Criar capa padrão para áudio
  static Future<Uint8List?> _createDefaultAudioCover(String fileName) async {
    try {
      // Criar uma imagem 400x400 com gradiente e texto
      final image = img.Image(width: 400, height: 400);
      
      // Criar gradiente de fundo (roxo para azul)
      for (int y = 0; y < 400; y++) {
        for (int x = 0; x < 400; x++) {
          final progress = y / 400;
          final r = (138 * (1 - progress) + 63 * progress).round();
          final g = (43 * (1 - progress) + 81 * progress).round();
          final b = (226 * (1 - progress) + 181 * progress).round();
          
          image.setPixelRgba(x, y, r, g, b, 255);
        }
      }
      
      // Adicionar ícone de música no centro (círculo com nota musical)
      final centerX = 200;
      final centerY = 200;
      final radius = 80;
      
      // Desenhar círculo branco semi-transparente
      for (int y = centerY - radius; y <= centerY + radius; y++) {
        for (int x = centerX - radius; x <= centerX + radius; x++) {
          final distance = ((x - centerX) * (x - centerX) + (y - centerY) * (y - centerY));
          if (distance <= radius * radius) {
            final pixel = image.getPixel(x, y);
            // Misturar com branco semi-transparente
            final r = (pixel.r * 0.3 + 255 * 0.7).round();
            final g = (pixel.g * 0.3 + 255 * 0.7).round();
            final b = (pixel.b * 0.3 + 255 * 0.7).round();
            image.setPixelRgba(x, y, r, g, b, 255);
          }
        }
      }
      
      // Desenhar símbolo de nota musical simples (♪)
      // Haste vertical
      for (int y = centerY - 40; y <= centerY + 20; y++) {
        for (int x = centerX - 2; x <= centerX + 2; x++) {
          image.setPixelRgba(x, y, 138, 43, 226, 255);
        }
      }
      
      // Cabeça da nota (oval)
      final ovalCenterY = centerY + 20;
      for (int y = ovalCenterY - 15; y <= ovalCenterY + 15; y++) {
        for (int x = centerX - 20; x <= centerX + 20; x++) {
          final dx = (x - centerX) / 20.0;
          final dy = (y - ovalCenterY) / 15.0;
          if (dx * dx + dy * dy <= 1) {
            image.setPixelRgba(x, y, 138, 43, 226, 255);
          }
        }
      }
      
      // Bandeirola
      for (int y = centerY - 40; y <= centerY - 20; y++) {
        for (int x = centerX; x <= centerX + 30; x++) {
          if (y == centerY - 40 || x == centerX + 30 || 
              (x - centerX) == (centerY - 40 - y) * 2) {
            image.setPixelRgba(x, y, 138, 43, 226, 255);
          }
        }
      }
      
      // Adicionar nome do arquivo na parte inferior
      // Por enquanto, vamos deixar sem texto (requer fonte)
      
      // Codificar como JPEG
      final coverBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: 85)
      );
      
      return coverBytes;
      
    } catch (e) {
      debugPrint('❌ Erro ao criar capa padrão: $e');
      return null;
    }
  }
}