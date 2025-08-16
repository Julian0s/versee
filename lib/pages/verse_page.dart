import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/models/bible_models.dart';
import 'package:versee/pages/create_selection_page.dart';
import 'package:versee/pages/presenter_page.dart';
import 'package:versee/services/scripture_api_service.dart';
import 'package:versee/services/language_service.dart';

class VersePage extends StatefulWidget {
  final BibleBook book;
  final int chapter;
  final String version;

  const VersePage({
    super.key,
    required this.book,
    required this.chapter,
    required this.version,
  });

  @override
  State<VersePage> createState() => _VersePageState();
}

class _VersePageState extends State<VersePage> {
  Set<int> _selectedVerses = {};
  List<BibleVerse> _verses = [];
  bool _isLoading = true;
  String? _errorMessage;
  late final ScriptureApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ScriptureApiService();
    _loadChapterVerses();
  }

  Future<void> _loadChapterVerses() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get version ID from popular versions
      await _apiService.getAvailableVersions(); // Ensure versions are loaded
      final versionInfo = ScriptureApiService.popularVersions.values.firstWhere(
        (v) => v.abbreviation == widget.version,
        orElse: () => ScriptureApiService.popularVersions.values.isNotEmpty 
            ? ScriptureApiService.popularVersions.values.first
            : const BibleVersionInfo(
                id: 'de4e12af7f28f599-01', 
                name: 'King James Version', 
                abbreviation: 'KJV', 
                language: 'en', 
                isPopular: true,
              ),
      );

      final verses = await _apiService.getChapterVerses(
        widget.book.id,
        widget.chapter,
        versionInfo.id,
      );

      if (mounted) {
        setState(() {
          _verses = verses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.book.name} ${widget.chapter}'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (_selectedVerses.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedVerses.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Chapter info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.version,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_verses.length} versículos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // Verses list
          Expanded(
            child: _buildVersesList(),
          ),
        ],
      ),
      
      // Bottom action bar when verses are selected
      bottomNavigationBar: _selectedVerses.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedVerses.length} versículo(s) selecionado(s)',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getSelectedVersesText(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botão de apresentação rápida
                    IconButton(
                      onPressed: _presentNow,
                      icon: const Icon(Icons.play_circle_filled),
                      tooltip: 'Apresentar Agora',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _createNewSelection,
                      icon: const Icon(Icons.add),
                      label: const Text('Criar Nova Seleção'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildVersesList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando versículos...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar versículos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChapterVerses,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_verses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Consumer<LanguageService>(
              builder: (context, languageService, child) {
                return Text(
                  languageService.strings.noVerseFound,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _verses.length,
      itemBuilder: (context, index) {
        final verse = _verses[index];
        final isSelected = _selectedVerses.contains(verse.verse);
        
        return VerseCard(
          verse: verse,
          isSelected: isSelected,
          onTap: () => _toggleVerseSelection(verse.verse),
        );
      },
    );
  }

  void _toggleVerseSelection(int verseNumber) {
    setState(() {
      if (_selectedVerses.contains(verseNumber)) {
        _selectedVerses.remove(verseNumber);
      } else {
        _selectedVerses.add(verseNumber);
      }
    });
  }

  String _getSelectedVersesText() {
    final sortedVerses = _selectedVerses.toList()..sort();
    if (sortedVerses.length <= 3) {
      return sortedVerses.map((v) => '${widget.book.name} ${widget.chapter}:$v').join(', ');
    } else {
      return '${widget.book.name} ${widget.chapter}:${sortedVerses.first}-${sortedVerses.last} e outros';
    }
  }

  void _createNewSelection() {
    final selectedVerseObjects = _verses
        .where((verse) => _selectedVerses.contains(verse.verse))
        .toList();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateSelectionPage(
          selectedVerses: selectedVerseObjects,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Clear selection after successful creation
        setState(() {
          _selectedVerses.clear();
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nova seleção criada com sucesso!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            action: SnackBarAction(
              label: 'Ver',
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {
                // Navigate to saved collections
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        );
      }
    });
  }

  void _presentNow() {
    final selectedVerseObjects = _verses
        .where((verse) => _selectedVerses.contains(verse.verse))
        .toList();
    
    if (selectedVerseObjects.isEmpty) return;
    
    // Create temporary collection for presentation
    final tempCollection = VerseCollection(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: '${widget.book.name} ${widget.chapter} - Seleção Temporária',
      verses: selectedVerseObjects,
      createdDate: DateTime.now(),
    );
    
    // Start presentation
    PresenterNavigation.startVerseCollectionPresentation(context, tempCollection);
  }
}

class VerseCard extends StatelessWidget {
  final BibleVerse verse;
  final bool isSelected;
  final VoidCallback onTap;

  const VerseCard({
    super.key,
    required this.verse,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verse number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : Text(
                            verse.verse.toString(),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Verse text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verse.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Selecionado',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
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