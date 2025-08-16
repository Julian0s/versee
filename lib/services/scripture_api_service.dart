import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versee/models/bible_models.dart';
import 'package:versee/services/xml_bible_service.dart';
// import 'package:versee/services/sqlite_bible_service.dart';

class ScriptureApiService {
  static const String _baseUrl = 'https://api.scripture.api.bible/v1';
  static const String _apiKey = '60517ac9ce769914a559ffbae7bee600';
  
  // Cache keys
  static const String _cacheVersionsKey = 'scripture_cache_versions';
  static const String _cacheVersesKey = 'scripture_cache_verses';
  static const Duration _cacheExpiry = Duration(hours: 24);
  
  // Offline mode flag
  static bool _isOfflineMode = false;
  
  // Services for imported Bibles
  static final XmlBibleService _xmlBibleService = XmlBibleService();
  // static final SqliteBibleService _sqliteBibleService = SqliteBibleService();
  
  /// Check if currently in offline mode
  static bool get isOfflineMode => _isOfflineMode;

  /// Reset offline mode (useful for retry)
  static void resetOfflineMode() {
    _isOfflineMode = false;
    print('🔄 Offline mode reset, attempting fresh connection');
  }

  // Popular Bible versions - will be populated from API
  static Map<String, BibleVersionInfo> _popularVersions = {};
  
  // Target popular versions we want to prioritize (only available ones from scripture.api.bible)
  static const Map<String, Map<String, String>> _targetVersions = {
    // 🇺🇸 English Only - Apenas as versões que funcionam na API
    'en': {
      'KJV': 'King James Version',
      'ASV': 'American Standard Version',
      'BSB': 'Berean Standard Bible',
    },
  };
  
  // Getter for popular versions (for compatibility)
  static Map<String, BibleVersionInfo> get popularVersions => _popularVersions;

