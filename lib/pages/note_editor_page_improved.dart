import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/models/note_models.dart';
import 'package:versee/services/notes_service.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/widgets/background_selector_widget.dart';
import 'package:versee/pages/presenter_page.dart';

class NoteEditorPageImproved extends StatefulWidget {
  final NoteItem? existingNote;
  final NotesContentType contentType;
  
  const NoteEditorPageImproved({
    super.key, 
    this.existingNote,
    required this.contentType,
  });

  @override
  State<NoteEditorPageImproved> createState() => _NoteEditorPageImprovedState();
}

class _NoteEditorPageImprovedState extends State<NoteEditorPageImproved> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _slideContentController;
  
  Color _backgroundColor = Colors.black;
  String? _backgroundImageUrl;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existingNote?.description ?? '');
    _slideContentController = TextEditingController(
      text: widget.existingNote?.slides.isNotEmpty == true 
        ? widget.existingNote!.slides.first.content 
        : ''
    );
    
    if (widget.existingNote?.slides.isNotEmpty == true) {
      final firstSlide = widget.existingNote!.slides.first;
      _backgroundColor = firstSlide.backgroundColor ?? Colors.black;
      _backgroundImageUrl = firstSlide.backgroundImageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _slideContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesService = Provider.of<NotesService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingNote == null 
          ? 'Nova Nota' 
          : 'Editar Nota'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
          if (widget.existingNote != null)
            IconButton(
              icon: const Icon(Icons.present_to_all),
              onPressed: () => _presentNote(context),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            BackgroundSelectorWidget(
              currentBackgroundColor: _backgroundColor,
              currentBackgroundImageUrl: _backgroundImageUrl,
              onBackgroundColorChanged: (color) {
                setState(() {
                  _backgroundColor = color;
                });
              },
              onBackgroundImageChanged: (imageUrl) {
                setState(() {
                  _backgroundImageUrl = imageUrl;
                });
              },
              onRemoveBackground: () {
                setState(() {
                  _backgroundImageUrl = null;
                  _backgroundColor = Colors.black;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _slideContentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Conteúdo do Slide',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveNote() async {
    final notesService = Provider.of<NotesService>(context, listen: false);
    
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira um título')),
      );
      return;
    }

    try {
      if (widget.existingNote == null) {
        // Criar nova nota
        final noteId = await notesService.createNote(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: widget.contentType,
          initialSlides: [
            NoteSlide(
              id: '1',
              content: _slideContentController.text.trim(),
              order: 0,
              backgroundColor: _backgroundColor,
              backgroundImageUrl: _backgroundImageUrl,
            )
          ],
        );
      } else {
        // Atualizar nota existente (implementação simplificada)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionalidade de edição em desenvolvimento')),
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar nota: $e')),
        );
      }
    }
  }

  void _presentNote(BuildContext context) {
    if (widget.existingNote != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PresenterPage(),
        ),
      );
    }
  }
}