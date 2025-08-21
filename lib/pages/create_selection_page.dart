import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/models/bible_models.dart';
import 'package:versee/pages/presenter_page.dart';
import 'package:versee/providers/riverpod_providers.dart';
import 'package:versee/services/language_service.dart';

class CreateSelectionPage extends StatefulWidget {
  final List<BibleVerse> selectedVerses;

  const CreateSelectionPage({
    super.key,
    required this.selectedVerses,
  });

  @override
  State<CreateSelectionPage> createState() => _CreateSelectionPageState();
}

class _CreateSelectionPageState extends State<CreateSelectionPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<BibleVerse> _orderedVerses = [];
  
  @override
  void initState() {
    super.initState();
    _orderedVerses = List.from(widget.selectedVerses);
    
    // Generate a default title based on selected verses
    if (_orderedVerses.isNotEmpty) {
      if (_orderedVerses.length == 1) {
        _titleController.text = _orderedVerses.first.reference;
      } else {
        final firstRef = _orderedVerses.first.reference;
        final lastRef = _orderedVerses.last.reference;
        _titleController.text = '$firstRef - $lastRef';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            return Text(languageService.strings.createNewSelection);
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return TextButton(
                onPressed: _saveSelection,
                child: Text(
                  languageService.strings.save,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        return Text(
                          languageService.strings.selectionInformation,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        return TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: languageService.strings.selectionTitle,
                            hintText: languageService.strings.selectionTitleHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.title),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        return TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: languageService.strings.descriptionOptional,
                            hintText: languageService.strings.descriptionHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.description),
                          ),
                          maxLines: 3,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Selected verses preview
            Consumer<LanguageService>(
              builder: (context, languageService, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${languageService.strings.selectedVersesCount} (${_orderedVerses.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      languageService.strings.dragToReorder,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Reorderable list of verses
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _orderedVerses.length,
              onReorder: _reorderVerses,
              itemBuilder: (context, index) {
                final verse = _orderedVerses[index];
                return PreviewVerseCard(
                  key: ValueKey(verse.reference),
                  verse: verse,
                  slideNumber: index + 1,
                  onRemove: () => _removeVerse(index),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Preview info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Consumer<LanguageService>(
                        builder: (context, languageService, child) {
                          return Text(
                            languageService.strings.presentationPreview,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Consumer<LanguageService>(
                    builder: (context, languageService, child) {
                      return Text(
                        '• ${_orderedVerses.length} ${languageService.strings.slidesWillBeCreated}\n'
                        '• ${languageService.strings.eachVerseWillBeSlide}\n'
                        '• ${languageService.strings.canPresentInTab}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reorderVerses(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final verse = _orderedVerses.removeAt(oldIndex);
      _orderedVerses.insert(newIndex, verse);
    });
  }

  void _removeVerse(int index) {
    setState(() {
      _orderedVerses.removeAt(index);
    });
    
    // Update title if needed
    if (_orderedVerses.isEmpty) {
      _titleController.clear();
    } else if (_orderedVerses.length == 1) {
      _titleController.text = _orderedVerses.first.reference;
    }
  }

  void _saveSelection() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageService.strings.pleaseTitleError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_orderedVerses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageService.strings.atLeastOneVerseError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // In a real app, you would save this to a database or shared preferences
    // For now, we'll just simulate saving
    _simulateSaving();
  }

  void _simulateSaving() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(languageService.strings.savingSelection),
            ],
          ),
        );
      },
    );

    // Create the new collection
    final newCollection = VerseCollection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      verses: List.from(_orderedVerses),
      createdDate: DateTime.now(),
    );
    
    // Save to the service
    final collectionService = VerseCollectionService();
    collectionService.addCollection(newCollection);

    // Simulate saving delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show success dialog with options
      final languageService = Provider.of<LanguageService>(context, listen: false);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(languageService.strings.selectionCreated),
              ],
            ),
            content: Text(
              '"${newCollection.title}" ${languageService.strings.savedSuccessfully}\n\n'
              '${languageService.strings.whatWouldYouLikeToDo}'
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true); // Return to Bible page
                },
                child: Text(languageService.strings.goBack),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                  // Navigate to presenter to show presentation options
                  _showPresentationOptions(newCollection);
                },
                child: Text(languageService.strings.viewInPlaylist),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                  // Start presentation immediately
                  PresenterNavigation.startVerseCollectionPresentation(context, newCollection);
                },
                child: Text(languageService.strings.presentNow),
              ),
            ],
          );
        },
      );
    });
  }

  void _showPresentationOptions(VerseCollection collection) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${languageService.strings.presentTitle} "${collection.title}"'),
          content: Text(
            '${languageService.strings.howWouldYouLikeToPresent}\n\n'
            '${languageService.strings.soloOneVerseAtTime}\n'
            '${languageService.strings.playlistAddToPlaylist}\n'
            '${languageService.strings.presentationStartImmediately}'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(languageService.strings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                PresenterNavigation.startVerseCollectionPresentation(context, collection);
              },
              child: Text(languageService.strings.presentTitle),
            ),
          ],
        );
      },
    );
  }
}

class PreviewVerseCard extends StatelessWidget {
  final BibleVerse verse;
  final int slideNumber;
  final VoidCallback onRemove;

  const PreviewVerseCard({
    super.key,
    required this.verse,
    required this.slideNumber,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slide number and drag handle
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      slideNumber.toString(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.drag_handle,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Verse content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      verse.reference,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verse.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Remove button
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              tooltip: Provider.of<LanguageService>(context, listen: false).strings.removeVerse,
            ),
          ],
        ),
      ),
    );
  }
}