  // Mapping book names (English and Portuguese) to Scripture API Bible book IDs
  static const Map<String, String> bookMapping = {
    // Old Testament - English
    'Genesis': 'GEN',
    'Exodus': 'EXO', 
    'Leviticus': 'LEV',
    'Numbers': 'NUM',
    'Deuteronomy': 'DEU',
    'Joshua': 'JOS',
    'Judges': 'JDG',
    'Ruth': 'RUT',
    '1 Samuel': '1SA',
    '2 Samuel': '2SA',
    '1 Kings': '1KI',
    '2 Kings': '2KI',
    '1 Chronicles': '1CH',
    '2 Chronicles': '2CH',
    'Ezra': 'EZR',
    'Nehemiah': 'NEH',
    'Esther': 'EST',
    'Job': 'JOB',
    'Psalms': 'PSA',
    'Proverbs': 'PRO',
    'Ecclesiastes': 'ECC',
    'Song of Songs': 'SNG', 'Song of Solomon': 'SNG',
    'Isaiah': 'ISA',
    'Jeremiah': 'JER',
    'Lamentations': 'LAM',
    'Ezekiel': 'EZK',
    'Daniel': 'DAN',
    'Hosea': 'HOS',
    'Joel': 'JOL',
    'Amos': 'AMO',
    'Obadiah': 'OBA',
    'Jonah': 'JON',
    'Micah': 'MIC',
    'Nahum': 'NAM',
    'Habakkuk': 'HAB',
    'Zephaniah': 'ZEP',
    'Haggai': 'HAG',
    'Zechariah': 'ZEC',
    'Malachi': 'MAL',
    
    // Old Testament - Portuguese
    'Gênesis': 'GEN',
    'Êxodo': 'EXO',
    'Levítico': 'LEV',
    'Números': 'NUM',
    'Deuteronômio': 'DEU',
    'Josué': 'JOS',
    'Juízes': 'JDG',
    'Rute': 'RUT',
    '1 Reis': '1KI',
    '2 Reis': '2KI',
    '1 Crônicas': '1CH',
    '2 Crônicas': '2CH',
    'Esdras': 'EZR',
    'Neemias': 'NEH',
    'Ester': 'EST',
    'Jó': 'JOB',
    'Salmos': 'PSA',
    'Provérbios': 'PRO',
    'Eclesiastes': 'ECC',
    'Cânticos': 'SNG', 'Cantares': 'SNG',
    'Isaías': 'ISA',
    'Jeremias': 'JER',
    'Lamentações': 'LAM',
    'Ezequiel': 'EZK',
    'Oséias': 'HOS',
    'Amós': 'AMO',
    'Obadias': 'OBA',
    'Jonas': 'JON',
    'Miquéias': 'MIC',
    'Naum': 'NAM',
    'Habacuque': 'HAB',
    'Sofonias': 'ZEP',
    'Ageu': 'HAG',
    'Zacarias': 'ZEC',
    'Malaquias': 'MAL',
    
    // New Testament - English
    'Matthew': 'MAT',
    'Mark': 'MRK',
    'Luke': 'LUK',
    'John': 'JHN',
    'Acts': 'ACT',
    'Romans': 'ROM',
    '1 Corinthians': '1CO',
    '2 Corinthians': '2CO',
    'Galatians': 'GAL',
    'Ephesians': 'EPH',
    'Philippians': 'PHP',
    'Colossians': 'COL',
    '1 Thessalonians': '1TH',
    '2 Thessalonians': '2TH',
    '1 Timothy': '1TI',
    '2 Timothy': '2TI',
    'Titus': 'TIT',
    'Philemon': 'PHM',
    'Hebrews': 'HEB',
    'James': 'JAS',
    '1 Peter': '1PE',
    '2 Peter': '2PE',
    '1 John': '1JN',
    '2 John': '2JN',
    '3 John': '3JN',
    'Jude': 'JUD',
    'Revelation': 'REV',
    
    // New Testament - Portuguese
    'Mateus': 'MAT',
    'Marcos': 'MRK',
    'Lucas': 'LUK',
    'João': 'JHN',
    'Atos': 'ACT',
    'Romanos': 'ROM',
    '1 Coríntios': '1CO',
    '2 Coríntios': '2CO',
    'Gálatas': 'GAL',
    'Efésios': 'EPH',
    'Filipenses': 'PHP',
    'Colossenses': 'COL',
    '1 Tessalonicenses': '1TH',
    '2 Tessalonicenses': '2TH',
    '1 Timóteo': '1TI',
    '2 Timóteo': '2TI',
    'Tito': 'TIT',
    'Filemom': 'PHM',
    'Hebreus': 'HEB',
    'Tiago': 'JAS',
    '1 Pedro': '1PE',
    '2 Pedro': '2PE',
    '1 João': '1JN',
    '2 João': '2JN',
    '3 João': '3JN',
    'Judas': 'JUD',
    'Apocalipse': 'REV',
    
    // Book IDs mapping to themselves (for cases where ID is passed instead of name)
    'GEN': 'GEN', 'EXO': 'EXO', 'LEV': 'LEV', 'NUM': 'NUM', 'DEU': 'DEU',
    'JOS': 'JOS', 'JDG': 'JDG', 'RUT': 'RUT', '1SA': '1SA', '2SA': '2SA',
    '1KI': '1KI', '2KI': '2KI', '1CH': '1CH', '2CH': '2CH', 'EZR': 'EZR',
    'NEH': 'NEH', 'EST': 'EST', 'JOB': 'JOB', 'PSA': 'PSA', 'PRO': 'PRO',
    'ECC': 'ECC', 'SNG': 'SNG', 'ISA': 'ISA', 'JER': 'JER', 'LAM': 'LAM',
    'EZK': 'EZK', 'DAN': 'DAN', 'HOS': 'HOS', 'JOL': 'JOL', 'AMO': 'AMO',
    'OBA': 'OBA', 'JON': 'JON', 'MIC': 'MIC', 'NAM': 'NAM', 'HAB': 'HAB',
    'ZEP': 'ZEP', 'HAG': 'HAG', 'ZEC': 'ZEC', 'MAL': 'MAL',
    'MAT': 'MAT', 'MRK': 'MRK', 'LUK': 'LUK', 'JHN': 'JHN', 'ACT': 'ACT', 'ROM': 'ROM',
    '1CO': '1CO', '2CO': '2CO', 'GAL': 'GAL', 'EPH': 'EPH', 'PHP': 'PHP',
    'COL': 'COL', '1TH': '1TH', '2TH': '2TH', '1TI': '1TI', '2TI': '2TI',
    'TIT': 'TIT', 'PHM': 'PHM', 'HEB': 'HEB', 'JAS': 'JAS', '1PE': '1PE',
    '2PE': '2PE', '1JN': '1JN', '2JN': '2JN', '3JN': '3JN', 'JUD': 'JUD',
    'REV': 'REV',
  };

