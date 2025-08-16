import 'package:flutter/material.dart';
import 'package:versee/services/playlist_service.dart';

enum MediaContentType { audio, video, image }

enum MediaSourceType { file, url, device, local }

abstract class MediaItem {
  final String id;
  final String title;
  final String? description;
  final DateTime createdDate;
  final DateTime? lastModified;
  final MediaContentType type;
  final MediaSourceType sourceType;
  final String sourcePath; // File path or URL
  final String? category; // Category ID for organization
  final Map<String, dynamic>? metadata;

  MediaItem({
    required this.id,
    required this.title,
    this.description,
    required this.createdDate,
    this.lastModified,
    required this.type,
    required this.sourceType,
    required this.sourcePath,
    this.category,
    this.metadata,
  });

  // Convert to PresentationItem for use in playlists
  PresentationItem toPresentationItem();
  
  // Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdDate': createdDate.millisecondsSinceEpoch,
      'lastModified': lastModified?.millisecondsSinceEpoch,
      'type': type.name,
      'sourceType': sourceType.name,
      'sourcePath': sourcePath,
      'category': category,
      'metadata': metadata,
    };
  }
  
  // Common properties that all media types should have
  String get displayTitle => title;
  String get displaySubtitle;
  IconData get displayIcon;
}

class AudioItem extends MediaItem {
  final Duration? duration;
  final String? artist;
  final String? album;
  final String? thumbnailUrl;
  final int? bitrate;
  final String? format;
  final int? fileSize;

  AudioItem({
    required super.id,
    required super.title,
    super.description,
    required super.createdDate,
    super.lastModified,
    required super.sourceType,
    required super.sourcePath,
    super.category,
    super.metadata,
    this.duration,
    this.artist,
    this.album,
    this.thumbnailUrl,
    this.bitrate,
    this.format,
    this.fileSize,
  }) : super(type: MediaContentType.audio);

  @override
  PresentationItem toPresentationItem() {
    return PresentationItem(
      id: 'audio_$id',
      title: displayTitle,
      type: ContentType.audio,
      content: sourcePath,
      metadata: {
        'mediaId': id,
        'mediaType': 'audio',
        'sourceType': sourceType.name,
        'duration': duration?.inMilliseconds,
        'artist': artist,
        'album': album,
        'thumbnailUrl': thumbnailUrl,
        'bitrate': bitrate,
        'format': format,
        'fileSize': fileSize,
        'description': description,
        ...?metadata,
      },
    );
  }

  @override
  String get displaySubtitle {
    final parts = <String>[];
    if (artist != null) parts.add(artist!);
    if (duration != null) {
      final minutes = duration!.inMinutes;
      final seconds = duration!.inSeconds % 60;
      parts.add('${minutes}:${seconds.toString().padLeft(2, '0')}');
    }
    if (fileSize != null) {
      parts.add(_formatFileSize(fileSize!));
    }
    return parts.isNotEmpty ? parts.join(' • ') : 'Áudio';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  IconData get displayIcon => Icons.music_note;

  AudioItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdDate,
    DateTime? lastModified,
    MediaSourceType? sourceType,
    String? sourcePath,
    String? category,
    Map<String, dynamic>? metadata,
    Duration? duration,
    String? artist,
    String? album,
    String? thumbnailUrl,
    int? bitrate,
    String? format,
    int? fileSize,
  }) {
    return AudioItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
      sourceType: sourceType ?? this.sourceType,
      sourcePath: sourcePath ?? this.sourcePath,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
      duration: duration ?? this.duration,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      bitrate: bitrate ?? this.bitrate,
      format: format ?? this.format,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}

class VideoItem extends MediaItem {
  final Duration? duration;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final String? resolution;
  final int? bitrate;
  final String? format;
  final double? frameRate;
  final int? fileSize;

  VideoItem({
    required super.id,
    required super.title,
    super.description,
    required super.createdDate,
    super.lastModified,
    required super.sourceType,
    required super.sourcePath,
    super.category,
    super.metadata,
    this.duration,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.resolution,
    this.bitrate,
    this.format,
    this.frameRate,
    this.fileSize,
  }) : super(type: MediaContentType.video);

  @override
  PresentationItem toPresentationItem() {
    return PresentationItem(
      id: 'video_$id',
      title: displayTitle,
      type: ContentType.video,
      content: sourcePath,
      metadata: {
        'mediaId': id,
        'mediaType': 'video',
        'sourceType': sourceType.name,
        'duration': duration?.inMilliseconds,
        'thumbnailUrl': thumbnailUrl,
        'width': width,
        'height': height,
        'resolution': resolution,
        'bitrate': bitrate,
        'format': format,
        'frameRate': frameRate,
        'fileSize': fileSize,
        'description': description,
        ...?metadata,
      },
    );
  }

