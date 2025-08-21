import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/pages/chapter_list_page.dart';
import 'package:versee/pages/slide_view_page.dart';
import 'package:versee/pages/presenter_page.dart';
import 'package:versee/providers/riverpod_providers.dart';
import 'package:versee/services/scripture_api_service.dart';
import 'package:versee/services/xml_bible_service.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/utils/playlist_helpers.dart';
import 'package:versee/models/bible_models.dart';
import 'package:versee/services/settings_service.dart';

class BiblePage extends StatefulWidget {
  const BiblePage({super.key});

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> with TickerProviderStateMixin {
  late final TabController _mainTabController;
  late final TabController _testamentTabController;
  String _selectedVersion = 'KJV';
  // late final VerseCollectionService _collectionService; // MIGRADO para Riverpod
  late final ScriptureApiService _apiService;

  List<BibleVersionInfo> _bibleVersions = [];
  bool _isLoadingVersions = true;
  List<BibleVerse> _searchResults = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<SearchHistory> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _testamentTabController = TabController(length: 2, vsync: this);
    // _collectionService = VerseCollectionService(); // MIGRADO
    _apiService = ScriptureApiService();

    // Escutar mudanças no serviço (MIGRADO)
    // _collectionService.addListener(_onCollectionsChanged);

    // Carregar configurações salvas
    _loadSavedBibleVersion();
    // Carregar versões da Bíblia
    _loadBibleVersions();
    _loadRecentSearches();
  }

  /// Force reload of Bible versions (useful when coming back from settings)
  Future<void> reloadBibleVersions() async {
    setState(() {
      _isLoadingVersions = true;
    });
    await _loadBibleVersions();
  }