  /// Get available Bible versions (fetches from API and filters popular ones)
  Future<List<BibleVersionInfo>> getAvailableVersions([String? language]) async {
    try {
      // Always clear cache and fetch fresh data to ensure updated versions
      await _clearAllCache();

      // Fetch from API
      final response = await http.get(
        Uri.parse('$_baseUrl/bibles'),
        headers: {
          'api-key': _apiKey,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📖 API Response received: ${data['data']?.length ?? 0} total bibles');
        
        final allVersions = _parseVersionsResponse(data);
        print('📖 Parsed ${allVersions.length} versions from API');
        
        // Filter to get only our target popular versions
        final popularVersionsList = _filterPopularVersions(allVersions);
        print('📖 Filtered to ${popularVersionsList.length} popular versions');
        
        // Update static popular versions map
        _popularVersions.clear();
        for (final version in popularVersionsList) {
          _popularVersions[version.abbreviation] = version;
        }
        
        // Cache the result
        await _cacheVersions(popularVersionsList);
        
        // Add enabled imported Bibles
        final combinedVersions = await _addImportedBibles(popularVersionsList);
        
        if (language != null) {
          return combinedVersions.where((v) => v.language == language).toList();
        }
        return combinedVersions;
      } else {
        final errorBody = response.body;
        print('❌ API Error ${response.statusCode}: $errorBody');
        throw Exception('Erro ao carregar versões: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      _isOfflineMode = true;
      print('📱 Erro ao buscar versões: $e');
      
      // Return hardcoded popular versions as fallback
      final fallbackVersions = _getFallbackVersions();
      
      // Update static popular versions map
      _popularVersions.clear();
      for (final version in fallbackVersions) {
        _popularVersions[version.abbreviation] = version;
      }
      
      // Add enabled imported Bibles even when offline
      final combinedVersions = await _addImportedBibles(fallbackVersions);
      
      if (language != null) {
        return combinedVersions.where((v) => v.language == language).toList();
      }
      return combinedVersions;
    }
  }

  /// Add enabled imported Bibles to the list of available versions
  static Future<List<BibleVersionInfo>> _addImportedBibles(List<BibleVersionInfo> apiVersions) async {
    try {
      final importedBibles = await _xmlBibleService.getImportedBibles();
      final enabledIds = await _xmlBibleService.getEnabledImportedBibles();
      
      // Mobile stub - return empty list
      final enabledImportedBibles = <BibleVersionInfo>[];
      
      // Mobile compatibility - skip caching
      // for (final bible in enabledImportedBibles) {
      //   _popularVersions[bible.abbreviation] = bible;
      // }
      
      // Combine API versions with enabled imported Bibles
      final combinedList = <BibleVersionInfo>[];
      combinedList.addAll(apiVersions);
      combinedList.addAll(enabledImportedBibles);
      
      return combinedList;
    } catch (e) {
      print('Error adding imported Bibles: $e');
      return apiVersions; // Return original list if error
    }
  }

  /// Search verses by reference (e.g., "John 3:16", "João 3:16")
  Future<List<BibleVerse>> searchVersesByReference(String reference, String versionId) async {
    try {
      // Check if this is an imported Bible
      if (versionId.startsWith('imported_')) {
        return await _searchInImportedBible(reference, versionId);
      }

      // Try cache first for API Bibles
      final cacheKey = '${versionId}_${reference.toLowerCase()}';
      final cachedVerses = await _getCachedVerses(cacheKey);
      if (cachedVerses.isNotEmpty) {
        return cachedVerses;
      }

      // Parse reference for API call
      final parsedRef = _parseReference(reference);
      if (parsedRef == null) {
        throw Exception('Referência inválida: $reference');
      }

      // Get book ID from API first
      final bookId = await _getBookId(parsedRef['book'], versionId);
      if (bookId == null) {
        throw Exception('Livro não encontrado: "${parsedRef['book']}". Tente nomes como "Gênesis", "João", "Mateus".');
      }

      // Construct passage ID
      String passageId = '$bookId.${parsedRef['chapter']}';
      if (parsedRef['startVerse'] != null) {
        passageId += '.${parsedRef['startVerse']}';
        if (parsedRef['endVerse'] != null) {
          passageId += '-${parsedRef['endVerse']}';
        }
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/bibles/$versionId/passages/$passageId?content-type=text&include-verse-numbers=true'),
        headers: {
          'api-key': _apiKey,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📖 Passage response received for $passageId');
        
        final verses = _parsePassageResponse(data, versionId);
        print('📖 Parsed ${verses.length} verses from passage');
        
        // Cache the result
        await _cacheVerses(cacheKey, verses);
        
        return verses;
      } else {
        final errorBody = response.body;
        print('❌ Passage API Error ${response.statusCode}: $errorBody');
        throw Exception('Erro na API: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      _isOfflineMode = true;
      print('📱 Erro ao buscar versículo: $e');
      
      // Clear cache if there's an API error
      if (e.toString().contains('404') || e.toString().contains('Livro não encontrado')) {
        final errorCacheKey = '${versionId}_${reference.toLowerCase()}';
        await _clearCacheForKey(errorCacheKey);
      }
      
      throw Exception('Não foi possível encontrar o versículo: $reference');
    }
  }

  /// Search verses by keywords
  Future<List<BibleVerse>> searchVersesByKeywords(String keywords, String versionId, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bibles/$versionId/search?query=${Uri.encodeComponent(keywords)}&limit=$limit'),
        headers: {
          'api-key': _apiKey,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📖 Search response received for "$keywords"');
        
        final results = _parseSearchResponse(data, versionId);
        print('📖 Found ${results.length} search results');
        
        return results;
      } else {
        final errorBody = response.body;
        print('❌ Search API Error ${response.statusCode}: $errorBody');
        throw Exception('Erro na busca: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      _isOfflineMode = true;
      print('📱 Erro na busca: $e');
      throw Exception('Não foi possível realizar a busca');
    }
  }

  /// Search verses in imported Bible (XML or SQLite)
  Future<List<BibleVerse>> _searchInImportedBible(String reference, String versionId) async {
    try {
      // Parse reference
      final parsedRef = _parseReference(reference);
      if (parsedRef == null) {
        throw Exception('Referência inválida: $reference');
      }

      final bookName = parsedRef['book'];
      final chapter = parsedRef['chapter'];
      final startVerse = parsedRef['startVerse'];
      final endVerse = parsedRef['endVerse'];

      // XML Bible only
      final results = await _xmlBibleService.searchVersesInXmlBible(
        versionId,
        bookName,
        chapter,
        // startVerse: startVerse,
        // endVerse: endVerse,
      );
      return results.cast<BibleVerse>();
    } catch (e) {
      print('Error searching in imported Bible: $e');
      throw Exception('Erro ao buscar na Bíblia importada: $e');
    }
  }

  /// Get chapter content
  Future<List<BibleVerse>> getChapterVerses(String book, int chapter, String versionId) async {
    try {
      // Check if this is an imported Bible
      if (versionId.startsWith('imported_')) {
        final results = await _xmlBibleService.searchVersesInXmlBible(versionId, book, chapter);
        return results.cast<BibleVerse>();
      }

      final cacheKey = '${versionId}_chapter_${book}_$chapter';
      
      // Try cache first for API Bibles
      final cachedVerses = await _getCachedVerses(cacheKey);
      if (cachedVerses.isNotEmpty) {
        return cachedVerses;
      }

      // Get book ID from API
      final bookId = await _getBookId(book, versionId);
      if (bookId == null) {
        throw Exception('Livro não encontrado: "$book". Verifique se o nome está correto.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/bibles/$versionId/chapters/$bookId.$chapter?content-type=text&include-verse-numbers=true'),
        headers: {
          'api-key': _apiKey,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📖 Chapter response received for $bookId.$chapter');
        
        final verses = _parseChapterResponse(data, versionId);
        print('📖 Parsed ${verses.length} verses from chapter');
        
        // Cache the result
        await _cacheVerses(cacheKey, verses);
        
        return verses;
      } else {
        final errorBody = response.body;
        print('❌ Chapter API Error ${response.statusCode}: $errorBody');
        throw Exception('Erro ao carregar capítulo: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      _isOfflineMode = true;
      print('📱 Erro ao carregar capítulo: $e');
      
      // Clear cache if there's an API error
      if (e.toString().contains('404') || e.toString().contains('Livro não encontrado')) {
        final errorCacheKey = '${versionId}_chapter_${book}_$chapter';
        await _clearCacheForKey(errorCacheKey);
      }
      
      throw Exception('Não foi possível carregar o capítulo');
    }
  }

  /// Get book ID from book name
  Future<String?> _getBookId(String bookName, String versionId) async {
    print('🔍 Looking for book: "$bookName"');
    
    // First try direct mapping
    final directMapping = bookMapping[bookName];
    if (directMapping != null) {
      print('✅ Found direct mapping: "$bookName" -> "$directMapping"');
      return directMapping;
    }
    
    print('❌ No direct mapping found for "$bookName"');
    
    // Try case-insensitive mapping
    for (final entry in bookMapping.entries) {
      if (entry.key.toLowerCase() == bookName.toLowerCase()) {
        print('✅ Found case-insensitive mapping: "${entry.key}" -> "${entry.value}"');
        return entry.value;
      }
    }
    
    print('❌ No case-insensitive mapping found for "$bookName"');
    
    // Fallback to API search
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bibles/$versionId/books'),
        headers: {
          'api-key': _apiKey,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final books = data['data'] as List;
        
        print('📚 Available books in version $versionId:');
        for (final book in books) {
          print('  "${book['id']}" - "${book['name']}" (${book['nameLong']})');
        }
        
        // First try exact match
        for (final book in books) {
          final name = book['name']?.toLowerCase() ?? '';
          final nameLong = book['nameLong']?.toLowerCase() ?? '';
          
          if (name == bookName.toLowerCase() || nameLong == bookName.toLowerCase()) {
            return book['id'];
          }
        }
        
        // Then try contains match
        for (final book in books) {
          final name = book['name']?.toLowerCase() ?? '';
          final nameLong = book['nameLong']?.toLowerCase() ?? '';
          
          if (name.contains(bookName.toLowerCase()) || 
              nameLong.contains(bookName.toLowerCase()) ||
              bookName.toLowerCase().contains(name)) {
            return book['id'];
          }
        }
      }
    } catch (e) {
      print('Erro ao buscar ID do livro: $e');
    }
    return null;
  }

  // Private methods for caching

  Future<void> _cacheVersions(List<BibleVersionInfo> versions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'versions': versions.map((v) => v.toJson()).toList(),
      };
      await prefs.setString(_cacheVersionsKey, json.encode(data));
    } catch (e) {
      print('Error caching versions: $e');
    }
  }

  Future<List<BibleVerse>> _getCachedVerses(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('${_cacheVersesKey}_$key');
      if (cached != null) {
        final data = json.decode(cached);
        final timestamp = DateTime.parse(data['timestamp']);
        if (DateTime.now().difference(timestamp) < _cacheExpiry) {
          return (data['verses'] as List)
              .map((v) => BibleVerse.fromJson(v))
              .toList();
        }
      }
    } catch (e) {
      print('Error reading cached verses: $e');
    }
    return [];
  }

  Future<void> _cacheVerses(String key, List<BibleVerse> verses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'verses': verses.map((v) => v.toJson()).toList(),
      };
      await prefs.setString('${_cacheVersesKey}_$key', json.encode(data));
    } catch (e) {
      print('Error caching verses: $e');
    }
  }

  Future<void> _clearCacheForKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cacheVersesKey}_$key');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<void> _clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheVersionsKey);
      print('🗑️ Cache completo das versões limpo');
    } catch (e) {
      print('Error clearing all cache: $e');
    }
  }

  /// Get hardcoded fallback versions when API fails
  List<BibleVersionInfo> _getFallbackVersions() {
    final fallback = <BibleVersionInfo>[];
    
    // Map of our target abbreviations to known API IDs  
    final Map<String, String> knownIds = {
      // English only - apenas as versões que funcionam na API
      'KJV': 'de4e12af7f28f599-01',     // King James (Authorised) Version
      'ASV': '685d1470fe4d5c3b-01',     // American Standard Version (Byzantine Text with Apocrypha)
      'BSB': 'bba9f40183526463-01',     // Berean Standard Bible
    };
    
    // Create fallback versions from our target configurations
    for (final langEntry in _targetVersions.entries) {
      final language = langEntry.key;
      final targetVersions = langEntry.value;
      
      for (final versionEntry in targetVersions.entries) {
        final targetAbbr = versionEntry.key;
        final targetName = versionEntry.value;
        final knownId = knownIds[targetAbbr];
        
        if (knownId != null) {
          fallback.add(BibleVersionInfo(
            id: knownId,
            name: targetName,
            abbreviation: targetAbbr,
            language: language,
            isPopular: true,
          ));
        }
      }
    }
    
    return fallback;
  }

  // Parse API responses
  List<BibleVersionInfo> _parseVersionsResponse(dynamic data) {
    final versions = <BibleVersionInfo>[];
    try {
      final bibles = data['data'] as List;
      for (final bible in bibles) {
        // Only English versions
        String language = 'en';
        
        // We'll determine popularity later in filtering
        bool isPopular = false;
        
        versions.add(BibleVersionInfo(
          id: bible['id'] ?? '',
          name: bible['name'] ?? '',
          abbreviation: bible['abbreviation'] ?? '',
          language: language,
          isPopular: isPopular,
        ));
      }
    } catch (e) {
      print('Error parsing versions response: $e');
    }
    return versions;
  }

  List<BibleVerse> _parsePassageResponse(dynamic data, String versionId) {
    final verses = <BibleVerse>[];
    try {
      final passage = data['data'];
      final content = passage['content'] ?? '';
      final reference = passage['reference'] ?? '';
      
      // Simple parsing - can be enhanced to split by verse numbers
      final versionAbbr = _getVersionAbbreviation(versionId);
      
      verses.add(BibleVerse(
        reference: reference,
        text: _cleanHtmlContent(content),
        version: versionAbbr,
        book: _extractBookFromReference(reference),
        chapter: _extractChapterFromReference(reference),
        verse: _extractVerseFromReference(reference),
      ));
    } catch (e) {
      print('Error parsing passage response: $e');
    }
    return verses;
  }

  List<BibleVerse> _parseSearchResponse(dynamic data, String versionId) {
    final verses = <BibleVerse>[];
    try {
      final results = data['data']['verses'] as List;
      final versionAbbr = _getVersionAbbreviation(versionId);
      
      for (final result in results) {
        verses.add(BibleVerse(
          reference: result['reference'] ?? '',
          text: _cleanHtmlContent(result['text'] ?? ''),
          version: versionAbbr,
          book: _extractBookFromReference(result['reference'] ?? ''),
          chapter: _extractChapterFromReference(result['reference'] ?? ''),
          verse: _extractVerseFromReference(result['reference'] ?? ''),
        ));
      }
    } catch (e) {
      print('Error parsing search response: $e');
    }
    return verses;
  }

  List<BibleVerse> _parseChapterResponse(dynamic data, String versionId) {
    final verses = <BibleVerse>[];
    try {
      final chapter = data['data'];
      final content = chapter['content'] ?? '';
      final reference = chapter['reference'] ?? '';
      final versionAbbr = _getVersionAbbreviation(versionId);
      
      print('📖 Debug - Content received: ${content.length} characters');
      
      // Multiple parsing strategies for different content formats
      
      // Strategy 1: Try with verse span tags
      var verseRegex = RegExp(r'<span[^>]*class="v"[^>]*>(\d+)</span>([^<]*(?:<[^>]*>[^<]*)*?)(?=<span[^>]*class="v"|$)', multiLine: true, dotAll: true);
      var matches = verseRegex.allMatches(content);
      
      if (matches.isEmpty) {
        // Strategy 2: Try with different verse markers
        verseRegex = RegExp(r'<span[^>]*data-number="(\d+)"[^>]*></span>([^<]*(?:<[^>]*>[^<]*)*?)(?=<span[^>]*data-number|$)', multiLine: true, dotAll: true);
        matches = verseRegex.allMatches(content);
      }
      
      if (matches.isEmpty) {
        // Strategy 3: Try with verse numbers in brackets or parentheses
        verseRegex = RegExp(r'[\[\(](\d+)[\]\)]([^[\(]*?)(?=[\[\(]\d+|$)', multiLine: true);
        matches = verseRegex.allMatches(content);
      }
      
      if (matches.isEmpty) {
        // Strategy 4: Split by verse indicators and try to parse
        final cleanContent = _cleanHtmlContent(content);
        final verseIndicators = RegExp(r'(\d+)\s+([^0-9]+?)(?=\d+\s|$)');
        matches = verseIndicators.allMatches(cleanContent);
      }
      
      if (matches.isNotEmpty) {
        for (final match in matches) {
          final verseNumber = int.tryParse(match.group(1) ?? '1') ?? 1;
          final verseText = _cleanHtmlContent(match.group(2) ?? '').trim();
          
          if (verseText.isNotEmpty && verseText.length > 5) { // Avoid empty or too short texts
            verses.add(BibleVerse(
              reference: '$reference:$verseNumber',
              text: verseText,
              version: versionAbbr,
              book: _extractBookFromReference(reference),
              chapter: _extractChapterFromReference(reference),
              verse: verseNumber,
            ));
          }
        }
      } else {
        // Fallback: Return the whole content as one verse if no parsing worked
        final cleanContent = _cleanHtmlContent(content).trim();
        if (cleanContent.isNotEmpty) {
          verses.add(BibleVerse(
            reference: reference,
            text: cleanContent,
            version: versionAbbr,
            book: _extractBookFromReference(reference),
            chapter: _extractChapterFromReference(reference),
            verse: 1,
          ));
        }
      }
      
      print('📖 Debug - Parsed ${verses.length} verses');
      
    } catch (e) {
      print('❌ Error parsing chapter response: $e');
    }
    return verses;
  }

  String _getVersionAbbreviation(String versionId) {
    for (final entry in _popularVersions.entries) {
      if (entry.value.id == versionId) {
        return entry.key;
      }
    }
    return 'UNKNOWN';
  }

  String _cleanHtmlContent(String content) {
    return content
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', multiLine: true, dotAll: true), '') // Remove scripts
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', multiLine: true, dotAll: true), '') // Remove styles
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'&nbsp;'), ' ') // Replace non-breaking spaces
        .replaceAll(RegExp(r'&amp;'), '&') // Replace encoded ampersands
        .replaceAll(RegExp(r'&lt;'), '<') // Replace encoded less than
        .replaceAll(RegExp(r'&gt;'), '>') // Replace encoded greater than
        .replaceAll(RegExp(r'&quot;'), '"') // Replace encoded quotes
        .replaceAll(RegExp(r'&#(\d+);'), '') // Remove numeric entities
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  String _extractBookFromReference(String reference) {
    final match = RegExp(r'^([^0-9]+)').firstMatch(reference);
    return match?.group(1)?.trim() ?? '';
  }