  @override
  String get displaySubtitle {
    final parts = <String>[];
    if (resolution != null) parts.add(resolution!);
    if (duration != null) {
      final minutes = duration!.inMinutes;
      final seconds = duration!.inSeconds % 60;
      parts.add('${minutes}:${seconds.toString().padLeft(2, '0')}');
    }
    if (fileSize != null) {
      parts.add(_formatFileSize(fileSize!));
    }
    return parts.isNotEmpty ? parts.join(' • ') : 'Vídeo';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  IconData get displayIcon => Icons.play_circle_outline;

  VideoItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdDate,
    DateTime? lastModified,
    MediaSourceType? sourceType,
    String? sourcePath,
    String? category,
    Map<String, dynamic>? metadata,
    Duration? duration,
    String? thumbnailUrl,
    int? width,
    int? height,
    String? resolution,
    int? bitrate,
    String? format,
    double? frameRate,
    int? fileSize,
  }) {
    return VideoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
      sourceType: sourceType ?? this.sourceType,
      sourcePath: sourcePath ?? this.sourcePath,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      width: width ?? this.width,
      height: height ?? this.height,
      resolution: resolution ?? this.resolution,
      bitrate: bitrate ?? this.bitrate,
      format: format ?? this.format,
      frameRate: frameRate ?? this.frameRate,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}

class ImageItem extends MediaItem {
  final int? width;
  final int? height;
  final String resolution;
  final int? fileSize;
  final String? format;
  final String? thumbnailUrl;

  ImageItem({
    required super.id,
    required super.title,
    super.description,
    required super.createdDate,
    super.lastModified,
    required super.sourceType,
    required super.sourcePath,
    super.category,
    super.metadata,
    this.width,
    this.height,
    String? resolution,
    this.fileSize,
    this.format,
    this.thumbnailUrl,
  }) : resolution = resolution ?? (width != null && height != null ? '${width}x$height' : 'Desconhecida'),
        super(type: MediaContentType.image);

  @override
  PresentationItem toPresentationItem() {
    return PresentationItem(
      id: 'image_$id',
      title: displayTitle,
      type: ContentType.image,
      content: sourcePath,
      metadata: {
        'mediaId': id,
        'mediaType': 'image',
        'sourceType': sourceType.name,
        'width': width,
        'height': height,
        'resolution': resolution,
        'fileSize': fileSize,
        'format': format,
        'thumbnailUrl': thumbnailUrl,
        'description': description,
        ...?metadata,
      },
    );
  }

  @override
  String get displaySubtitle {
    final parts = <String>[];
    parts.add(resolution);
    if (format != null) parts.add(format!.toUpperCase());
    if (fileSize != null) {
      parts.add(_formatFileSize(fileSize!));
    }
    return parts.join(' • ');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  IconData get displayIcon => Icons.image;

  ImageItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdDate,
    DateTime? lastModified,
    MediaSourceType? sourceType,
    String? sourcePath,
    String? category,
    Map<String, dynamic>? metadata,
    int? width,
    int? height,
    String? resolution,
    int? fileSize,
    String? format,
    String? thumbnailUrl,
  }) {
    return ImageItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
      sourceType: sourceType ?? this.sourceType,
      sourcePath: sourcePath ?? this.sourcePath,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
      width: width ?? this.width,
      height: height ?? this.height,
      resolution: resolution ?? this.resolution,
      fileSize: fileSize ?? this.fileSize,
      format: format ?? this.format,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}

// Utility class for media management
class MediaCollection {
  final String id;
  final String title;
  final String? description;
  final List<MediaItem> items;
  final DateTime createdDate;
  final DateTime? lastModified;

  MediaCollection({
    required this.id,
    required this.title,
    this.description,
    required this.items,
    required this.createdDate,
    this.lastModified,
  });

  int get itemCount => items.length;
  
  List<AudioItem> get audioItems => items.whereType<AudioItem>().toList();
  List<VideoItem> get videoItems => items.whereType<VideoItem>().toList();
  List<ImageItem> get imageItems => items.whereType<ImageItem>().toList();

  MediaCollection copyWith({
    String? id,
    String? title,
    String? description,
    List<MediaItem>? items,
    DateTime? createdDate,
    DateTime? lastModified,
  }) {
    return MediaCollection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      items: items ?? this.items,
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}