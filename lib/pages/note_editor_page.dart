import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:versee/models/note_models.dart';
import 'package:versee/services/notes_service.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/services/dual_screen_service.dart';
import 'package:versee/widgets/background_selector_widget.dart';

class NoteEditorPage extends StatefulWidget {
  final NoteItem? existingNote;
  final NotesContentType contentType;

  const NoteEditorPage({
    super.key,
    this.existingNote,
    required this.contentType,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> with TickerProviderStateMixin {
  final DualScreenService _dualScreenService = DualScreenService();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  List<NoteSlide> _slides = [];
  List<TextEditingController> _slideControllers = [];
  int _currentSlideIndex = 0;
  bool _isModified = false;
  bool _isSaving = false;
  
  // Configurações de apresentação
  Color _backgroundColor = Colors.black;
  Color _textColor = Colors.white;
  double _fontSize = 24.0;
  TextAlign _textAlign = TextAlign.center;
  String? _backgroundImageUrl;
  
  // Configurações de sombreamento
  bool _hasTextShadow = false;
  Color _shadowColor = Colors.black;
  double _shadowBlurRadius = 2.0;
  Offset _shadowOffset = const Offset(1.0, 1.0);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingNote();
    _setupAnimations();
  }

  void _initializeControllers() {
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  void _setupAnimations() {
    _fabAnimationController.forward();
  }

  void _loadExistingNote() {
    if (widget.existingNote != null) {
      final note = widget.existingNote!;
      _titleController.text = note.title;
      _descriptionController.text = note.description;
      _slides = List.from(note.slides);
      
      // Ordena slides por ordem
      _slides.sort((a, b) => a.order.compareTo(b.order));
      
      // Carrega configurações do primeiro slide se existir
      if (_slides.isNotEmpty) {
        final firstSlide = _slides.first;
        if (firstSlide.backgroundColor != null) {
          _backgroundColor = firstSlide.backgroundColor!;
        }
        if (firstSlide.textStyle != null) {
          _textColor = firstSlide.textStyle!.color ?? Colors.white;
          _fontSize = firstSlide.textStyle!.fontSize ?? 24.0;
        }
        _hasTextShadow = firstSlide.hasTextShadow;
        if (firstSlide.shadowColor != null) {
          _shadowColor = firstSlide.shadowColor!;
        }
        _shadowBlurRadius = firstSlide.shadowBlurRadius;
        _shadowOffset = firstSlide.shadowOffset;
      }
      
      // Cria controladores para cada slide
      _slideControllers = _slides.map((slide) => 
        TextEditingController(text: slide.content)).toList();
    } else {
      // Nova nota - cria slide inicial
      _addNewSlide();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    _fabAnimationController.dispose();
    for (final controller in _slideControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addNewSlide() {
    final newSlide = NoteSlide(
      id: 'slide_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      backgroundColor: _backgroundColor,
      order: _slides.length,
    );
    
    setState(() {
      _slides.add(newSlide);
      _slideControllers.add(TextEditingController());
      _isModified = true;
    });
    
    // Anima para o novo slide
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _slides.length - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _removeSlide(int index) {
    if (_slides.length <= 1) return; // Manter pelo menos um slide
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Slide'),
        content: Text('Deseja remover o slide ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _slides.removeAt(index);
                _slideControllers[index].dispose();
                _slideControllers.removeAt(index);
                _isModified = true;
                
                // Reordena slides
                for (int i = 0; i < _slides.length; i++) {
                  _slides[i] = _slides[i].copyWith(order: i);
                }
                
                // Ajusta índice atual se necessário
                if (_currentSlideIndex >= _slides.length) {
                  _currentSlideIndex = _slides.length - 1;
                }
              });
            },
            child: Text(
              'Remover',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _duplicateSlide(int index) {
    final originalSlide = _slides[index];
    final duplicatedSlide = originalSlide.copyWith(
      id: 'slide_${DateTime.now().millisecondsSinceEpoch}',
      order: _slides.length,
    );
    
    setState(() {
      _slides.add(duplicatedSlide);
      _slideControllers.add(TextEditingController(text: originalSlide.content));
      _isModified = true;
    });
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira um título')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notesService = Provider.of<NotesService>(context, listen: false);
      
      // Atualiza conteúdo dos slides com os controladores
      for (int i = 0; i < _slides.length; i++) {
        _slides[i] = _slides[i].copyWith(
          content: _slideControllers[i].text,
          backgroundColor: _backgroundColor,
          textStyle: TextStyle(
            color: _textColor,
            fontSize: _fontSize,
            shadows: _hasTextShadow ? [
              Shadow(
                color: _shadowColor,
                blurRadius: _shadowBlurRadius,
                offset: _shadowOffset,
              )
            ] : null,
          ),
          hasTextShadow: _hasTextShadow,
          shadowColor: _shadowColor,
          shadowBlurRadius: _shadowBlurRadius,
          shadowOffset: _shadowOffset,
        );
      }

      if (widget.existingNote != null) {
        // Atualizar nota existente
        final updatedNote = widget.existingNote!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          slides: _slides,
          slideCount: _slides.length,
        );
        await notesService.updateNote(updatedNote);
      } else {
        // Criar nova nota
        await notesService.createNote(
          title: _titleController.text.trim(),
          type: widget.contentType,
          description: _descriptionController.text.trim(),
          initialSlides: _slides,
        );
      }

      setState(() {
        _isModified = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingNote != null ? 'Nota atualizada!' : 'Nota criada!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _previewPresentation() {
    if (_slides.isEmpty) return;

    // Atualiza slides com conteúdo atual
    final updatedSlides = <NoteSlide>[];
    for (int i = 0; i < _slides.length; i++) {
      updatedSlides.add(_slides[i].copyWith(
        content: _slideControllers[i].text,
        backgroundColor: _backgroundColor,
        textStyle: TextStyle(
          color: _textColor,
          fontSize: _fontSize,
          shadows: _hasTextShadow ? [
            Shadow(
              color: _shadowColor,
              blurRadius: _shadowBlurRadius,
              offset: _shadowOffset,
            )
          ] : null,
        ),
        hasTextShadow: _hasTextShadow,
        shadowColor: _shadowColor,
        shadowBlurRadius: _shadowBlurRadius,
        shadowOffset: _shadowOffset,
      ));
    }

    // Cria nota temporária para apresentação
    final tempNote = NoteItem(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.isNotEmpty ? _titleController.text : 'Preview',
      slideCount: updatedSlides.length,
      createdDate: DateTime.now(),
      description: 'Preview',
      type: widget.contentType,
      slides: updatedSlides,
    );

    // Converte para PresentationItems e inicia apresentação
    final presentationItems = tempNote.toPresentationItems();
    if (presentationItems.isNotEmpty) {
      _dualScreenService.startPresentation(presentationItems.first);
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _PresentationPreviewPage(
            slides: updatedSlides,
            dualScreenService: _dualScreenService,
          ),
        ),
      );
    }
  }

  void _showBackgroundOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BackgroundSelectorWidget(
        currentBackgroundColor: _backgroundColor,
        currentBackgroundImageUrl: _backgroundImageUrl,
        onBackgroundColorChanged: (color) {
          setState(() {
            _backgroundColor = color;
            _backgroundImageUrl = null;
            _isModified = true;
          });
        },
        onBackgroundImageChanged: (imageUrl) {
          setState(() {
            _backgroundImageUrl = imageUrl;
            _backgroundColor = Colors.transparent;
            _isModified = true;
          });
        },
        onRemoveBackground: () {
          setState(() {
            _backgroundImageUrl = null;
            _backgroundColor = Colors.black;
            _isModified = true;
          });
        },
      ),
    );
  }

  void _showTextOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TextOptionsSheet(
        currentTextColor: _textColor,
        currentFontSize: _fontSize,
        currentTextAlign: _textAlign,
        hasTextShadow: _hasTextShadow,
        shadowColor: _shadowColor,
        shadowBlurRadius: _shadowBlurRadius,
        shadowOffset: _shadowOffset,
        onTextColorChanged: (color) {
          setState(() {
            _textColor = color;
            _isModified = true;
          });
        },
        onFontSizeChanged: (size) {
          setState(() {
            _fontSize = size;
            _isModified = true;
          });
        },
        onTextAlignChanged: (align) {
          setState(() {
            _textAlign = align;
            _isModified = true;
          });
        },
        onTextShadowChanged: (hasShadow) {
          setState(() {
            _hasTextShadow = hasShadow;
            _isModified = true;
          });
        },
        onShadowColorChanged: (color) {
          setState(() {
            _shadowColor = color;
            _isModified = true;
          });
        },
        onShadowBlurRadiusChanged: (radius) {
          setState(() {
            _shadowBlurRadius = radius;
            _isModified = true;
          });
        },
        onShadowOffsetChanged: (offset) {
          setState(() {
            _shadowOffset = offset;
            _isModified = true;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isModified,
      onPopInvoked: (didPop) {
        if (didPop) return;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Descartar alterações?'),
            content: const Text('Você tem alterações não salvas. Deseja descartá-las?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  'Descartar',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existingNote != null 
                ? 'Editar ${widget.contentType == NotesContentType.lyrics ? 'Letra' : 'Nota'}'
                : 'Nova ${widget.contentType == NotesContentType.lyrics ? 'Letra' : 'Nota'}',
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          actions: [
            if (_slides.isNotEmpty)
              IconButton(
                onPressed: _previewPresentation,
                icon: const Icon(Icons.play_arrow),
                tooltip: 'Prévia',
              ),
            IconButton(
              onPressed: _isSaving ? null : _saveNote,
              icon: _isSaving 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              tooltip: 'Salvar',
            ),
          ],
        ),
        body: Column(
          children: [
            // Header com título e descrição
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                    onChanged: (_) => setState(() => _isModified = true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (_) => setState(() => _isModified = true),
                  ),
                ],
              ),
            ),
            
            // Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _showBackgroundOptions,
                    icon: const Icon(Icons.palette),
                    tooltip: 'Fundo',
                  ),
                  IconButton(
                    onPressed: _showTextOptions,
                    icon: const Icon(Icons.text_fields),
                    tooltip: 'Texto',
                  ),
                  const Spacer(),
                  Text(
                    'Slide ${_currentSlideIndex + 1} de ${_slides.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _slides.length > 1 ? () => _removeSlide(_currentSlideIndex) : null,
                    icon: const Icon(Icons.delete),
                    tooltip: 'Remover slide',
                  ),
                  IconButton(
                    onPressed: () => _duplicateSlide(_currentSlideIndex),
                    icon: const Icon(Icons.copy),
                    tooltip: 'Duplicar slide',
                  ),
                ],
              ),
            ),
            
            // Editor de slides
            Expanded(
              child: _slides.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (index) {
                        setState(() => _currentSlideIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            image: _backgroundImageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                      _backgroundImageUrl!,
                                      headers: const {
                                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                                      },
                                    ),
                                    fit: BoxFit.cover,
                                    onError: (error, stackTrace) {
                                      debugPrint('Erro ao carregar imagem de fundo: $_backgroundImageUrl - $error');
                                    },
                                  )
                                : null,
                          ),
                          child: TextField(
                            controller: _slideControllers[index],
                            decoration: const InputDecoration(
                              hintText: 'Digite o conteúdo do slide...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(20),
                            ),
                            style: TextStyle(
                              color: _textColor,
                              fontSize: _fontSize,
                              shadows: _hasTextShadow ? [
                                Shadow(
                                  color: _shadowColor,
                                  blurRadius: _shadowBlurRadius,
                                  offset: _shadowOffset,
                                )
                              ] : null,
                            ),
                            textAlign: _textAlign,
                            maxLines: null,
                            expands: true,
                            onChanged: (_) => setState(() => _isModified = true),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _fabAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _fabAnimation.value,
              child: FloatingActionButton(
                onPressed: _addNewSlide,
                tooltip: 'Adicionar slide',
                child: const Icon(Icons.add),
              ),
            );
          },
        ),
      ),
    );
  }
}


