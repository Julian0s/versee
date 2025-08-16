import 'package:versee/models/media_models.dart';
import 'package:versee/services/playlist_service.dart';

/// Utilitários para manipulação de mídia
/// Centraliza lógicas duplicadas de parsing e conversão
class MediaUtils {
  /// Converte string/dynamic para MediaSourceType
  static MediaSourceType parseSourceType(dynamic sourceType) {
    if (sourceType is String) {
      switch (sourceType.toLowerCase()) {
        case 'file':
          return MediaSourceType.file;
        case 'url':
          return MediaSourceType.url;
        case 'device':
          return MediaSourceType.device;
        default:
          return MediaSourceType.file;
      }
    }
    return MediaSourceType.file;
  }

  /// Converte int/dynamic para Duration
  static Duration? parseDuration(dynamic duration) {
    if (duration is int) {
      return Duration(milliseconds: duration);
    }
    if (duration is double) {
      return Duration(milliseconds: duration.round());
    }
    return null;
  }

  /// Detecta MIME type a partir da URL
  static String? getMimeTypeFromUrl(String url) {
    final uri = Uri.parse(url.toLowerCase());
    final path = uri.path.toLowerCase();
    
    // Audio formats
    if (path.endsWith('.mp3')) return 'audio/mpeg';
    if (path.endsWith('.wav')) return 'audio/wav';
    if (path.endsWith('.ogg') || path.endsWith('.oga')) return 'audio/ogg';
    if (path.endsWith('.m4a')) return 'audio/mp4';
    if (path.endsWith('.aac')) return 'audio/aac';
    if (path.endsWith('.webm')) return 'audio/webm';
    
    // Firebase Storage URL parsing
    if (url.contains('firebasestorage.googleapis.com')) {
      final contentType = uri.queryParameters['contentType'];
      if (contentType != null && contentType.startsWith('audio/')) {
        return contentType;
      }
      // Default for Firebase Storage
      return 'audio/mpeg';
    }
    
    return null; // Let browser detect
  }

  /// Converte formato de áudio para MIME type
  static String formatToMimeType(String format) {
    switch (format.toLowerCase()) {
      case 'mp3': return 'audio/mpeg';
      case 'wav': return 'audio/wav';
      case 'ogg': case 'oga': return 'audio/ogg';
      case 'm4a': return 'audio/mp4';
      case 'aac': return 'audio/aac';
      case 'webm': return 'audio/webm';
      default: return 'audio/mpeg';
    }
  }

  /// Valida se uma string é uma URL válida
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'blob');
    } catch (e) {
      return false;
    }
  }

  /// Formata duração para exibição
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  /// Cria MediaItem a partir de PresentationItem
  static MediaItem? createMediaItemFromPresentation(PresentationItem item) {
    final metadata = item.metadata;
    if (metadata == null) return null;
    
    final mediaType = metadata['mediaType'] as String?;
    final mediaId = metadata['mediaId'] as String?;
    
    if (mediaId == null || mediaType == null) return null;
    
    switch (mediaType) {
      case 'audio':
        return AudioItem(
          id: mediaId,
          title: item.title,
          description: metadata['description'] as String?,
          createdDate: DateTime.now(),
          sourceType: parseSourceType(metadata['sourceType']),
          sourcePath: item.content,
          category: metadata['category'] as String?,
          duration: parseDuration(metadata['duration']),
          artist: metadata['artist'] as String?,
          album: metadata['album'] as String?,
          thumbnailUrl: metadata['thumbnailUrl'] as String?,
          bitrate: metadata['bitrate'] as int?,
          format: metadata['format'] as String?,
          fileSize: metadata['fileSize'] as int?,
        );
      case 'video':
        return VideoItem(
          id: mediaId,
          title: item.title,
          description: metadata['description'] as String?,
          createdDate: DateTime.now(),
          sourceType: parseSourceType(metadata['sourceType']),
          sourcePath: item.content,
          category: metadata['category'] as String?,
          duration: parseDuration(metadata['duration']),
          thumbnailUrl: metadata['thumbnailUrl'] as String?,
          width: metadata['width'] as int?,
          height: metadata['height'] as int?,
          resolution: metadata['resolution'] as String?,
          bitrate: metadata['bitrate'] as int?,
          format: metadata['format'] as String?,
          frameRate: (metadata['frameRate'] as num?)?.toDouble(),
          fileSize: metadata['fileSize'] as int?,
        );
      case 'image':
        return ImageItem(
          id: mediaId,
          title: item.title,
          description: metadata['description'] as String?,
          createdDate: DateTime.now(),
          sourceType: parseSourceType(metadata['sourceType']),
          sourcePath: item.content,
          width: metadata['width'] as int?,
          height: metadata['height'] as int?,
          resolution: metadata['resolution'] as String?,
          format: metadata['format'] as String?,
          fileSize: metadata['fileSize'] as int?,
          thumbnailUrl: metadata['thumbnailUrl'] as String?,
        );
      default:
        return null;
    }
  }
}