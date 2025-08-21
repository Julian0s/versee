import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:versee/models/note_models.dart';
import 'package:versee/services/firebase_manager.dart';
import 'package:versee/firestore/firestore_data_schema.dart';

/// Instância global do NotesService para bridge híbrida com Riverpod
NotesService? _globalNotesService;

/// Serviço para gerenciar notas e lyrics no Firestore
class NotesService extends ChangeNotifier {
  final FirebaseManager _firebaseManager = FirebaseManager();
  final Map<String, List<NoteItem>> _notesCache = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Streams para observar mudanças em tempo real
  final StreamController<List<NoteItem>> _lyricsStreamController = StreamController<List<NoteItem>>.broadcast();
  final StreamController<List<NoteItem>> _notesStreamController = StreamController<List<NoteItem>>.broadcast();

  Stream<List<NoteItem>> get lyricsStream => _lyricsStreamController.stream;
  Stream<List<NoteItem>> get notesStream => _notesStreamController.stream;

  List<NoteItem> get lyrics => _notesCache['lyrics'] ?? [];
  List<NoteItem> get notes => _notesCache['notes'] ?? [];

  NotesService() {
    // Registrar esta instância globalmente para bridge híbrida
    _globalNotesService = this;
  }

  @override
  void dispose() {
    _subscriptions.values.forEach((subscription) => subscription.cancel());
    _subscriptions.clear();
    _lyricsStreamController.close();
    _notesStreamController.close();
    _notesCache.clear();
    _isInitialized = false;
    _isInitializing = false;
    super.dispose();
  }