  int _extractChapterFromReference(String reference) {
    final match = RegExp(r'(\d+)').firstMatch(reference);
    return int.tryParse(match?.group(1) ?? '1') ?? 1;
  }

  int _extractVerseFromReference(String reference) {
    final match = RegExp(r':(\d+)').firstMatch(reference);
    return int.tryParse(match?.group(1) ?? '1') ?? 1;
  }

  // Simple reference parser
  Map<String, dynamic>? _parseReference(String reference) {
    final regex = RegExp(r'^(.+?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$');
    final match = regex.firstMatch(reference.trim());
    
    if (match != null) {
      return {
        'book': match.group(1),
        'chapter': int.parse(match.group(2)!),
        'startVerse': match.group(3) != null ? int.parse(match.group(3)!) : null,
        'endVerse': match.group(4) != null ? int.parse(match.group(4)!) : null,
      };
    }
    return null;
  }
  
  /// Filter versions to get only our target popular ones
  List<BibleVersionInfo> _filterPopularVersions(List<BibleVersionInfo> allVersions) {
    final filtered = <BibleVersionInfo>[];
    
    // Map of our target abbreviations to known API IDs
    final Map<String, String> knownIds = {
      // English only - apenas as versões que funcionam na API
      'KJV': 'de4e12af7f28f599-01',     // King James (Authorised) Version
      'ASV': '685d1470fe4d5c3b-01',     // American Standard Version (Byzantine Text with Apocrypha)
      'BSB': 'bba9f40183526463-01',     // Berean Standard Bible
    };
    
    // For each target language and version
    for (final langEntry in _targetVersions.entries) {
      final language = langEntry.key;
      final targetVersions = langEntry.value;
      
      for (final versionEntry in targetVersions.entries) {
        final targetAbbr = versionEntry.key;
        final targetName = versionEntry.value;
        
        // First try to find by known ID
        final knownId = knownIds[targetAbbr];
        if (knownId != null) {
          final matchById = allVersions.where((v) => v.id == knownId).toList();
          if (matchById.isNotEmpty) {
            final selectedVersion = matchById.first;
            filtered.add(BibleVersionInfo(
              id: selectedVersion.id,
              name: selectedVersion.name,
              abbreviation: targetAbbr, // Use our target abbreviation
              language: language,
              isPopular: true,
            ));
            continue;
          }
        }
        
        // Fallback: Find matching version in API results by name/abbreviation
        final match = allVersions.where((v) {
          final abbr = v.abbreviation.toUpperCase();
          final name = v.name.toLowerCase();
          final targetNameLower = targetName.toLowerCase();
          
          // Try exact abbreviation match first
          if (abbr == targetAbbr.toUpperCase()) return true;
          
          // Try name contains match
          if (name.contains(targetNameLower) || targetNameLower.contains(name)) {
            return true;
          }
          
          // Special cases for better matching - apenas as 3 versões que funcionam
          if (targetAbbr == 'KJV' && name.contains('king james')) return true;
          if (targetAbbr == 'ASV' && name.contains('american standard')) return true;
          if (targetAbbr == 'BSB' && name.contains('berean')) return true;
          
          return false;
        }).toList();
        
        if (match.isNotEmpty) {
          // Use the first match, but prefer exact abbreviation matches
          match.sort((a, b) {
            if (a.abbreviation.toUpperCase() == targetAbbr.toUpperCase()) return -1;
            if (b.abbreviation.toUpperCase() == targetAbbr.toUpperCase()) return 1;
            return 0;
          });
          
          final selectedVersion = match.first;
          
          // Create version with correct abbreviation for display
          filtered.add(BibleVersionInfo(
            id: selectedVersion.id,
            name: selectedVersion.name,
            abbreviation: targetAbbr, // Use our target abbreviation
            language: language,
            isPopular: true,
          ));
        }
      }
    }
    
    return filtered;
  }
  
