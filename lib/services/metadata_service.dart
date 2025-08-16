import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

class MediaMetadata {
  final Duration? duration;
  final int? width;
  final int? height;
  final String? format;
  final int? bitrate;
  final double? frameRate;
  final String? artist;
  final String? album;
  final String? thumbnailPath;

  const MediaMetadata({
    this.duration,
    this.width,
    this.height,
    this.format,
    this.bitrate,
    this.frameRate,
    this.artist,
    this.album,
    this.thumbnailPath,
  });

  MediaMetadata copyWith({
    Duration? duration,
    int? width,
    int? height,
    String? format,
    int? bitrate,
    double? frameRate,
    String? artist,
    String? album,
    String? thumbnailPath,
  }) {
    return MediaMetadata(
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      format: format ?? this.format,
      bitrate: bitrate ?? this.bitrate,
      frameRate: frameRate ?? this.frameRate,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}

class MetadataService {
  static const int thumbnailWidth = 200;
  static const int thumbnailHeight = 200;
  static const int thumbnailQuality = 80;

  // Extract metadata from video files
  static Future<MediaMetadata> extractVideoMetadata(
    String filePath,
    String thumbnailDir,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final fileExtension = path.extension(filePath).toLowerCase().replaceAll('.', '');
      
      // Generate thumbnail
      String? thumbnailPath;
      try {
        thumbnailPath = await _generateVideoThumbnail(filePath, thumbnailDir);
      } catch (e) {
        debugPrint('Error generating video thumbnail: $e');
      }

      // Basic video metadata (duration extraction is limited without ffmpeg)
      // For now, we'll try to get basic info and set reasonable defaults
      
      return MediaMetadata(
        format: fileExtension.toUpperCase(),
        thumbnailPath: thumbnailPath,
        // These would need proper media analysis tools for accurate extraction:
        duration: await _estimateVideoDuration(filePath),
        width: 1920, // Default HD resolution
        height: 1080,
        bitrate: 5000000, // 5 Mbps default
        frameRate: 30.0,
      );
    } catch (e) {
      debugPrint('Error extracting video metadata: $e');
      return MediaMetadata(
        format: path.extension(filePath).toUpperCase().replaceAll('.', ''),
      );
    }
  }

  // Extract metadata from audio files
  static Future<MediaMetadata> extractAudioMetadata(
    String filePath,
    String thumbnailDir,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final fileExtension = path.extension(filePath).toLowerCase().replaceAll('.', '');
      
      // Generate thumbnail (audio visualization or default icon)
      String? thumbnailPath;
      try {
        thumbnailPath = await _generateAudioThumbnail(filePath, thumbnailDir);
      } catch (e) {
        debugPrint('Error generating audio thumbnail: $e');
      }

      return MediaMetadata(
        format: fileExtension.toUpperCase(),
        thumbnailPath: thumbnailPath,
        // These would need proper audio analysis tools for accurate extraction:
        duration: await _estimateAudioDuration(filePath),
        bitrate: _estimateAudioBitrate(fileExtension),
        // For audio metadata like artist/album, we'd need a proper ID3 reader
        artist: _extractArtistFromFilename(filePath),
      );
    } catch (e) {
      debugPrint('Error extracting audio metadata: $e');
      return MediaMetadata(
        format: path.extension(filePath).toUpperCase().replaceAll('.', ''),
      );
    }
  }