  /// Inicializa o serviço e escuta mudanças em tempo real
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) {
      debugPrint('🔄 NotesService já inicializado ou inicializando - pulando');
      return;
    }
    _isInitializing = true;
    
    try {
      debugPrint('🚀 Iniciando NotesService...');
      
      // Verificar se o Firebase está configurado
      await _firebaseManager.initialize();
      
      final userId = _firebaseManager.currentUserId;
      debugPrint('👤 NotesService.initialize - userId: $userId');
      
      if (userId == null) {
        debugPrint('❌ NotesService.initialize - usuário não autenticado');
        _isInitializing = false;
        return;
      }

      debugPrint('🎧 NotesService.initialize - configurando listeners');
      await _setupRealtimeListeners(userId);
      _isInitialized = true;
      debugPrint('✅ NotesService.initialize - inicialização concluída');
    } catch (e) {
      debugPrint('❌ Erro na inicialização do NotesService: $e');
      debugPrint('📍 Stack trace: ${StackTrace.current}'); 
    } finally {
      _isInitializing = false;
    }
  }


  /// Configura listeners em tempo real para notas e lyrics
  Future<void> _setupRealtimeListeners(String userId) async {
    // Cancelar listeners anteriores
    _subscriptions.values.forEach((subscription) => subscription.cancel());
    _subscriptions.clear();

    debugPrint('🎧 Configurando listeners para userId: $userId');

    // Listener para lyrics (nova coleção separada)
    debugPrint('🎵 Configurando listener para lyrics...');
    try {
      final lyricsSubscription = _firebaseManager.firestore
          .collection(FirestoreDataSchema.lyricsCollection)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        debugPrint('🎵 LYRICS LISTENER ATIVADO - documentos recebidos: ${snapshot.docs.length}');
        
        try {
          final lyricsList = snapshot.docs.map((doc) => _noteFromFirestore(doc, NotesContentType.lyrics)).toList();
          // Ordena no cliente por createdAt (mais recente primeiro)
          lyricsList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
          debugPrint('🎵 Lyrics processadas com sucesso: ${lyricsList.length}');
          
          _notesCache['lyrics'] = lyricsList;
          _lyricsStreamController.add(lyricsList);
          notifyListeners();
          debugPrint('🎵 Lyrics atualizadas no cache e stream');
        } catch (parseError) {
          debugPrint('❌ Erro ao processar lyrics: $parseError');
          debugPrint('📍 Parse error stack: ${StackTrace.current}');
          // Enviar lista vazia em caso de erro de parsing
          _notesCache['lyrics'] = [];
          _lyricsStreamController.add([]);
          notifyListeners();
        }
        
      }, onError: (error) {
        debugPrint('❌ ERRO NO LISTENER DE LYRICS: $error');
        debugPrint('📍 Stack trace: ${StackTrace.current}');
        // Enviar lista vazia em caso de erro
        _notesCache['lyrics'] = [];
        _lyricsStreamController.add([]);
        notifyListeners();
      });

      _subscriptions['lyrics'] = lyricsSubscription;
      debugPrint('✅ Listener de lyrics configurado');
    } catch (e) {
      debugPrint('❌ Erro ao configurar listener de lyrics: $e');
      debugPrint('📍 Setup error stack: ${StackTrace.current}');
    }

    // Listener para notes (coleção original, usando query mais simples)
    debugPrint('📝 Configurando listener para notes...');
    try {
      final notesSubscription = _firebaseManager.firestore
          .collection(FirestoreDataSchema.notesCollection)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        debugPrint('📝 NOTES LISTENER ATIVADO - documentos recebidos: ${snapshot.docs.length}');
        
        try {
          // Filtra documentos que não têm campo 'type' no lado do cliente
          final notesDocsOnly = snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return !data.containsKey('type') || data['type'] == null;
          }).toList();
          
          debugPrint('📝 Documentos filtrados (sem type): ${notesDocsOnly.length}');
          
          final notesList = notesDocsOnly.map((doc) => _noteFromFirestore(doc, NotesContentType.notes)).toList();
          // Ordena no cliente por createdAt (mais recente primeiro)
          notesList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
          debugPrint('📝 Notes processadas com sucesso: ${notesList.length}');
          
          _notesCache['notes'] = notesList;
          _notesStreamController.add(notesList);
          notifyListeners();
          debugPrint('📝 Notes atualizadas no cache e stream');
        } catch (parseError) {
          debugPrint('❌ Erro ao processar notes: $parseError');
          debugPrint('📍 Parse error stack: ${StackTrace.current}');
          // Enviar lista vazia em caso de erro de parsing
          _notesCache['notes'] = [];
          _notesStreamController.add([]);
          notifyListeners();
        }
        
      }, onError: (error) {
        debugPrint('❌ ERRO NO LISTENER DE NOTES: $error');
        debugPrint('📍 Stack trace: ${StackTrace.current}');
        // Enviar lista vazia em caso de erro
        _notesCache['notes'] = [];
        _notesStreamController.add([]);
        notifyListeners();
      });

      _subscriptions['notes'] = notesSubscription;
      debugPrint('✅ Listener de notes configurado');
    } catch (e) {
      debugPrint('❌ Erro ao configurar listener de notes: $e');
      debugPrint('📍 Setup error stack: ${StackTrace.current}');
    }

    debugPrint('🎧 Todos os listeners configurados');
  }

  /// Cria uma nova nota ou lyrics
  Future<String> createNote({
    required String title,
    required NotesContentType type,
    String? description,
    List<NoteSlide>? initialSlides,
  }) async {
    final userId = _firebaseManager.currentUserId;
    debugPrint('📝 CreateNote - userId: $userId, type: $type, title: $title');
    
    if (userId == null) {
      debugPrint('❌ CreateNote - usuário não autenticado');
      throw Exception('Usuário não autenticado');
    }

    try {
      final noteId = _generateNoteId();
      final slides = initialSlides ?? [
        NoteSlide(
          id: 'slide_1',
          content: '',
          order: 0,
        ),
      ];

      // Usa coleções separadas
      final collection = type == NotesContentType.lyrics 
          ? FirestoreDataSchema.lyricsCollection
          : FirestoreDataSchema.notesCollection;
      
      debugPrint('📝 CreateNote - coleção: $collection, noteId: $noteId');
      
      final noteData = type == NotesContentType.lyrics
          ? FirestoreDataSchema.lyricsDocument(
              userId: userId,
              title: title,
              description: description,
              slides: slides.map(_slideToMap).toList(),
            )
          : FirestoreDataSchema.noteDocument(
              userId: userId,
              title: title,
              description: description,
              slides: slides.map(_slideToMap).toList(),
            );

      debugPrint('📝 CreateNote - dados preparados: ${noteData.keys}');
      debugPrint('📝 CreateNote - userId nos dados: ${noteData['userId']}');
      
      await _firebaseManager.firestore
          .collection(collection)
          .doc(noteId)
          .set(noteData);

      debugPrint('✅ CreateNote - nota criada com sucesso: $noteId');
      return noteId;
    } catch (e) {
      debugPrint('❌ CreateNote - erro: $e');
      debugPrint('📍 Stack trace: ${StackTrace.current}');
      throw Exception('Erro ao criar nota: $e');
    }
  }

  /// Atualiza uma nota existente
  Future<void> updateNote(NoteItem note) async {
    final userId = _firebaseManager.currentUserId;
    debugPrint('📝 UpdateNote - userId: $userId, noteId: ${note.id}, title: ${note.title}');
    
    if (userId == null) throw Exception('Usuário não autenticado');

    try {
      // Usa coleções separadas
      final collection = note.type == NotesContentType.lyrics 
          ? FirestoreDataSchema.lyricsCollection
          : FirestoreDataSchema.notesCollection;
      
      debugPrint('📝 UpdateNote - coleção: $collection');
      
      final noteData = note.type == NotesContentType.lyrics
          ? FirestoreDataSchema.lyricsDocument(
              userId: userId,
              title: note.title,
              description: note.description,
              slides: note.slides.map(_slideToMap).toList(),
              updatedAt: DateTime.now(),
            )
          : FirestoreDataSchema.noteDocument(
              userId: userId,
              title: note.title,
              description: note.description,
              slides: note.slides.map(_slideToMap).toList(),
              updatedAt: DateTime.now(),
            );

      await _firebaseManager.firestore
          .collection(collection)
          .doc(note.id)
          .update(noteData);
          
      debugPrint('✅ UpdateNote - nota atualizada com sucesso: ${note.id}');
    } catch (e) {
      debugPrint('❌ UpdateNote - erro: $e');
      debugPrint('📍 Stack trace: ${StackTrace.current}');
      throw Exception('Erro ao atualizar nota: $e');
    }
  }

  /// Deleta uma nota
  Future<void> deleteNote(String noteId, NotesContentType type) async {
    final userId = _firebaseManager.currentUserId;
    debugPrint('🗑️ DeleteNote - userId: $userId, noteId: $noteId, type: $type');
    
    if (userId == null) throw Exception('Usuário não autenticado');

    try {
      final collection = type == NotesContentType.lyrics 
          ? FirestoreDataSchema.lyricsCollection
          : FirestoreDataSchema.notesCollection;
      
      debugPrint('🗑️ DeleteNote - coleção: $collection');
      
      await _firebaseManager.firestore
          .collection(collection)
          .doc(noteId)
          .delete();
          
      debugPrint('✅ DeleteNote - nota deletada com sucesso: $noteId');
    } catch (e) {
      debugPrint('❌ DeleteNote - erro: $e');
      debugPrint('📍 Stack trace: ${StackTrace.current}');
      throw Exception('Erro ao deletar nota: $e');
    }
  }

  /// Busca uma nota específica
  Future<NoteItem?> getNoteById(String noteId, NotesContentType type) async {
    debugPrint('🔍 GetNoteById - noteId: $noteId, type: $type');
    
    try {
      final collection = type == NotesContentType.lyrics 
          ? FirestoreDataSchema.lyricsCollection
          : FirestoreDataSchema.notesCollection;
      
      debugPrint('🔍 GetNoteById - coleção: $collection');
      
      final doc = await _firebaseManager.firestore
          .collection(collection)
          .doc(noteId)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ GetNoteById - documento não existe: $noteId');
        return null;
      }
      
      final noteItem = _noteFromFirestore(doc, type);
      debugPrint('✅ GetNoteById - nota encontrada: ${noteItem.title}');
      return noteItem;
    } catch (e) {
      debugPrint('❌ GetNoteById - erro: $e');
      debugPrint('📍 Stack trace: ${StackTrace.current}');
      throw Exception('Erro ao buscar nota: $e');
    }
  }

  /// Busca notas por tipo
  Future<List<NoteItem>> getNotesByType(NotesContentType type) async {
    final userId = _firebaseManager.currentUserId;
    debugPrint('🔍 GetNotesByType - userId: $userId, type: $type');
    
    if (userId == null) {
      debugPrint('⚠️ GetNotesByType - usuário não autenticado');
      return [];
    }

    try {
      final collection = type == NotesContentType.lyrics 
          ? FirestoreDataSchema.lyricsCollection
          : FirestoreDataSchema.notesCollection;
      
      debugPrint('🔍 GetNotesByType - coleção: $collection');
      
      final querySnapshot = await _firebaseManager.firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('🔍 GetNotesByType - documentos encontrados: ${querySnapshot.docs.length}');
      
      List<DocumentSnapshot> filteredDocs = querySnapshot.docs;
      
      // Para a coleção 'notes', filtra apenas documentos sem campo 'type' no cliente
      if (type == NotesContentType.notes) {
        filteredDocs = querySnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return !data.containsKey('type') || data['type'] == null;
        }).toList();
        debugPrint('🔍 GetNotesByType - documentos filtrados (sem type): ${filteredDocs.length}');
      }
      
      final notes = filteredDocs.map((doc) => _noteFromFirestore(doc, type)).toList();
      // Ordena no cliente por createdAt (mais recente primeiro)
      notes.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      debugPrint('✅ GetNotesByType - notas processadas: ${notes.length}');
      
      return notes;
    } catch (e) {
      debugPrint('❌ GetNotesByType - erro: $e');
      debugPrint('📍 Stack trace: ${StackTrace.current}');
      throw Exception('Erro ao buscar notas: $e');
    }
  }

  /// Duplica uma nota
  Future<String> duplicateNote(String noteId, NotesContentType type) async {
    debugPrint('📋 DuplicateNote - noteId: $noteId, type: $type');
    
    final originalNote = await getNoteById(noteId, type);
    if (originalNote == null) {
      debugPrint('❌ DuplicateNote - nota não encontrada: $noteId');
      throw Exception('Nota não encontrada');
    }

    final newNoteId = await createNote(
      title: '${originalNote.title} (Cópia)',
      type: originalNote.type,
      description: originalNote.description,
      initialSlides: originalNote.slides,
    );
    
    debugPrint('✅ DuplicateNote - nota duplicada: $newNoteId');
    return newNoteId;
  }

  /// Adiciona um slide a uma nota
  Future<void> addSlideToNote(String noteId, NotesContentType type, NoteSlide slide) async {
    debugPrint('➕ AddSlideToNote - noteId: $noteId, slideId: ${slide.id}');
    
    final note = await getNoteById(noteId, type);
    if (note == null) throw Exception('Nota não encontrada');

    final updatedSlides = List<NoteSlide>.from(note.slides)..add(slide);
    final updatedNote = note.copyWith(
      slides: updatedSlides,
      slideCount: updatedSlides.length,
    );

    await updateNote(updatedNote);
    debugPrint('✅ AddSlideToNote - slide adicionado com sucesso');
  }

  /// Remove um slide de uma nota
  Future<void> removeSlideFromNote(String noteId, NotesContentType type, String slideId) async {
    debugPrint('➖ RemoveSlideFromNote - noteId: $noteId, slideId: $slideId');
    
    final note = await getNoteById(noteId, type);
    if (note == null) throw Exception('Nota não encontrada');

    final updatedSlides = note.slides.where((slide) => slide.id != slideId).toList();
    
    // Reordena os slides
    for (int i = 0; i < updatedSlides.length; i++) {
      updatedSlides[i] = updatedSlides[i].copyWith(order: i);
    }

    final updatedNote = note.copyWith(
      slides: updatedSlides,
      slideCount: updatedSlides.length,
    );

    await updateNote(updatedNote);
    debugPrint('✅ RemoveSlideFromNote - slide removido com sucesso');
  }

  /// Atualiza um slide específico
  Future<void> updateSlideInNote(String noteId, NotesContentType type, NoteSlide updatedSlide) async {
    debugPrint('✏️ UpdateSlideInNote - noteId: $noteId, slideId: ${updatedSlide.id}');
    
    final note = await getNoteById(noteId, type);
    if (note == null) throw Exception('Nota não encontrada');

    final slideIndex = note.slides.indexWhere((slide) => slide.id == updatedSlide.id);
    if (slideIndex == -1) throw Exception('Slide não encontrado');

    final updatedSlides = List<NoteSlide>.from(note.slides);
    updatedSlides[slideIndex] = updatedSlide;

    final updatedNote = note.copyWith(slides: updatedSlides);
    await updateNote(updatedNote);
    debugPrint('✅ UpdateSlideInNote - slide atualizado com sucesso');
  }

  /// Reordena slides de uma nota
  Future<void> reorderSlides(String noteId, NotesContentType type, List<NoteSlide> reorderedSlides) async {
    debugPrint('🔄 ReorderSlides - noteId: $noteId, slides: ${reorderedSlides.length}');
    
    final note = await getNoteById(noteId, type);
    if (note == null) throw Exception('Nota não encontrada');

    // Atualiza a ordem dos slides
    for (int i = 0; i < reorderedSlides.length; i++) {
      reorderedSlides[i] = reorderedSlides[i].copyWith(order: i);
    }

    final updatedNote = note.copyWith(slides: reorderedSlides);
    await updateNote(updatedNote);
    debugPrint('✅ ReorderSlides - slides reordenados com sucesso');
  }

  /// Converte documento do Firestore para NoteItem
  NoteItem _noteFromFirestore(DocumentSnapshot doc, NotesContentType type) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        debugPrint('⚠️ Documento ${doc.id} não contém dados');
        return _createFallbackNoteItem(doc.id, type);
      }
      
      debugPrint('🔄 Convertendo documento ${doc.id} para NoteItem');
      
      final slidesData = data['slides'] as List<dynamic>? ?? [];
      debugPrint('🔄 Slides encontrados: ${slidesData.length}');
      
      final slides = <NoteSlide>[];
      for (int i = 0; i < slidesData.length; i++) {
        try {
          final slideData = slidesData[i];
          if (slideData is Map<String, dynamic>) {
            slides.add(_createSlideFromData(slideData, i));
          } else {
            debugPrint('⚠️ Slide $i não é um Map válido - ignorando');
          }
        } catch (slideError) {
          debugPrint('⚠️ Erro ao processar slide $i: $slideError - ignorando');
          // Continua processamento sem incluir o slide com erro
        }
      }

      // Se não há slides válidos, cria um slide padrão
      if (slides.isEmpty) {
        slides.add(NoteSlide(
          id: 'slide_0',
          content: '',
          order: 0,
        ));
      }

      // Ordena slides por ordem
      slides.sort((a, b) => a.order.compareTo(b.order));

      final noteItem = NoteItem(
        id: doc.id,
        title: data['title'] ?? 'Sem título',
        slideCount: slides.length,
        createdDate: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
        description: data['description'] ?? '',
        type: type,
        slides: slides,
      );
      
      debugPrint('✅ NoteItem criado: ${noteItem.title} (${noteItem.id})');
      return noteItem;
    } catch (e) {
      debugPrint('❌ Erro ao converter documento ${doc.id}: $e');
      debugPrint('📍 Stack trace: ${StackTrace.current}');
      // Retorna um item de fallback em vez de falhar
      return _createFallbackNoteItem(doc.id, type);
    }
  }

  /// Cria um NoteItem de fallback quando há erro na conversão
  NoteItem _createFallbackNoteItem(String id, NotesContentType type) {
    debugPrint('🔧 Criando NoteItem de fallback para ID: $id');
    return NoteItem(
      id: id,
      title: 'Erro na conversão',
      slideCount: 1,
      createdDate: DateTime.now(),
      description: 'Este item teve erro na conversão de dados',
      type: type,
      slides: [
        NoteSlide(
          id: 'slide_0',
          content: 'Erro ao carregar conteúdo',
          order: 0,
        ),
      ],
    );
  }

  /// Cria um NoteSlide a partir de dados do Firestore
  NoteSlide _createSlideFromData(Map<String, dynamic> slideMap, int index) {
    return NoteSlide(
      id: slideMap['id'] ?? 'slide_$index',
      content: slideMap['content'] ?? '',
      backgroundImageUrl: slideMap['backgroundImageUrl'],
      isBackgroundGif: slideMap['isBackgroundGif'] ?? false,
      backgroundColor: slideMap['backgroundColor'] != null 
          ? _parseColor(slideMap['backgroundColor'])
          : null,
      textStyle: slideMap['textStyle'] != null 
          ? _parseTextStyle(slideMap['textStyle'])
          : null,
      displayDuration: slideMap['displayDuration'] != null
          ? Duration(milliseconds: slideMap['displayDuration'])
          : null,
      order: slideMap['order'] ?? index,
      hasTextShadow: slideMap['hasTextShadow'] ?? false,
      shadowColor: slideMap['shadowColor'] != null 
          ? _parseColor(slideMap['shadowColor'])
          : null,
      shadowBlurRadius: slideMap['shadowBlurRadius']?.toDouble() ?? 2.0,
      shadowOffset: slideMap['shadowOffset'] != null
          ? _parseOffset(slideMap['shadowOffset'])
          : const Offset(1.0, 1.0),
    );
  }

  /// Parse seguro de Timestamp
  DateTime? _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return null;
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      return null;
    } catch (e) {
      debugPrint('⚠️ Erro ao parsear timestamp: $e');
      return null;
    }
  }

  /// Parse seguro de Offset
  Offset _parseOffset(dynamic offsetData) {
    try {
      if (offsetData is Map<String, dynamic>) {
        return Offset(
          offsetData['dx']?.toDouble() ?? 1.0,
          offsetData['dy']?.toDouble() ?? 1.0,
        );
      }
      return const Offset(1.0, 1.0);
    } catch (e) {
      debugPrint('⚠️ Erro ao parsear offset: $e');
      return const Offset(1.0, 1.0);
    }
  }

  /// Converte string de cor para Color (trata erros de formato)
  Color _parseColor(String colorString) {
    try {
      if (colorString.isEmpty) {
        debugPrint('⚠️ String de cor vazia - usando cor padrão');
        return Colors.black;
      }
      
      // Remove '#' se presente e garante que seja um hex válido
      String hexColor = colorString.replaceFirst('#', '');
      
      // Remove espaços em branco
      hexColor = hexColor.trim();
      
      // Valida se contém apenas caracteres hexadecimais
      final validHexPattern = RegExp(r'^[0-9A-Fa-f]+$');
      if (!validHexPattern.hasMatch(hexColor)) {
        debugPrint('⚠️ Cor contém caracteres inválidos: $colorString - usando cor padrão');
        return Colors.black;
      }
      
      // Se não tem prefixo de transparência, adiciona FF
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      
      // Garante que tem exatamente 8 caracteres
      if (hexColor.length != 8) {
        debugPrint('⚠️ Cor com comprimento inválido: $colorString (${hexColor.length} chars) - usando cor padrão');
        return Colors.black;
      }
      
      final colorValue = int.parse(hexColor, radix: 16);
      return Color(colorValue);
    } catch (e) {
      debugPrint('❌ Erro ao parsear cor "$colorString": $e - usando cor padrão');
      return Colors.black; // Cor padrão em caso de erro
    }
  }

  /// Converte NoteSlide para Map
  Map<String, dynamic> _slideToMap(NoteSlide slide) {
    return {
      'id': slide.id,
      'content': slide.content,
      'backgroundImageUrl': slide.backgroundImageUrl,
      'isBackgroundGif': slide.isBackgroundGif,
      'backgroundColor': slide.backgroundColor?.value.toRadixString(16).padLeft(8, '0'),
      'textStyle': slide.textStyle != null ? _textStyleToMap(slide.textStyle!) : null,
      'displayDuration': slide.displayDuration?.inMilliseconds,
      'order': slide.order,
      'hasTextShadow': slide.hasTextShadow,
      'shadowColor': slide.shadowColor?.value.toRadixString(16).padLeft(8, '0'),
      'shadowBlurRadius': slide.shadowBlurRadius,
      'shadowOffset': {
        'dx': slide.shadowOffset.dx,
        'dy': slide.shadowOffset.dy,
      },
    };
  }

  /// Converte TextStyle para Map
  Map<String, dynamic> _textStyleToMap(TextStyle textStyle) {
    return {
      'fontSize': textStyle.fontSize,
      'fontWeight': textStyle.fontWeight?.index,
      'color': textStyle.color?.value.toRadixString(16).padLeft(8, '0'),
      'fontFamily': textStyle.fontFamily,
      'shadows': textStyle.shadows?.map((shadow) => {
        'color': shadow.color.value.toRadixString(16).padLeft(8, '0'),
        'blurRadius': shadow.blurRadius,
        'offset': {
          'dx': shadow.offset.dx,
          'dy': shadow.offset.dy,
        },
      }).toList(),
    };
  }

  /// Converte Map para TextStyle (parsing seguro)
  TextStyle _parseTextStyle(Map<String, dynamic> styleMap) {
    try {
      final shadowsData = styleMap['shadows'] as List<dynamic>? ?? [];
      final shadows = <Shadow>[];
      
      for (var shadowData in shadowsData) {
        try {
          if (shadowData is Map<String, dynamic>) {
            shadows.add(Shadow(
              color: shadowData['color'] != null 
                  ? _parseColor(shadowData['color'])
                  : Colors.black,
              blurRadius: shadowData['blurRadius']?.toDouble() ?? 0.0,
              offset: shadowData['offset'] != null
                  ? _parseOffset(shadowData['offset'])
                  : const Offset(0.0, 0.0),
            ));
          }
        } catch (shadowError) {
          debugPrint('⚠️ Erro ao parsear shadow: $shadowError - ignorando');
        }
      }

      FontWeight? fontWeight;
      if (styleMap['fontWeight'] != null) {
        try {
          final weightIndex = styleMap['fontWeight'] as int;
          if (weightIndex >= 0 && weightIndex < FontWeight.values.length) {
            fontWeight = FontWeight.values[weightIndex];
          }
        } catch (e) {
          debugPrint('⚠️ Erro ao parsear fontWeight: $e');
        }
      }

      return TextStyle(
        fontSize: styleMap['fontSize']?.toDouble(),
        fontWeight: fontWeight,
        color: styleMap['color'] != null 
            ? _parseColor(styleMap['color'])
            : null,
        fontFamily: styleMap['fontFamily'],
        shadows: shadows.isNotEmpty ? shadows : null,
      );
    } catch (e) {
      debugPrint('⚠️ Erro ao parsear TextStyle: $e - retornando estilo padrão');
      return const TextStyle();
    }
  }

  /// Gera ID único para nota
  String _generateNoteId() {
    return 'note_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Limpa cache local
  void clearCache() {
    debugPrint('🧹 Limpando cache local');
    _notesCache.clear();
    notifyListeners();
  }

  /// Força atualização dos dados
  Future<void> refresh() async {
    debugPrint('🔄 Forçando refresh do NotesService');
    await initialize();
  }
  
  /// Utilitário para limpar dados antigos com campo 'type' (usar apenas para limpeza)
  Future<void> cleanupOldData() async {
    final userId = _firebaseManager.currentUserId;
    if (userId == null) return;
    
    try {
      debugPrint('🧹 Iniciando limpeza de dados antigos...');
      
      // Busca documentos com field 'type' na coleção notes
      final oldDocsQuery = await _firebaseManager.firestore
          .collection(FirestoreDataSchema.notesCollection)
          .where('userId', isEqualTo: userId)
          .where('type', whereIn: ['lyrics', 'notes'])
          .get();
      
      debugPrint('🧹 Encontrados ${oldDocsQuery.docs.length} documentos antigos');
      
      final batch = _firebaseManager.firestore.batch();
      
      for (final doc in oldDocsQuery.docs) {
        final data = doc.data();
        final type = data['type'] as String;
        
        if (type == 'lyrics') {
          // Move para coleção lyrics
          final lyricsRef = _firebaseManager.firestore
              .collection(FirestoreDataSchema.lyricsCollection)
              .doc(doc.id);
          
          final cleanData = Map<String, dynamic>.from(data)..remove('type');
          batch.set(lyricsRef, cleanData);
          batch.delete(doc.reference);
        } else if (type == 'notes') {
          // Remove o campo type apenas
          batch.update(doc.reference, {'type': FieldValue.delete()});
        }
      }
      
      await batch.commit();
      debugPrint('✅ Limpeza concluída');
    } catch (e) {
      debugPrint('❌ Erro na limpeza: $e');
    }
  }

  /// Sincroniza com Riverpod - usado para bridge híbrida
  /// Este método é chamado quando o Riverpod muda o estado
  void syncWithRiverpod(Map<String, List<dynamic>> newCache, bool initialized, bool initializing, String? error) {
    debugPrint('🔄 [PROVIDER] Sincronizando com Riverpod (Notes)');
    
    // Atualizar cache com dados do Riverpod
    _notesCache.clear();
    newCache.forEach((key, value) {
      _notesCache[key] = value.cast<NoteItem>();
    });
    
    _isInitialized = initialized;
    _isInitializing = initializing;
    
    // Notificar listeners para que todos os Provider.of<NotesService> reajam
    notifyListeners();
  }
  
  /// Função estática para acesso global à instância (bridge híbrida)
  static NotesService? get globalInstance => _globalNotesService;
}