  @override
  void dispose() {
    // _collectionService.removeListener(_onCollectionsChanged); // MIGRADO
    _mainTabController.dispose();
    _testamentTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onCollectionsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Carrega a versão da Bíblia salva nas configurações
  Future<void> _loadSavedBibleVersion() async {
    // final userSettings = UserSettingsService(); // MIGRADO
    await userSettings.loadSettings();
    setState(() {
      _selectedVersion = userSettings.selectedBibleVersion;
    });
    debugPrint('✅ Versão da Bíblia carregada: $_selectedVersion');
  }

  Future<void> _loadBibleVersions() async {
    try {
      // Reset do serviço se necessário
      if (ScriptureApiService.isOfflineMode) {
        ScriptureApiService.resetOfflineMode();
      }

      // Get imported XML Bibles FIRST (priority)
      final xmlService = XmlBibleService();
      
      // IMPORTANTE: Limpar duplicatas antes de carregar
      // await xmlService.removeDuplicates(); // Temporariamente desabilitado
      
      final importedBibles = <dynamic>[]; // await xmlService.getImportedBibles();
      final enabledImportedIds = <String>[]; // await xmlService.getEnabledImportedBibles();
      
      debugPrint('📖 DEBUG: Found ${importedBibles.length} total imported Bibles');
      debugPrint('📖 DEBUG: Enabled IDs: $enabledImportedIds');
      for (var bible in importedBibles) {
        debugPrint('📖 DEBUG: Bible ${bible.name} (${bible.abbreviation}) - ID: ${bible.id} - isImported: ${bible.isImported}');
      }
      
      // Filter imported Bibles to only include enabled ones
      final enabledImportedBibles = importedBibles.where((bible) {
        final isEnabled = enabledImportedIds.contains(bible.id);
        debugPrint('📖 DEBUG: Bible ${bible.abbreviation} enabled check: $isEnabled');
        return isEnabled;
      }).toList();
      
      debugPrint('📖 DEBUG: After filtering, ${enabledImportedBibles.length} enabled XML Bibles:');
      for (var bible in enabledImportedBibles) {
        debugPrint('📖 DEBUG: - ${bible.name} (${bible.abbreviation})');
      }

      // Get all available versions from API
      final allVersions = await _apiService.getAvailableVersions();
      
      // Get enabled version abbreviations from settings (only for API versions)
      final enabledAbbreviations = await SettingsService.getEnabledVersionAbbreviations();
      
      // Filter API versions based on settings, but fallback to all versions if none enabled
      List<BibleVersionInfo> filteredApiVersions;
      if (enabledAbbreviations.isNotEmpty) {
        filteredApiVersions = allVersions.where((version) {
          return enabledAbbreviations.contains(version.abbreviation);
        }).toList();
      } else {
        // Fallback to all versions if no settings found
        filteredApiVersions = allVersions;
      }
      
      // ALWAYS combine: XML Bibles first, then API versions
      final combinedVersions = <BibleVersionInfo>[
        ...enabledImportedBibles, // XML Bibles go first
        ...filteredApiVersions,   // API versions go after
      ];
      
      // Ensure we have at least some versions to show
      List<BibleVersionInfo> versionsToShow;
      if (combinedVersions.isNotEmpty) {
        versionsToShow = combinedVersions;
      } else if (enabledImportedBibles.isNotEmpty) {
        // If no API versions but we have XML, show XML only
        versionsToShow = <BibleVersionInfo>[]; // Cast fix
      } else {
        // Last resort: show all API versions
        versionsToShow = allVersions;
      }
      
      // CRITICAL: Final deduplication before showing
      final deduplicatedVersions = <BibleVersionInfo>[];
      final seenKeys = <String>{};
      
      for (final version in versionsToShow) {
        final key = '${version.name.toLowerCase().trim()}-${version.abbreviation.toLowerCase().trim()}';
        if (!seenKeys.contains(key)) {
          seenKeys.add(key);
          deduplicatedVersions.add(version);
        } else {
          debugPrint('🗑️ DROPDOWN: Removed duplicate ${version.name} (${version.abbreviation})');
        }
      }
      
      versionsToShow = deduplicatedVersions;
      
      debugPrint('📖 FINAL: Loaded ${filteredApiVersions.length} API versions and ${enabledImportedBibles.length} imported XML Bibles');
      debugPrint('📖 FINAL: Total versions to show: ${versionsToShow.length}');
      debugPrint('📖 FINAL: Complete versions list:');
      for (var version in versionsToShow) {
        debugPrint('📖 FINAL: - ${version.name} (${version.abbreviation}) - isImported: ${version.isImported}');
      }
      
      if (mounted) {
        setState(() {
          _bibleVersions = versionsToShow;
          _isLoadingVersions = false;
          
          // Set default version
          if (versionsToShow.any((v) => v.abbreviation == 'KJV')) {
            _selectedVersion = 'KJV';
          } else if (versionsToShow.isNotEmpty) {
            _selectedVersion = versionsToShow.first.abbreviation;
          }
        });
      }
    } catch (e) {
      print('Error loading Bible versions: $e');
      if (mounted) {
        setState(() {
          _isLoadingVersions = false;
          // Try to get XML imported Bibles as fallback
          _loadXmlBiblesAsFallback();
          
          // Use fallback versions from the service
          var fallbackVersions = ScriptureApiService.popularVersions.values.toList();
          if (fallbackVersions.isEmpty) {
            // Hardcoded fallback to ensure we always have versions
            fallbackVersions = [
              const BibleVersionInfo(
                id: 'de4e12af7f28f599-01',
                name: 'King James Version',
                abbreviation: 'KJV',
                language: 'en',
                isPopular: true,
              ),
              const BibleVersionInfo(
                id: '685d1470fe4d5c3b-01',
                name: 'American Standard Version',
                abbreviation: 'ASV',
                language: 'en',
                isPopular: true,
              ),
              const BibleVersionInfo(
                id: 'bba9f40183526463-01',
                name: 'Berean Standard Bible',
                abbreviation: 'BSB',
                language: 'en',
                isPopular: true,
              ),
            ];
          }
          _bibleVersions = fallbackVersions;
          // Ensure we have a selected version
          if (_bibleVersions.any((v) => v.abbreviation == 'KJV')) {
            _selectedVersion = 'KJV';
          } else if (_bibleVersions.isNotEmpty) {
            _selectedVersion = _bibleVersions.first.abbreviation;
          }
        });
      }
    }
  }

  Future<void> _loadXmlBiblesAsFallback() async {
    try {
      final xmlService = XmlBibleService();
      final importedBibles = await xmlService.getImportedBibles();
      final enabledImportedIds = await xmlService.getEnabledImportedBibles();
      
      // Filter imported Bibles to only include enabled ones
      final enabledImportedBibles = importedBibles.where((bible) {
        return enabledImportedIds.contains(bible['id']); // Cast fix
      }).toList();
      
      if (enabledImportedBibles.isNotEmpty) {
        debugPrint('📖 Using ${enabledImportedBibles.length} XML imported Bibles as fallback');
        // Cast fix - skip importing for now
        // _bibleVersions = [..._bibleVersions, ...enabledImportedBibles];
      }
    } catch (e) {
      debugPrint('Error loading XML Bibles as fallback: $e');
    }
  }

  /// Search verses in imported XML Bible
  Future<List<BibleVerse>> _searchInXmlBible(String query, BibleVersionInfo bibleInfo) async {
    try {
      final xmlService = XmlBibleService();
      
      // Check if it's a reference search (e.g., "João 3:16" or "Genesis 1:1-3")
      final referenceMatch = RegExp(r'(\w+)\s+(\d+):(\d+)(?:-(\d+))?').firstMatch(query);
      
      if (referenceMatch != null) {
        // It's a reference search
        final bookName = referenceMatch.group(1)!;
        final chapter = int.parse(referenceMatch.group(2)!);
        final startVerse = int.parse(referenceMatch.group(3)!);
        final endVerse = referenceMatch.group(4) != null 
            ? int.parse(referenceMatch.group(4)!) 
            : startVerse;
        
        debugPrint('🔍 Searching XML Bible: $bookName $chapter:$startVerse-$endVerse');
        
        final results = await xmlService.searchVersesInXmlBible(
          bibleInfo.id, 
          bookName, 
          chapter,
          // startVerse: startVerse, // Param fix
          // endVerse: endVerse,
        );
        return results.cast<BibleVerse>();
      } else {
        // For keyword searches, we would need to implement full-text search
        // For now, return empty list with a message
        debugPrint('📝 Keyword search in XML Bibles not implemented yet: "$query"');
        return [];
      }
    } catch (e) {
      debugPrint('Error searching XML Bible: $e');
      return [];
    }
  }

  Future<void> _loadRecentSearches() async {
    // Load from SharedPreferences if implemented
    // For now, using sample data
    _recentSearches = [
      SearchHistory(
          query: 'João 3:16',
          timestamp: DateTime.now().subtract(const Duration(hours: 2))),
      SearchHistory(
          query: 'amor de Deus',
          timestamp: DateTime.now().subtract(const Duration(days: 1))),
      SearchHistory(
          query: 'Salmo 23',
          timestamp: DateTime.now().subtract(const Duration(days: 2))),
      SearchHistory(
          query: 'fé',
          timestamp: DateTime.now().subtract(const Duration(days: 3))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Bíblia'),
            if (ScriptureApiService.isOfflineMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off, size: 12, color: Colors.orange),
                    SizedBox(width: 4),
                    Text('Offline',
                        style: TextStyle(fontSize: 10, color: Colors.orange)),
                  ],
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _mainTabController,
          tabs: [
            Tab(text: context.watch<LanguageService>().strings.bible),
            Tab(text: context.watch<LanguageService>().strings.search),
            Tab(text: context.watch<LanguageService>().strings.saved),
          ],
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildBibleTab(),
          _buildSearchTab(),
          _buildSavedTab(),
        ],
      ),
    );
  }

  Widget _buildBibleTab() {
    return Column(
      children: [
        // Bible Version Selector
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: _isLoadingVersions
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedVersion,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  decoration: InputDecoration(
                    labelText: 'Versão da Bíblia',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.book),
                  ),
                  items: _bibleVersions.map((BibleVersionInfo version) {
                    return DropdownMenuItem<String>(
                      value: version.abbreviation,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              version.abbreviation,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                version.name,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedVersion = newValue;
                      });
                      // Salvar a versão selecionada
                      // UserSettingsService().setBibleVersion(newValue); // MIGRADO
                    }
                  },
                ),
        ),

        // Testament Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _testamentTabController,
            tabs: [
              Tab(text: context.watch<LanguageService>().strings.oldTestament),
              Tab(text: context.watch<LanguageService>().strings.newTestament),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
          ),
        ),

        const SizedBox(height: 16),

        // Testament Content
        Expanded(
          child: TabBarView(
            controller: _testamentTabController,
            children: [
              _buildBooksList(isOldTestament: true),
              _buildBooksList(isOldTestament: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBooksList({required bool isOldTestament}) {
    final books = isOldTestament
        ? BibleData.oldTestamentBooks
        : BibleData.newTestamentBooks;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookCard(
          book: book,
          onTap: () => _openBook(book),
        );
      },
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar versículos',
              hintText: 'Ex: João 3:16 ou "amor de Deus"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: () => _showSearchFilters(),
                    ),
            ),
            onSubmitted: (value) => _performSearch(value),
            onChanged: (value) {
              // Real-time search could be implemented here with debouncing
            },
          ),

          const SizedBox(height: 20),

          // Search Results or Recent Searches
          Expanded(
            child: _searchResults.isNotEmpty
                ? _buildSearchResults()
                : _buildRecentSearches(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Resultados da Busca',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchResults.clear();
                  _searchController.clear();
                });
              },
              child: const Text('Limpar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final verse = _searchResults[index];
              return VerseResultCard(
                verse: verse,
                onTap: () => _selectVerse(verse),
                onAddToCollection: () => _addVerseToCollection(verse),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buscas Recentes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: _recentSearches.map((search) {
              return SearchHistoryCard(
                search: search,
                onTap: () => _performSearch(search.query),
                onDelete: () => _deleteSearch(search),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedTab() {
    return Column(
      children: [
        // Header with action
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Slides Salvos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                onPressed: () => _showSortOptions(),
                icon: const Icon(Icons.sort),
                tooltip: 'Ordenar',
              ),
            ],
          ),
        ),

        // Saved verse collections list
        Expanded(
          child: _collectionService.collections.isEmpty
              ? _buildEmptyCollectionState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _collectionService.collections.length,
                  itemBuilder: (context, index) {
                    final collection = _collectionService.collections[index];
                    return VerseCollectionCard(
                      collection: collection,
                      onTap: () => _openCollection(collection),
                      onShare: () => _shareCollection(collection),
                      onDelete: () => _deleteCollection(collection),
                      onAddToPlaylist: () => _addToPlaylist(collection),
                      onPresentNow: () => _presentNow(collection),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyCollectionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.slideshow_outlined,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return Text(
                languageService.strings.noSlidesSaved,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione versículos e crie suas coleções de slides',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openBook(BibleBook book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChapterListPage(
          book: book,
          version: _selectedVersion,
        ),
      ),
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final selectedVersionInfo = _bibleVersions.firstWhere(
        (v) => v.abbreviation == _selectedVersion,
        orElse: () => _bibleVersions.isNotEmpty
            ? _bibleVersions.first
            : const BibleVersionInfo(
                id: '06125adad2d5898a-01',
                name: 'Nova Versão Internacional',
                abbreviation: 'NVI',
                language: 'pt',
                isPopular: true,
              ),
      );

      List<BibleVerse> results;

      // Check if the selected version is an imported XML Bible
      if (selectedVersionInfo.isImported) {
        // Handle XML Bible search
        results = await _searchInXmlBible(query, selectedVersionInfo);
      } else {
        // Check if it's a reference search (contains numbers and colons) or keyword search
        if (RegExp(r'\d+:\d+').hasMatch(query)) {
          results = await _apiService.searchVersesByReference(
              query, selectedVersionInfo.id);
        } else {
          results = await _apiService.searchVersesByKeywords(
              query, selectedVersionInfo.id);
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });

        // Add to recent searches
        _addToRecentSearches(query);

        if (results.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Consumer<LanguageService>(
                builder: (context, languageService, child) {
                  return Text(languageService.strings.noResultsForQuery(query));
                },
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na busca: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _addToRecentSearches(String query) {
    setState(() {
      // Remove if already exists
      _recentSearches
          .removeWhere((s) => s.query.toLowerCase() == query.toLowerCase());

      // Add to the beginning
      _recentSearches.insert(
          0,
          SearchHistory(
            query: query,
            timestamp: DateTime.now(),
          ));

      // Keep only the last 10 searches
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.take(10).toList();
      }
    });
  }

  void _selectVerse(BibleVerse verse) {
    // For now, just show the verse in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(verse.reference),
        content: Text(verse.text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addVerseToCollection(verse);
            },
            child: const Text('Adicionar aos Salvos'),
          ),
        ],
      ),
    );
  }

  void _addVerseToCollection(BibleVerse verse) {
    // This would integrate with the VerseCollectionService
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Versículo ${verse.reference} será adicionado aos salvos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showSearchFilters() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtros de Busca'),
          content: const Text('Filtros de busca serão implementados em breve.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSearch(SearchHistory search) {
    setState(() {
      _recentSearches.remove(search);
    });
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ordenar por'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Data (mais recente)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _collectionService.sortCollections(SortCriteria.dateNewest);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Data (mais antigo)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _collectionService.sortCollections(SortCriteria.dateOldest);
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book),
                title: const Text('Ordem bíblica'),
                onTap: () {
                  Navigator.of(context).pop();
                  _collectionService.sortCollections(SortCriteria.biblical);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Alfabética'),
                onTap: () {
                  Navigator.of(context).pop();
                  _collectionService.sortCollections(SortCriteria.alphabetical);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCollection(VerseCollection collection) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(collection.title),
          content: Text('Como você gostaria de visualizar esta seleção?\n\n'
              '• Preview: Ver slides sem apresentar\n'
              '• Apresentar: Iniciar apresentação diretamente\n'
              '• Solo: Um versículo por vez'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SlideViewPage(collection: collection),
                  ),
                );
              },
              child: const Text('Preview'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                PresenterNavigation.startVerseCollectionPresentation(
                    context, collection);
              },
              child: const Text('Apresentar'),
            ),
          ],
        );
      },
    );
  }

  void _shareCollection(VerseCollection collection) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compartilhando: ${collection.title}'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _addToPlaylist(VerseCollection collection) {
    PlaylistHelpers.addVerseCollectionToPlaylist(
      context,
      collection,
      onCompleted: () {
        // Callback opcional quando concluído
      },
    );
  }

  void _deleteCollection(VerseCollection collection) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remover Slide'),
          content: Text('Deseja remover "${collection.title}" dos salvos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _collectionService.removeCollection(collection.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Slide "${collection.title}" removido'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              },
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );
  }

  void _presentNow(VerseCollection collection) {
    PresenterNavigation.startVerseCollectionPresentation(context, collection);
  }
}