  // Extract metadata from image files
  static Future<MediaMetadata> extractImageMetadata(
    String filePath,
    String thumbnailDir,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final fileExtension = path.extension(filePath).toLowerCase().replaceAll('.', '');
      
      // Read image dimensions com timeout
      final imageBytes = await file.readAsBytes().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Image reading timed out for: $filePath');
          return Uint8List(0);
        },
      );
      
      img.Image? image;
      try {
        image = await Future.microtask(() => img.decodeImage(imageBytes)).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('Image decoding timed out for: $filePath');
            return null;
          },
        );
      } catch (e) {
        debugPrint('Error decoding image: $e');
        image = null;
      }
      
      int? width;
      int? height;
      
      if (image != null) {
        width = image.width;
        height = image.height;
      }

      // Generate thumbnail
      String? thumbnailPath;
      try {
        thumbnailPath = await _generateImageThumbnail(filePath, thumbnailDir);
      } catch (e) {
        debugPrint('Error generating image thumbnail: $e');
      }

      return MediaMetadata(
        width: width,
        height: height,
        format: fileExtension.toUpperCase(),
        thumbnailPath: thumbnailPath,
      );
    } catch (e) {
      debugPrint('Error extracting image metadata: $e');
      return MediaMetadata(
        format: path.extension(filePath).toUpperCase().replaceAll('.', ''),
      );
    }
  }

  // Generate video thumbnail
  static Future<String?> _generateVideoThumbnail(
    String videoPath,
    String thumbnailDir,
  ) async {
    try {
      final fileName = path.basenameWithoutExtension(videoPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final thumbnailPath = path.join(thumbnailDir, '${fileName}_$timestamp.jpg');

      // Add timeout para evitar loading infinito
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: thumbnailWidth,
        maxHeight: thumbnailHeight,
        quality: thumbnailQuality,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Video thumbnail generation timed out for: $videoPath');
          return null;
        },
      );

      if (thumbnail != null) {
        final thumbnailFile = File(thumbnailPath);
        await thumbnailFile.writeAsBytes(thumbnail);
        return thumbnailPath;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  // Generate image thumbnail
  static Future<String?> _generateImageThumbnail(
    String imagePath,
    String thumbnailDir,
  ) async {
    try {
      final fileName = path.basenameWithoutExtension(imagePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final thumbnailPath = path.join(thumbnailDir, '${fileName}_$timestamp.jpg');

      // Add timeout para evitar loading infinito
      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        thumbnailPath,
        quality: thumbnailQuality,
        minWidth: thumbnailWidth,
        minHeight: thumbnailHeight,
        format: CompressFormat.jpeg,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('Image compression timed out for: $imagePath');
          return null;
        },
      );

      return result?.path;
    } catch (e) {
      debugPrint('Error generating image thumbnail: $e');
      return null;
    }
  }

  // Generate audio thumbnail (placeholder image)
  static Future<String?> _generateAudioThumbnail(
    String audioPath,
    String thumbnailDir,
  ) async {
    try {
      final fileName = path.basenameWithoutExtension(audioPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final thumbnailPath = path.join(thumbnailDir, '${fileName}_$timestamp.png');

      // Create a simple colored square as audio thumbnail
      final image = img.Image(width: thumbnailWidth, height: thumbnailHeight);
      img.fill(image, color: img.ColorRgb8(45, 45, 48)); // Dark background
      
      // Add a simple music note-like shape
      _drawSimpleMusicIcon(image);

      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(img.encodePng(image));
      
      return thumbnailPath;
    } catch (e) {
      debugPrint('Error generating audio thumbnail: $e');
      return null;
    }
  }

  // Draw a simple music icon on the image
  static void _drawSimpleMusicIcon(img.Image image) {
    try {
      final centerX = image.width ~/ 2;
      final centerY = image.height ~/ 2;
      final color = img.ColorRgb8(255, 255, 255); // White

      // Draw a simple circle (note head)
      img.fillCircle(image, x: centerX - 20, y: centerY + 10, radius: 15, color: color);
      
      // Draw a vertical line (note stem)
      img.drawLine(image, x1: centerX - 5, y1: centerY + 10, x2: centerX - 5, y2: centerY - 30, color: color);
    } catch (e) {
      debugPrint('Error drawing music icon: $e');
    }
  }

  // Estimate video duration (simplified approach)
  static Future<Duration?> _estimateVideoDuration(String filePath) async {
    try {
      // This is a simplified estimation based on file size and format
      // In a real implementation, you'd use proper media analysis tools
      final file = File(filePath);
      final size = await file.length();
      final extension = path.extension(filePath).toLowerCase();
      
      // Rough estimation based on file size (very approximate)
      double estimatedMinutes;
      switch (extension) {
        case '.mp4':
        case '.mov':
        case '.avi':
          estimatedMinutes = size / (10 * 1024 * 1024); // ~10MB per minute for HD
          break;
        case '.mkv':
        case '.flv':
          estimatedMinutes = size / (8 * 1024 * 1024); // ~8MB per minute
          break;
        default:
          estimatedMinutes = size / (12 * 1024 * 1024); // ~12MB per minute default
      }
      
      return Duration(minutes: estimatedMinutes.round());
    } catch (e) {
      return null;
    }
  }

  // Estimate audio duration (simplified approach)
  static Future<Duration?> _estimateAudioDuration(String filePath) async {
    try {
      final file = File(filePath);
      final size = await file.length();
      final extension = path.extension(filePath).toLowerCase();
      
      // Rough estimation based on file size and format
      double estimatedMinutes;
      switch (extension) {
        case '.mp3':
          estimatedMinutes = size / (1024 * 1024); // ~1MB per minute for 320kbps
          break;
        case '.flac':
        case '.wav':
          estimatedMinutes = size / (10 * 1024 * 1024); // ~10MB per minute for uncompressed
          break;
        case '.aac':
        case '.m4a':
          estimatedMinutes = size / (0.8 * 1024 * 1024); // ~0.8MB per minute
          break;
        case '.ogg':
          estimatedMinutes = size / (0.7 * 1024 * 1024); // ~0.7MB per minute
          break;
        default:
          estimatedMinutes = size / (1024 * 1024); // ~1MB per minute default
      }
      
      return Duration(minutes: estimatedMinutes.round());
    } catch (e) {
      return null;
    }
  }

  // Estimate audio bitrate based on format
  static int? _estimateAudioBitrate(String extension) {
    switch (extension.toLowerCase()) {
      case 'mp3':
        return 320; // kbps
      case 'flac':
        return 1411; // kbps (CD quality)
      case 'wav':
        return 1411; // kbps (CD quality)
      case 'aac':
      case 'm4a':
        return 256; // kbps
      case 'ogg':
        return 192; // kbps
      default:
        return 320; // kbps default
    }
  }

  // Try to extract artist from filename (very basic)
  static String? _extractArtistFromFilename(String filePath) {
    try {
      final fileName = path.basenameWithoutExtension(filePath);
      
      // Look for common patterns like "Artist - Song" or "Artist_Song"
      if (fileName.contains(' - ')) {
        return fileName.split(' - ').first.trim();
      } else if (fileName.contains('_')) {
        final parts = fileName.split('_');
        if (parts.length > 1) {
          return parts.first.trim();
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Clean up old thumbnails
  static Future<void> cleanupOldThumbnails(
    String thumbnailDir,
    Set<String> activeThumbnailPaths,
  ) async {
    try {
      final directory = Directory(thumbnailDir);
      if (!await directory.exists()) return;

      final files = directory.listSync();
      for (final entity in files) {
        if (entity is File && !activeThumbnailPaths.contains(entity.path)) {
          try {
            await entity.delete();
            debugPrint('Deleted old thumbnail: ${entity.path}');
          } catch (e) {
            debugPrint('Error deleting thumbnail ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up thumbnails: $e');
    }
  }

  // Get thumbnail size info
  static Future<Map<String, int>> getThumbnailInfo(String thumbnailPath) async {
    try {
      final file = File(thumbnailPath);
      if (!await file.exists()) {
        return {'width': 0, 'height': 0, 'size': 0};
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      final fileSize = bytes.length;

      return {
        'width': image?.width ?? 0,
        'height': image?.height ?? 0,
        'size': fileSize,
      };
    } catch (e) {
      return {'width': 0, 'height': 0, 'size': 0};
    }
  }
}