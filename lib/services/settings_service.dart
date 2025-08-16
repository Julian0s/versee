import 'package:shared_preferences/shared_preferences.dart';
import 'package:versee/services/xml_bible_service.dart';

class SettingsService {
  static const String _bibleVersionsKey = 'enabled_bible_versions';
  
  // Default Bible versions configuration - English only (apenas as que funcionam na API)
  static const Map<String, String> defaultBibleVersions = {
    'KJV': 'King James Version',
    'ASV': 'American Standard Version',
    'BSB': 'Berean Standard Bible',
  };
  
  /// Get enabled Bible versions from settings
  static Future<Map<String, bool>> getEnabledBibleVersions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabledVersionsJson = prefs.getString(_bibleVersionsKey);
      
      // Always return default configuration with the 3 working versions
      final defaultConfig = {
        'King James Version (KJV)': true,
        'American Standard Version (ASV)': true, 
        'Berean Standard Bible (BSB)': false,
      };
      
      if (enabledVersionsJson != null && enabledVersionsJson.isNotEmpty) {
        // Parse saved settings
        final savedVersions = <String, bool>{};
        final parts = enabledVersionsJson.split('|');
        for (final part in parts) {
          if (part.contains(':')) {
            final keyValue = part.split(':');
            if (keyValue.length == 2) {
              final fullVersionName = keyValue[0];
              final isEnabled = keyValue[1] == 'true';
              savedVersions[fullVersionName] = isEnabled;
            }
          }
        }
        
        // Merge saved settings with defaults, prioritizing saved values
        final result = <String, bool>{};
        for (final entry in defaultConfig.entries) {
          result[entry.key] = savedVersions[entry.key] ?? entry.value;
        }
        
        return result;
      } else {
        // Return default configuration
        return defaultConfig;
      }
    } catch (e) {
      print('Error loading Bible version settings: $e');
      // Return default configuration on error
      return {
        'King James Version (KJV)': true,
        'American Standard Version (ASV)': true, 
        'Berean Standard Bible (BSB)': false,
      };
    }
  }
  
  /// Save enabled Bible versions to settings
  static Future<void> saveEnabledBibleVersions(Map<String, bool> versions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert to string format: "Version Name:true|Another Version:false"
      final parts = <String>[];
      for (final entry in versions.entries) {
        parts.add('${entry.key}:${entry.value}');
      }
      final enabledVersionsJson = parts.join('|');
      
      await prefs.setString(_bibleVersionsKey, enabledVersionsJson);
    } catch (e) {
      print('Error saving Bible version settings: $e');
    }
  }
  
  /// Get list of enabled Bible version abbreviations for filtering
  static Future<List<String>> getEnabledVersionAbbreviations() async {
    final enabledVersions = await getEnabledBibleVersions();
    final enabledAbbreviations = <String>[];
    
    // Add API-based Bible abbreviations
    for (final entry in enabledVersions.entries) {
      if (entry.value) {
        // Extract abbreviation from format "Version Name (ABBR)"
        final match = RegExp(r'\(([^)]+)\)$').firstMatch(entry.key);
        if (match != null) {
          enabledAbbreviations.add(match.group(1)!);
        }
      }
    }
    
    // Add XML imported Bible abbreviations
    try {
      final xmlService = XmlBibleService();
      final importedBibles = await xmlService.getImportedBibles();
      final enabledImportedIds = await xmlService.getEnabledImportedBibles();
      
      for (final bible in importedBibles) {
        if (enabledImportedIds.contains(bible['id'])) {
          enabledAbbreviations.add(bible['abbreviation']);
        }
      }
    } catch (e) {
      print('Error loading XML Bible abbreviations: $e');
    }
    
    return enabledAbbreviations;
  }
  
  /// Check if a specific Bible version is enabled
  static Future<bool> isBibleVersionEnabled(String abbreviation) async {
    final enabledAbbreviations = await getEnabledVersionAbbreviations();
    return enabledAbbreviations.contains(abbreviation);
  }
}