class VerseResultCard extends StatelessWidget {
  final BibleVerse verse;
  final VoidCallback onTap;
  final VoidCallback onAddToCollection;

  const VerseResultCard({
    super.key,
    required this.verse,
    required this.onTap,
    required this.onAddToCollection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        verse.reference,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        verse.version,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onAddToCollection,
                      icon: Icon(
                        Icons.add_box_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      tooltip: 'Adicionar aos Salvos',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  verse.text,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  final BibleBook book;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      book.abbreviation,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${book.chapters} capítulos',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchHistoryCard extends StatelessWidget {
  final SearchHistory search;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SearchHistoryCard({
    super.key,
    required this.search,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    search.query,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VerseCollectionCard extends StatelessWidget {
  final VerseCollection collection;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onPresentNow;

  const VerseCollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
    this.onAddToPlaylist,
    this.onPresentNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.slideshow,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        collection.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'playlist':
                            if (onAddToPlaylist != null) {
                              onAddToPlaylist!();
                            }
                            break;
                          case 'share':
                            onShare();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        if (onAddToPlaylist != null)
                          PopupMenuItem<String>(
                            value: 'playlist',
                            child: Row(
                              children: [
                                Icon(Icons.playlist_add,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                const Text('Adicionar à Playlist'),
                              ],
                            ),
                          ),
                        PopupMenuItem<String>(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              const Text('Compartilhar'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.error),
                              const SizedBox(width: 8),
                              const Text('Remover'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${collection.verses.length} versículos',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${collection.verses.length} slides',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  collection.verses.map((v) => v.reference).join(', '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(collection.createdDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: onPresentNow,
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Presente Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
