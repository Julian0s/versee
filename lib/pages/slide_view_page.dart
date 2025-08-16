import 'package:flutter/material.dart';
import 'package:versee/models/bible_models.dart';
import 'package:versee/pages/presenter_page.dart';

class SlideViewPage extends StatefulWidget {
  final VerseCollection collection;

  const SlideViewPage({
    super.key,
    required this.collection,
  });

  @override
  State<SlideViewPage> createState() => _SlideViewPageState();
}

class _SlideViewPageState extends State<SlideViewPage> {
  PageController _pageController = PageController();
  int _currentSlide = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.collection.title),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSlideOptions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Slide counter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentSlide + 1} de ${widget.collection.verses.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentSlide > 0 ? _previousSlide : null,
                      icon: Icon(
                        Icons.chevron_left,
                        color: _currentSlide > 0 ? Colors.white : Colors.white30,
                      ),
                    ),
                    IconButton(
                      onPressed: _currentSlide < widget.collection.verses.length - 1 
                          ? _nextSlide 
                          : null,
                      icon: Icon(
                        Icons.chevron_right,
                        color: _currentSlide < widget.collection.verses.length - 1 
                            ? Colors.white 
                            : Colors.white30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Slides
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentSlide = index;
                });
              },
              itemCount: widget.collection.verses.length,
              itemBuilder: (context, index) {
                final verse = widget.collection.verses[index];
                return SlideWidget(verse: verse);
              },
            ),
          ),
          
          // Bottom controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Slide indicators
                ...List.generate(
                  widget.collection.verses.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentSlide 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Bottom action bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Colors.white12, width: 1),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startPresentation,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar Apresentação'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _shareCollection,
                icon: const Icon(Icons.share, color: Colors.white),
                tooltip: 'Compartilhar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _previousSlide() {
    if (_currentSlide > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextSlide() {
    if (_currentSlide < widget.collection.verses.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _startPresentation() {
    PresenterNavigation.startVerseCollectionPresentation(context, widget.collection);
  }

  void _shareCollection() {
    widget.collection.verses
        .map((verse) => '${verse.reference}\n${verse.text}')
        .join('\n\n');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compartilhando: ${widget.collection.title}'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _showSlideOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar Seleção'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit page (would be implemented)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Função de edição será implementada')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Duplicar Seleção'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seleção duplicada')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Compartilhar'),
                onTap: () {
                  Navigator.pop(context);
                  _shareCollection();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Excluir Seleção',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Seleção'),
          content: Text('Tem certeza que deseja excluir "${widget.collection.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Seleção "${widget.collection.title}" excluída'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }
}

class SlideWidget extends StatelessWidget {
  final BibleVerse verse;

  const SlideWidget({
    super.key,
    required this.verse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Reference
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              verse.reference,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Verse text
          Text(
            verse.text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Version
          Text(
            verse.version,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