// Sheet para opções de texto
class _TextOptionsSheet extends StatelessWidget {
  final Color currentTextColor;
  final double currentFontSize;
  final TextAlign currentTextAlign;
  final bool hasTextShadow;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final ValueChanged<Color> onTextColorChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<TextAlign> onTextAlignChanged;
  final ValueChanged<bool> onTextShadowChanged;
  final ValueChanged<Color> onShadowColorChanged;
  final ValueChanged<double> onShadowBlurRadiusChanged;
  final ValueChanged<Offset> onShadowOffsetChanged;

  const _TextOptionsSheet({
    required this.currentTextColor,
    required this.currentFontSize,
    required this.currentTextAlign,
    required this.hasTextShadow,
    required this.shadowColor,
    required this.shadowBlurRadius,
    required this.shadowOffset,
    required this.onTextColorChanged,
    required this.onFontSizeChanged,
    required this.onTextAlignChanged,
    required this.onTextShadowChanged,
    required this.onShadowColorChanged,
    required this.onShadowBlurRadiusChanged,
    required this.onShadowOffsetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColors = [
      Colors.white,
      Colors.black,
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opções de Texto',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Cor do Texto',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: textColors.map((color) {
              final isSelected = color == currentTextColor;
              return GestureDetector(
                onTap: () {
                  onTextColorChanged(color);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: color == Colors.white || color == Colors.yellow
                              ? Colors.black
                              : Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Tamanho da Fonte: ${currentFontSize.round()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: currentFontSize,
            min: 12,
            max: 48,
            divisions: 36,
            onChanged: onFontSizeChanged,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Alinhamento',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              _AlignmentButton(
                icon: Icons.format_align_left,
                isSelected: currentTextAlign == TextAlign.left,
                onTap: () => onTextAlignChanged(TextAlign.left),
              ),
              const SizedBox(width: 8),
              _AlignmentButton(
                icon: Icons.format_align_center,
                isSelected: currentTextAlign == TextAlign.center,
                onTap: () => onTextAlignChanged(TextAlign.center),
              ),
              const SizedBox(width: 8),
              _AlignmentButton(
                icon: Icons.format_align_right,
                isSelected: currentTextAlign == TextAlign.right,
                onTap: () => onTextAlignChanged(TextAlign.right),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Seção de Sombreamento
          Row(
            children: [
              Text(
                'Sombreamento',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Switch(
                value: hasTextShadow,
                onChanged: onTextShadowChanged,
              ),
            ],
          ),
          
          if (hasTextShadow) ...[
            const SizedBox(height: 16),
            
            Text(
              'Cor da Sombra',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Colors.black,
                Colors.white,
                Colors.grey,
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.purple,
              ].map((color) {
                final isSelected = color == shadowColor;
                return GestureDetector(
                  onTap: () => onShadowColorChanged(color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: color == Colors.white || color == Colors.yellow
                                ? Colors.black
                                : Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Intensidade da Sombra: ${shadowBlurRadius.round()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: shadowBlurRadius,
              min: 0,
              max: 10,
              divisions: 20,
              onChanged: onShadowBlurRadiusChanged,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Deslocamento da Sombra',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Horizontal: ${shadowOffset.dx.round()}'),
                      Slider(
                        value: shadowOffset.dx,
                        min: -10,
                        max: 10,
                        divisions: 20,
                        onChanged: (value) => onShadowOffsetChanged(
                          Offset(value, shadowOffset.dy),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vertical: ${shadowOffset.dy.round()}'),
                      Slider(
                        value: shadowOffset.dy,
                        min: -10,
                        max: 10,
                        divisions: 20,
                        onChanged: (value) => onShadowOffsetChanged(
                          Offset(shadowOffset.dx, value),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _AlignmentButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlignmentButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

// Página de prévia da apresentação
class _PresentationPreviewPage extends StatefulWidget {
  final List<NoteSlide> slides;
  final DualScreenService dualScreenService;

  const _PresentationPreviewPage({
    required this.slides,
    required this.dualScreenService,
  });

  @override
  State<_PresentationPreviewPage> createState() => _PresentationPreviewPageState();
}

class _PresentationPreviewPageState extends State<_PresentationPreviewPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    widget.dualScreenService.stopPresentation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Prévia - Slide ${_currentIndex + 1} de ${widget.slides.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.slides.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final slide = widget.slides[index];
          return Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: slide.backgroundColor ?? Colors.black,
              borderRadius: BorderRadius.circular(8),
              image: slide.backgroundImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(
                        slide.backgroundImageUrl!,
                        headers: const {
                          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                        },
                      ),
                      fit: BoxFit.cover,
                      onError: (error, stackTrace) {
                        debugPrint('Erro ao carregar imagem de fundo do slide: ${slide.backgroundImageUrl} - $error');
                      },
                    )
                  : null,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  slide.content,
                  style: slide.textStyle ?? TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    shadows: slide.hasTextShadow ? [
                      Shadow(
                        color: slide.shadowColor ?? Colors.black,
                        blurRadius: slide.shadowBlurRadius,
                        offset: slide.shadowOffset,
                      )
                    ] : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: _currentIndex > 0 
                  ? () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                  : null,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            Expanded(
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / widget.slides.length,
                backgroundColor: Colors.grey.shade800,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            IconButton(
              onPressed: _currentIndex < widget.slides.length - 1
                  ? () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                  : null,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}