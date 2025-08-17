import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:versee/models/media_models.dart';
import 'package:versee/services/metadata_service.dart';
import 'package:versee/services/permission_service.dart';

// Web-specific imports  
import 'dart:convert' show base64Encode;
// import 'dart:html' as html if (dart.library.io) 'web_platform_stub.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FileManagerService extends ChangeNotifier {
  // Supported file extensions
  static const List<String> audioExtensions = ['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'];
  static const List<String> videoExtensions = ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm'];
  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];

  // App directories
  Directory? _appDirectory;
  Directory? _audioDirectory;
  Directory? _videoDirectory;
  Directory? _imageDirectory;
  Directory? _thumbnailDirectory;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Initialize directories
  Future<void> initialize() async {
    try {
      _appDirectory = await getApplicationDocumentsDirectory();
      
      // Create media subdirectories
      _audioDirectory = Directory(path.join(_appDirectory!.path, 'audio'));
      _videoDirectory = Directory(path.join(_appDirectory!.path, 'video'));
      _imageDirectory = Directory(path.join(_appDirectory!.path, 'images'));
      _thumbnailDirectory = Directory(path.join(_appDirectory!.path, 'thumbnails'));

      // Ensure directories exist
      await _audioDirectory!.create(recursive: true);
      await _videoDirectory!.create(recursive: true);
      await _imageDirectory!.create(recursive: true);
      await _thumbnailDirectory!.create(recursive: true);

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing FileManagerService: $e');
      rethrow;
    }
  }

  // Pick and import audio files
  Future<List<AudioItem>> pickAudioFiles() async {
    debugPrint('===== FileManagerService.pickAudioFiles() INICIADO =====');
    debugPrint('kIsWeb: $kIsWeb, _isInitialized: $_isInitialized');
    
    if (!kIsWeb && !_isInitialized) {
      debugPrint('Inicializando FileManagerService...');
      await initialize();
    }

    try {
      // Request permissions on Android
      if (!kIsWeb && Platform.isAndroid) {
        debugPrint('Solicitando permissões Android...');
        final hasPermission = await PermissionService.requestMediaPermission(MediaType.audio);
        debugPrint('Permissão concedida: $hasPermission');
        if (!hasPermission) {
          debugPrint('Permissão de áudio negada');
          return [];
        }
      }
      
      debugPrint('Abrindo FilePicker...');
      debugPrint('Extensões permitidas: $audioExtensions');
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: audioExtensions,
        allowMultiple: true,
        withData: kIsWeb, // Para web, precisamos dos bytes
      );

      debugPrint('FilePicker resultado: ${result != null ? "Arquivos selecionados" : "Cancelado"}');
      
      if (result != null && result.files.isNotEmpty) {
        debugPrint('${result.files.length} arquivos selecionados');
        List<AudioItem> audioItems = [];
        
        for (PlatformFile file in result.files) {
          AudioItem? audioItem;
          
          if (kIsWeb) {
            // Processamento para web
            audioItem = await _processAudioFileWeb(file);
          } else if (file.path != null) {
            // Processamento para mobile/desktop
            audioItem = await _processAudioFile(File(file.path!));
          }
          
          if (audioItem != null) {
            audioItems.add(audioItem);
          }
        }
        
        return audioItems;
      }
      
      return [];
    } catch (e) {
      debugPrint('Error picking audio files: $e');
      rethrow;
    }
  }

  // Pick and import video files
  Future<List<VideoItem>> pickVideoFiles() async {
    if (!kIsWeb && !_isInitialized) await initialize();

    try {
      // Request permissions on Android
      if (!kIsWeb && Platform.isAndroid) {
        final hasPermission = await PermissionService.requestMediaPermission(MediaType.video);
        if (!hasPermission) {
          debugPrint('Permissão de vídeo negada');
          return [];
        }
      }
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: videoExtensions,
        allowMultiple: true,
        withData: kIsWeb, // Para web, precisamos dos bytes
      );

      if (result != null && result.files.isNotEmpty) {
        List<VideoItem> videoItems = [];
        
        for (PlatformFile file in result.files) {
          VideoItem? videoItem;
          
          if (kIsWeb) {
            // Processamento para web
            videoItem = await _processVideoFileWeb(file);
          } else if (file.path != null) {
            // Processamento para mobile/desktop
            videoItem = await _processVideoFile(File(file.path!));
          }
          
          if (videoItem != null) {
            videoItems.add(videoItem);
          }
        }
        
        return videoItems;
      }
      
      return [];
    } catch (e) {
      debugPrint('Error picking video files: $e');
      rethrow;
    }
  }

  // Pick and import image files
  Future<List<ImageItem>> pickImageFiles() async {
    if (!kIsWeb && !_isInitialized) await initialize();

    try {
      // Request permissions on Android
      if (!kIsWeb && Platform.isAndroid) {
        final hasPermission = await PermissionService.requestMediaPermission(MediaType.image);
        if (!hasPermission) {
          debugPrint('Permissão de imagem negada');
          return [];
        }
      }
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: imageExtensions,
        allowMultiple: true,
        withData: kIsWeb, // Para web, precisamos dos bytes
      );

      if (result != null && result.files.isNotEmpty) {
        List<ImageItem> imageItems = [];
        
        for (PlatformFile file in result.files) {
          ImageItem? imageItem;
          
          if (kIsWeb) {
            // Processamento para web
            imageItem = await _processImageFileWeb(file);
          } else if (file.path != null) {
            // Processamento para mobile/desktop
            imageItem = await _processImageFile(File(file.path!));
          }
          
          if (imageItem != null) {
            imageItems.add(imageItem);
          }
        }
        
        return imageItems;
      }
      
      return [];
    } catch (e) {
      debugPrint('Error picking image files: $e');
      rethrow;
    }
  }

  // Process audio file and copy to app directory
  Future<AudioItem?> _processAudioFile(File sourceFile) async {
    try {
      final fileName = path.basename(sourceFile.path);
      final fileExtension = path.extension(fileName).toLowerCase().replaceAll('.', '');
      final fileNameWithoutExt = path.basenameWithoutExtension(fileName);
      
      // Generate unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${fileNameWithoutExt}_$timestamp.$fileExtension';
      final destinationPath = path.join(_audioDirectory!.path, uniqueFileName);
      
      // Copy file to app directory
      final copiedFile = await sourceFile.copy(destinationPath);
      final fileStat = await copiedFile.stat();

      // Extract metadata and generate thumbnail com timeout
      final metadata = await MetadataService.extractAudioMetadata(
        copiedFile.path,
        _thumbnailDirectory!.path,
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          debugPrint('Audio metadata extraction timed out for: ${copiedFile.path}');
          return const MediaMetadata();
        },
      );

      // Create AudioItem with extracted metadata
      return AudioItem(
        id: 'audio_${timestamp}',
        title: fileNameWithoutExt,
        description: 'Arquivo importado: $fileName',
        createdDate: DateTime.now(),
        sourceType: MediaSourceType.file,
        sourcePath: copiedFile.path,
        category: null, // Novos itens sem categoria inicialmente
        format: metadata.format ?? fileExtension.toUpperCase(),
        duration: metadata.duration ?? Duration.zero,
        fileSize: fileStat.size,
        bitrate: metadata.bitrate,
        artist: metadata.artist,
        thumbnailUrl: metadata.thumbnailPath,
      );
    } catch (e) {
      debugPrint('Error processing audio file: $e');
      return null;
    }
  }

  // Process video file and copy to app directory
  Future<VideoItem?> _processVideoFile(File sourceFile) async {
    try {
      final fileName = path.basename(sourceFile.path);
      final fileExtension = path.extension(fileName).toLowerCase().replaceAll('.', '');
      final fileNameWithoutExt = path.basenameWithoutExtension(fileName);
      
      // Generate unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${fileNameWithoutExt}_$timestamp.$fileExtension';
      final destinationPath = path.join(_videoDirectory!.path, uniqueFileName);
      
      // Copy file to app directory
      final copiedFile = await sourceFile.copy(destinationPath);
      final fileStat = await copiedFile.stat();

      // Extract metadata and generate thumbnail com timeout
      final metadata = await MetadataService.extractVideoMetadata(
        copiedFile.path,
        _thumbnailDirectory!.path,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint('Video metadata extraction timed out for: ${copiedFile.path}');
          return const MediaMetadata();
        },
      );

      // Create VideoItem with extracted metadata
      return VideoItem(
        id: 'video_${timestamp}',
        title: fileNameWithoutExt,
        description: 'Arquivo importado: $fileName',
        createdDate: DateTime.now(),
        sourceType: MediaSourceType.file,
        sourcePath: copiedFile.path,
        category: null, // Novos itens sem categoria inicialmente
        format: metadata.format ?? fileExtension.toUpperCase(),
        width: metadata.width ?? 1920,
        height: metadata.height ?? 1080,
        resolution: metadata.width != null && metadata.height != null 
          ? '${metadata.width}x${metadata.height}' 
          : '1920x1080',
        duration: metadata.duration ?? Duration.zero,
        fileSize: fileStat.size,
        bitrate: metadata.bitrate,
        frameRate: metadata.frameRate,
        thumbnailUrl: metadata.thumbnailPath,
      );
    } catch (e) {
      debugPrint('Error processing video file: $e');
      return null;
    }
  }

  // Process image file and copy to app directory
  Future<ImageItem?> _processImageFile(File sourceFile) async {
    try {
      final fileName = path.basename(sourceFile.path);
      final fileExtension = path.extension(fileName).toLowerCase().replaceAll('.', '');
      final fileNameWithoutExt = path.basenameWithoutExtension(fileName);
      
      // Generate unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${fileNameWithoutExt}_$timestamp.$fileExtension';
      final destinationPath = path.join(_imageDirectory!.path, uniqueFileName);
      
      // Copy file to app directory
      final copiedFile = await sourceFile.copy(destinationPath);
      final fileStat = await copiedFile.stat();

      // Extract metadata and generate thumbnail com timeout
      final metadata = await MetadataService.extractImageMetadata(
        copiedFile.path,
        _thumbnailDirectory!.path,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Image metadata extraction timed out for: ${copiedFile.path}');
          return const MediaMetadata();
        },
      );

      // Create ImageItem with extracted metadata
      return ImageItem(
        id: 'image_${timestamp}',
        title: fileNameWithoutExt,
        description: 'Arquivo importado: $fileName',
        createdDate: DateTime.now(),
        sourceType: MediaSourceType.file,
        sourcePath: copiedFile.path,
        format: metadata.format ?? fileExtension.toUpperCase(),
        width: metadata.width ?? 1920,
        height: metadata.height ?? 1080,
        fileSize: fileStat.size,
        thumbnailUrl: metadata.thumbnailPath,
      );
    } catch (e) {
      debugPrint('Error processing image file: $e');
      return null;
    }
  }

  // Delete a media file from storage
  Future<bool> deleteMediaFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting media file: $e');
      return false;
    }
  }

  // Check if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get file size
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Clean up unused files (files not referenced by any MediaItem)
  Future<void> cleanupUnusedFiles(List<MediaItem> referencedItems) async {
    try {
      final referencedPaths = referencedItems
          .where((item) => item.sourceType == MediaSourceType.file)
          .map((item) => item.sourcePath)
          .toSet();

      // Get all thumbnail paths that should be kept
      final activeThumbnailPaths = <String>{};
      for (final item in referencedItems) {
        String? thumbnailPath;
        if (item is AudioItem && item.thumbnailUrl != null) {
          thumbnailPath = item.thumbnailUrl;
        } else if (item is VideoItem && item.thumbnailUrl != null) {
          thumbnailPath = item.thumbnailUrl;
        } else if (item is ImageItem && item.thumbnailUrl != null) {
          thumbnailPath = item.thumbnailUrl;
        }
        if (thumbnailPath != null) {
          activeThumbnailPaths.add(thumbnailPath);
        }
      }

      // Clean media directories
      await _cleanupDirectory(_audioDirectory!, referencedPaths);
      await _cleanupDirectory(_videoDirectory!, referencedPaths);
      await _cleanupDirectory(_imageDirectory!, referencedPaths);
      
      // Clean thumbnail directory
      await MetadataService.cleanupOldThumbnails(
        _thumbnailDirectory!.path,
        activeThumbnailPaths,
      );
      
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  Future<void> _cleanupDirectory(Directory directory, Set<String> referencedPaths) async {
    try {
      final files = directory.listSync();
      for (FileSystemEntity entity in files) {
        if (entity is File && !referencedPaths.contains(entity.path)) {
          await entity.delete();
          debugPrint('Deleted unused file: ${entity.path}');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning directory ${directory.path}: $e');
    }
  }

  // Get storage information
  Future<Map<String, dynamic>> getStorageInfo() async {
    if (!_isInitialized) await initialize();

    try {
      int audioFiles = 0;
      int videoFiles = 0;
      int imageFiles = 0;
      
      int audioSize = 0;
      int videoSize = 0;
      int imageSize = 0;

      // Count audio files and size
      if (await _audioDirectory!.exists()) {
        final audioFilesList = _audioDirectory!.listSync();
        audioFiles = audioFilesList.length;
        for (FileSystemEntity entity in audioFilesList) {
          if (entity is File) {
            final stat = await entity.stat();
            audioSize += stat.size;
          }
        }
      }

      // Count video files and size
      if (await _videoDirectory!.exists()) {
        final videoFilesList = _videoDirectory!.listSync();
        videoFiles = videoFilesList.length;
        for (FileSystemEntity entity in videoFilesList) {
          if (entity is File) {
            final stat = await entity.stat();
            videoSize += stat.size;
          }
        }
      }

      // Count image files and size
      if (await _imageDirectory!.exists()) {
        final imageFilesList = _imageDirectory!.listSync();
        imageFiles = imageFilesList.length;
        for (FileSystemEntity entity in imageFilesList) {
          if (entity is File) {
            final stat = await entity.stat();
            imageSize += stat.size;
          }
        }
      }

      return {
        'audioFiles': audioFiles,
        'videoFiles': videoFiles,
        'imageFiles': imageFiles,
        'audioSize': audioSize,
        'videoSize': videoSize,
        'imageSize': imageSize,
        'totalFiles': audioFiles + videoFiles + imageFiles,
        'totalSize': audioSize + videoSize + imageSize,
      };
    } catch (e) {
      debugPrint('Error getting storage info: $e');
      return {
        'audioFiles': 0,
        'videoFiles': 0,
        'imageFiles': 0,
        'audioSize': 0,
        'videoSize': 0,
        'imageSize': 0,
        'totalFiles': 0,
        'totalSize': 0,
      };
    }
  }

  // Validate file extension
  static bool isValidAudioExtension(String extension) {
    return audioExtensions.contains(extension.toLowerCase().replaceAll('.', ''));
  }

  static bool isValidVideoExtension(String extension) {
    return videoExtensions.contains(extension.toLowerCase().replaceAll('.', ''));
  }

  static bool isValidImageExtension(String extension) {
    return imageExtensions.contains(extension.toLowerCase().replaceAll('.', ''));
  }

  // Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // WEB-SPECIFIC METHODS WITH OPTIMIZATION

  // Process audio file for web with compression and optimization
  Future<AudioItem?> _processAudioFileWeb(PlatformFile file) async {
    try {
      if (file.bytes == null) return null;

      final fileName = file.name;
      final fileExtension = path.extension(fileName).toLowerCase().replaceAll('.', '');
      final fileNameWithoutExt = path.basenameWithoutExtension(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Compress audio file for web if it's too large
      Uint8List processedBytes = file.bytes!;
      if (file.size > 10 * 1024 * 1024) { // 10MB threshold
        debugPrint('Large audio file detected: ${file.size} bytes. Applying compression optimization...');
        processedBytes = await _compressAudioForWeb(file.bytes!, fileExtension);
      }

      // Create blob URL using optimized approach
      final blobUrl = await _createOptimizedBlobUrl(processedBytes, 'audio/$fileExtension');
      
      if (blobUrl.isEmpty) return null;

      // Create AudioItem for web with proper blob URL
      return AudioItem(
        id: 'audio_web_${timestamp}',
        title: fileNameWithoutExt,
        description: 'Arquivo web: $fileName',
        createdDate: DateTime.now(),
        sourceType: MediaSourceType.url,
        sourcePath: blobUrl,
        category: null, // Novos itens sem categoria inicialmente
        format: fileExtension.toUpperCase(),
        fileSize: processedBytes.length,
        duration: null, // Will be determined by player
        bitrate: null,
        artist: null,
        thumbnailUrl: null,
      );
    } catch (e) {
      debugPrint('Error processing web audio file: $e');
      return null;
    }
  }

  // Process video file for web with compression and optimization
  Future<VideoItem?> _processVideoFileWeb(PlatformFile file) async {
    try {
      if (file.bytes == null) return null;

      final fileName = file.name;
      final fileExtension = path.extension(fileName).toLowerCase().replaceAll('.', '');
      final fileNameWithoutExt = path.basenameWithoutExtension(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Check file size and apply compression if needed
      Uint8List processedBytes = file.bytes!;
      String? thumbnailUrl;
      
      if (file.size > 50 * 1024 * 1024) { // 50MB threshold for videos
        debugPrint('Large video file detected: ${file.size} bytes. Applying optimization...');
        processedBytes = await _compressVideoForWeb(file.bytes!, fileExtension);
      }

      // Generate thumbnail for video
      try {
        thumbnailUrl = await _generateVideoThumbnailWeb(processedBytes, fileExtension);
      } catch (e) {
        debugPrint('Error generating video thumbnail: $e');
      }

      // Create blob URL using optimized approach
      final blobUrl = await _createOptimizedBlobUrl(processedBytes, 'video/$fileExtension');
      
      if (blobUrl.isEmpty) return null;

      // Create VideoItem for web with proper blob URL
      return VideoItem(
        id: 'video_web_${timestamp}',
        title: fileNameWithoutExt,
        description: 'Arquivo web: $fileName',
        createdDate: DateTime.now(),
        sourceType: MediaSourceType.url,
        sourcePath: blobUrl,
        category: null, // Novos itens sem categoria inicialmente
        format: fileExtension.toUpperCase(),
        fileSize: processedBytes.length,
        width: null, // Will be determined by player
        height: null,
        resolution: 'Desconhecida',
        duration: null, // Will be determined by player
        bitrate: null,
        frameRate: null,
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      debugPrint('Error processing web video file: $e');
      return null;
    }
  }

  // Process image file for web with intelligent compression
  Future<ImageItem?> _processImageFileWeb(PlatformFile file) async {
    try {
      if (file.bytes == null) return null;

      final fileName = file.name;
      final fileExtension = path.extension(fileName).toLowerCase().replaceAll('.', '');
      final fileNameWithoutExt = path.basenameWithoutExtension(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Decode image to get dimensions
      img.Image? originalImage;
      try {
        originalImage = img.decodeImage(file.bytes!);
      } catch (e) {
        debugPrint('Error decoding image: $e');
      }

      // Apply intelligent compression
      final compressedData = await _compressImageIntelligently(file.bytes!, fileExtension, originalImage);
      
      // Create optimized blob URL
      final blobUrl = await _createOptimizedBlobUrl(compressedData.bytes, 'image/${compressedData.format}');
      
      if (blobUrl.isEmpty) return null;

      // Generate thumbnail
      final thumbnailUrl = await _generateImageThumbnailWeb(compressedData.bytes, compressedData.format);

      // Create ImageItem for web with proper blob URL
      return ImageItem(
        id: 'image_web_${timestamp}',
        title: fileNameWithoutExt,
        description: 'Arquivo web otimizado: $fileName',
        createdDate: DateTime.now(),
        sourceType: MediaSourceType.url,
        sourcePath: blobUrl,
        format: compressedData.format.toUpperCase(),
        fileSize: compressedData.bytes.length,
        width: compressedData.width,
        height: compressedData.height,
        thumbnailUrl: thumbnailUrl ?? blobUrl,
      );
    } catch (e) {
      debugPrint('Error processing web image file: $e');
      return null;
    }
  }

  // OPTIMIZATION METHODS

  // Create optimized blob URL using native browser APIs when possible
  Future<String> _createOptimizedBlobUrl(Uint8List bytes, String mimeType) async {
    try {
      if (kIsWeb) {
        // Blob API not available on mobile
        final base64String = base64Encode(bytes);
        return 'data:$mimeType;base64,$base64String';
      } else {
        // Fallback to data URL for non-web platforms
        final base64String = base64Encode(bytes);
        return 'data:$mimeType;base64,$base64String';
      }
    } catch (e) {
      debugPrint('Error creating blob URL: $e');
      return '';
    }
  }

  // Intelligent image compression with adaptive quality
  Future<CompressedImageData> _compressImageIntelligently(Uint8List bytes, String format, img.Image? originalImage) async {
    try {
      if (originalImage == null) {
        return CompressedImageData(bytes, format, null, null);
      }

      final width = originalImage.width;
      final height = originalImage.height;
      final fileSize = bytes.length;

      // Determine compression strategy based on image characteristics
      int targetMaxWidth = 1920;
      int targetMaxHeight = 1080;
      int quality = 85;

      // Adjust compression based on file size
      if (fileSize > 10 * 1024 * 1024) { // > 10MB
        quality = 70;
        targetMaxWidth = 1600;
        targetMaxHeight = 900;
      } else if (fileSize > 5 * 1024 * 1024) { // > 5MB
        quality = 75;
        targetMaxWidth = 1920;
        targetMaxHeight = 1080;
      } else if (fileSize > 2 * 1024 * 1024) { // > 2MB
        quality = 80;
      }

      // Skip compression for small images
      if (fileSize < 500 * 1024 && width <= targetMaxWidth && height <= targetMaxHeight) {
        return CompressedImageData(bytes, format, width, height);
      }

      // Compress image
      Uint8List? compressedBytes;
      try {
        // Use appropriate format for compression
        final targetFormat = format.toLowerCase() == 'png' ? CompressFormat.png : CompressFormat.jpeg;
        
        compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: targetMaxWidth,
          minHeight: targetMaxHeight,
          quality: quality,
          format: targetFormat,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('Image compression timed out, using original');
            return Uint8List(0);
          },
        );
      } catch (e) {
        debugPrint('Error compressing image: $e');
      }

      if (compressedBytes != null && compressedBytes.length < bytes.length) {
        // Get new dimensions
        final compressedImage = img.decodeImage(compressedBytes);
        final newWidth = compressedImage?.width ?? width;
        final newHeight = compressedImage?.height ?? height;
        final newFormat = 'jpeg'; // Default to jpeg for compression
        
        debugPrint('Image compressed: ${bytes.length} -> ${compressedBytes.length} bytes (${((1 - compressedBytes.length / bytes.length) * 100).toStringAsFixed(1)}% reduction)');
        return CompressedImageData(compressedBytes, newFormat, newWidth, newHeight);
      }

      return CompressedImageData(bytes, format, width, height);
    } catch (e) {
      debugPrint('Error in intelligent compression: $e');
      return CompressedImageData(bytes, format, originalImage?.width, originalImage?.height);
    }
  }

  // Compress audio for web (placeholder - basic optimization)
  Future<Uint8List> _compressAudioForWeb(Uint8List bytes, String format) async {
    try {
      // For now, just return original bytes
      // In the future, could implement audio compression using web APIs
      debugPrint('Audio compression not yet implemented, using original size');
      return bytes;
    } catch (e) {
      debugPrint('Error compressing audio: $e');
      return bytes;
    }
  }

  // Compress video for web (placeholder - basic optimization)
  Future<Uint8List> _compressVideoForWeb(Uint8List bytes, String format) async {
    try {
      // For now, just return original bytes
      // In the future, could implement video compression using web APIs or server-side processing
      debugPrint('Video compression not yet implemented, using original size');
      return bytes;
    } catch (e) {
      debugPrint('Error compressing video: $e');
      return bytes;
    }
  }

  // Generate video thumbnail for web
  Future<String?> _generateVideoThumbnailWeb(Uint8List videoBytes, String format) async {
    try {
      // Create a simple placeholder thumbnail for videos
      // In the future, could use canvas API to extract frame
      final image = img.Image(width: 200, height: 200);
      img.fill(image, color: img.ColorRgb8(30, 30, 30)); // Dark background
      
      // Add play icon
      _drawPlayIcon(image);
      
      final thumbnailBytes = img.encodePng(image);
      return await _createOptimizedBlobUrl(Uint8List.fromList(thumbnailBytes), 'image/png');
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  // Generate image thumbnail for web
  Future<String?> _generateImageThumbnailWeb(Uint8List imageBytes, String format) async {
    try {
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      // Create thumbnail
      final thumbnail = img.copyResize(originalImage, width: 200, height: 200, interpolation: img.Interpolation.average);
      final thumbnailBytes = img.encodePng(thumbnail);
      
      return await _createOptimizedBlobUrl(Uint8List.fromList(thumbnailBytes), 'image/png');
    } catch (e) {
      debugPrint('Error generating image thumbnail: $e');
      return null;
    }
  }

  // Draw play icon for video thumbnails
  void _drawPlayIcon(img.Image image) {
    try {
      final centerX = image.width ~/ 2;
      final centerY = image.height ~/ 2;
      final color = img.ColorRgb8(255, 255, 255); // White

      // Draw play triangle using drawPixel
      // Create a simple play icon by drawing lines
      for (int i = -30; i <= 30; i++) {
        for (int j = -20; j <= 20; j++) {
          if (i >= 0 && j >= -i/2 && j <= i/2) {
            final x = centerX + i;
            final y = centerY + j;
            if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
              image.setPixel(x, y, color);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error drawing play icon: $e');
    }
  }

  // Cleanup method for web blob URLs
  void cleanupBlobUrls(List<String> urls) {
    if (kIsWeb) {
      for (final url in urls) {
        if (url.startsWith('blob:')) {
          try {
            // URL revoke not needed for data URLs
          } catch (e) {
            debugPrint('Error revoking blob URL: $e');
          }
        }
      }
    }
  }
}

// Helper class for compressed image data
class CompressedImageData {
  final Uint8List bytes;
  final String format;
  final int? width;
  final int? height;

  CompressedImageData(this.bytes, this.format, this.width, this.height);
}