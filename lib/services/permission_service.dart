import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Serviço robusto de permissões para Android/iOS
/// Otimizado para Android 14+ e iOS 17+
class PermissionService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // Cache para evitar múltiplas verificações
  static final Map<MediaType, bool> _permissionCache = {};
  
  /// Request storage permissions based on Android version
  static Future<bool> requestStoragePermissions() async {
    if (kIsWeb) return true; // Web doesn't need permissions
    if (!Platform.isAndroid) return true; // Only Android needs these permissions
    
    try {
      // Get Android SDK version
      final androidInfo = await _deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      debugPrint('Android SDK Version: $sdkInt');
      
      if (sdkInt >= 33) {
        // Android 13+ (API 33+)
        // Request granular media permissions
        final permissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];
        
        // Check current status
        Map<Permission, PermissionStatus> statuses = {};
        for (var permission in permissions) {
          statuses[permission] = await permission.status;
          debugPrint('${permission.toString()} status: ${statuses[permission]}');
        }
        
        // Request permissions if not granted
        List<Permission> toRequest = [];
        for (var entry in statuses.entries) {
          if (!entry.value.isGranted && !entry.value.isPermanentlyDenied) {
            toRequest.add(entry.key);
          }
        }
        
        if (toRequest.isNotEmpty) {
          debugPrint('Requesting permissions: $toRequest');
          final results = await toRequest.request();
          
          // Check if all permissions were granted
          bool allGranted = true;
          for (var entry in results.entries) {
            debugPrint('${entry.key.toString()} result: ${entry.value}');
            if (!entry.value.isGranted) {
              allGranted = false;
            }
          }
          
          return allGranted;
        }
        
        // Check if all permissions are granted
        return statuses.values.every((status) => status.isGranted);
        
      } else if (sdkInt >= 30) {
        // Android 11-12 (API 30-32)
        // Request manage external storage permission
        final status = await Permission.manageExternalStorage.status;
        debugPrint('Manage external storage status: $status');
        
        if (!status.isGranted) {
          final result = await Permission.manageExternalStorage.request();
          debugPrint('Manage external storage result: $result');
          
          if (result.isPermanentlyDenied) {
            // Open app settings
            await openAppSettings();
            return false;
          }
          
          return result.isGranted;
        }
        
        return true;
        
      } else {
        // Android 10 and below (API 29-)
        // Request regular storage permission
        final status = await Permission.storage.status;
        debugPrint('Storage permission status: $status');
        
        if (!status.isGranted) {
          final result = await Permission.storage.request();
          debugPrint('Storage permission result: $result');
          
          if (result.isPermanentlyDenied) {
            // Open app settings
            await openAppSettings();
            return false;
          }
          
          return result.isGranted;
        }
        
        return true;
      }
    } catch (e) {
      debugPrint('Error requesting storage permissions: $e');
      return false;
    }
  }
  
  /// Check if storage permissions are granted
  static Future<bool> hasStoragePermissions() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;
    
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      if (sdkInt >= 33) {
        // Android 13+
        final photos = await Permission.photos.isGranted;
        final videos = await Permission.videos.isGranted;
        final audio = await Permission.audio.isGranted;
        
        return photos || videos || audio; // At least one should be granted
        
      } else if (sdkInt >= 30) {
        // Android 11-12
        return await Permission.manageExternalStorage.isGranted;
        
      } else {
        // Android 10 and below
        return await Permission.storage.isGranted;
      }
    } catch (e) {
      debugPrint('Error checking storage permissions: $e');
      return false;
    }
  }
  
  /// Request specific media type permission - VERSÃO ROBUSTA
  static Future<bool> requestMediaPermission(MediaType type) async {
    debugPrint('🔐 Solicitando permissão para ${type.name}...');
    debugPrint('🔐 Platform.isAndroid: ${Platform.isAndroid}');
    debugPrint('🔐 Platform.isIOS: ${Platform.isIOS}');
    debugPrint('🔐 kIsWeb: $kIsWeb');
    
    // Verificar cache primeiro
    if (_permissionCache.containsKey(type)) {
      final cached = _permissionCache[type]!;
      debugPrint('🔐 Permissão em cache: ${type.name} = $cached');
      return cached;
    }
    
    try {
      bool granted = false;
      
      if (Platform.isAndroid) {
        granted = await _requestAndroidPermission(type);
      } else if (Platform.isIOS) {
        granted = await _requestIOSPermission(type);
      } else {
        granted = true; // Desktop/outras plataformas
      }
      
      // Cachear resultado
      _permissionCache[type] = granted;
      
      debugPrint('🔐 Permissão ${type.name}: ${granted ? "CONCEDIDA" : "NEGADA"}');
      return granted;
      
    } catch (e) {
      debugPrint('❌ Erro ao solicitar permissão ${type.name}: $e');
      _permissionCache[type] = false;
      return false;
    }
  }
  
  /// Solicitar permissão Android
  static Future<bool> _requestAndroidPermission(MediaType type) async {
    final androidInfo = await _deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    
    debugPrint('🤖 Android SDK: $sdkInt');
    
    if (sdkInt >= 33) {
      // Android 13+ (API 33+) - Permissões granulares
      return await _requestAndroid13Permission(type);
    } else if (sdkInt >= 30) {
      // Android 11-12 (API 30-32) - MANAGE_EXTERNAL_STORAGE
      return await _requestAndroid11Permission();
    } else {
      // Android 10- (API 29-) - EXTERNAL_STORAGE
      return await _requestLegacyAndroidPermission();
    }
  }
  
  /// Permissões Android 13+
  static Future<bool> _requestAndroid13Permission(MediaType type) async {
    Permission permission;
    
    switch (type) {
      case MediaType.audio:
        permission = Permission.audio;
        break;
      case MediaType.video:
        permission = Permission.videos;
        break;
      case MediaType.image:
        permission = Permission.photos;
        break;
    }
    
    final status = await permission.status;
    debugPrint('🤖 ${permission.toString()} status: $status');
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      debugPrint('🚫 Permissão permanentemente negada - abrindo configurações');
      await openAppSettings();
      return false;
    }
    
    final result = await permission.request();
    debugPrint('🤖 ${permission.toString()} result: $result');
    
    if (result.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return result.isGranted;
  }
  
  /// Permissões Android 11-12
  static Future<bool> _requestAndroid11Permission() async {
    final status = await Permission.manageExternalStorage.status;
    debugPrint('🤖 Manage external storage status: $status');
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    final result = await Permission.manageExternalStorage.request();
    debugPrint('🤖 Manage external storage result: $result');
    
    if (result.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return result.isGranted;
  }
  
  /// Permissões Android legacy
  static Future<bool> _requestLegacyAndroidPermission() async {
    final status = await Permission.storage.status;
    debugPrint('🤖 Storage permission status: $status');
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    final result = await Permission.storage.request();
    debugPrint('🤖 Storage permission result: $result');
    
    if (result.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return result.isGranted;
  }
  
  /// Solicitar permissão iOS
  static Future<bool> _requestIOSPermission(MediaType type) async {
    debugPrint('🍎 Solicitando permissão iOS para ${type.name}');
    
    Permission permission;
    
    switch (type) {
      case MediaType.audio:
        permission = Permission.microphone; // Para gravação
        break;
      case MediaType.video:
      case MediaType.image:
        permission = Permission.photos;
        break;
    }
    
    final status = await permission.status;
    debugPrint('🍎 ${permission.toString()} status: $status');
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    final result = await permission.request();
    debugPrint('🍎 ${permission.toString()} result: $result');
    
    if (result.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return result.isGranted;
  }
  
  /// Limpar cache de permissões
  static void clearPermissionCache() {
    _permissionCache.clear();
    debugPrint('🔐 Cache de permissões limpo');
  }
  
  /// Verificar se permissão já foi concedida
  static Future<bool> hasMediaPermission(MediaType type) async {
    if (_permissionCache.containsKey(type)) {
      return _permissionCache[type]!;
    }
    
    try {
      bool granted = false;
      
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        
        if (sdkInt >= 33) {
          Permission permission;
          switch (type) {
            case MediaType.audio:
              permission = Permission.audio;
              break;
            case MediaType.video:
              permission = Permission.videos;
              break;
            case MediaType.image:
              permission = Permission.photos;
              break;
          }
          granted = await permission.isGranted;
        } else if (sdkInt >= 30) {
          granted = await Permission.manageExternalStorage.isGranted;
        } else {
          granted = await Permission.storage.isGranted;
        }
      } else if (Platform.isIOS) {
        switch (type) {
          case MediaType.audio:
            granted = await Permission.microphone.isGranted;
            break;
          case MediaType.video:
          case MediaType.image:
            granted = await Permission.photos.isGranted;
            break;
        }
      } else {
        granted = true;
      }
      
      _permissionCache[type] = granted;
      return granted;
      
    } catch (e) {
      debugPrint('❌ Erro ao verificar permissão: $e');
      return false;
    }
  }
}

enum MediaType {
  audio,
  video,
  image,
}