  /// Test API connectivity and version fetching
  Future<bool> testApiConnection() async {
    try {
      print('🔍 Testing API connection to $_baseUrl');
      print('🔍 Using API Key: ${_apiKey.substring(0, 8)}...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/bibles'),
        headers: {
          'api-key': _apiKey,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('🔍 API Test - Status: ${response.statusCode}');
      print('🔍 API Test - Headers sent: api-key, Accept, Content-Type');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = (data['data'] as List?)?.length ?? 0;
        print('🔍 API Test - Found $count versions');
        print('✅ API connection successful');
        _isOfflineMode = false;
        return true;
      } else {
        print('❌ API Test failed with status ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        _isOfflineMode = true;
        return false;
      }
    } catch (e) {
      print('🔍 API Test - Error: $e');
      _isOfflineMode = true;
      return false;
    }
  }

  /// Get API status information
  static Map<String, dynamic> getApiStatus() {
    return {
      'isOffline': _isOfflineMode,
      'baseUrl': _baseUrl,
      'hasApiKey': _apiKey.isNotEmpty,
      'apiKeyPreview': _apiKey.isNotEmpty ? '${_apiKey.substring(0, 8)}...' : 'Missing',
      'popularVersionsLoaded': _popularVersions.isNotEmpty,
      'popularVersionsCount': _popularVersions.length,
    };
  }

  /// Clear all cache and reset state
  static Future<void> resetService() async {
    _isOfflineMode = false;
    _popularVersions.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheVersionsKey);
      // Clear all verse caches
      final keys = prefs.getKeys().where((key) => key.startsWith(_cacheVersesKey));
      for (final key in keys) {
        await prefs.remove(key);
      }
      print('🔄 Scripture API Service reset complete');
    } catch (e) {
      print('❌ Error resetting service: $e');
    }
  }
}