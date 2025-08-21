import 'package:flutter/material.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/widgets/playlist_selection_dialog.dart';
import 'package:versee/providers/riverpod_providers.dart';
import 'package:versee/models/note_models.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/models/bible_models.dart';

/// Classe helper com métodos utilitários para facilitar o uso do sistema de playlist
class PlaylistHelpers {
  
  /// Mostra o diálogo de seleção de playlist para versículos
  static void addBibleVersesToPlaylist(
    BuildContext context,
    List<BibleVerse> verses, {
    String? collectionTitle,
    VoidCallback? onCompleted,
  }) {
    final items = verses.map((verse) {
      return PresentationItem(
        id: '${verse.book}_${verse.chapter}_${verse.verse}',
        title: verse.reference,
        type: ContentType.bible,
        content: verse.text,
        metadata: {
          'reference': verse.reference,
          'version': verse.version,
          'book': verse.book,
          'chapter': verse.chapter,
          'verse': verse.verse,
        },
      );
    }).toList();

    showDialog(
      context: context,
      builder: (context) => PlaylistSelectionDialog(
        itemsToAdd: items,
        itemTypeLabel: verses.length == 1 ? 'versículo' : 'versículos',
        onCompleted: onCompleted,
      ),
    );
  }

  /// Mostra o diálogo de seleção de playlist para uma coleção de versículos
  static void addVerseCollectionToPlaylist(
    BuildContext context,
    VerseCollection collection, {
    VoidCallback? onCompleted,
  }) {
    addBibleVersesToPlaylist(
      context,
      collection.verses,
      collectionTitle: collection.title,
      onCompleted: onCompleted,
    );
  }

  /// Mostra o diálogo de seleção de playlist para notas
  static void addNotesToPlaylist(
    BuildContext context,
    List<NoteItem> notes, {
    VoidCallback? onCompleted,
  }) {
    final items = <PresentationItem>[];
    
    for (final note in notes) {
      items.addAll(note.toPresentationItems());
    }

    showDialog(
      context: context,
      builder: (context) => PlaylistSelectionDialog(
        itemsToAdd: items,
        itemTypeLabel: _getNoteTypeLabel(notes),
        onCompleted: onCompleted,
      ),
    );
  }

  /// Mostra o diálogo de seleção de playlist para uma única nota
  static void addSingleNoteToPlaylist(
    BuildContext context,
    NoteItem note, {
    VoidCallback? onCompleted,
  }) {
    addNotesToPlaylist(context, [note], onCompleted: onCompleted);
  }

  /// Mostra o diálogo de seleção de playlist para mídia
  static void addMediaToPlaylist(
    BuildContext context,
    List<MediaItem> mediaItems, {
    VoidCallback? onCompleted,
  }) {
    final items = mediaItems.map((media) => media.toPresentationItem()).toList();

    showDialog(
      context: context,
      builder: (context) => PlaylistSelectionDialog(
        itemsToAdd: items,
        itemTypeLabel: _getMediaTypeLabel(mediaItems),
        onCompleted: onCompleted,
      ),
    );
  }

  /// Mostra o diálogo de seleção de playlist para um único item de mídia
  static void addSingleMediaToPlaylist(
    BuildContext context,
    MediaItem mediaItem, {
    VoidCallback? onCompleted,
  }) {
    addMediaToPlaylist(context, [mediaItem], onCompleted: onCompleted);
  }

  /// Mostra o diálogo de seleção de playlist para items de apresentação genéricos
  static void addPresentationItemsToPlaylist(
    BuildContext context,
    List<PresentationItem> items, {
    required String itemTypeLabel,
    VoidCallback? onCompleted,
  }) {
    showDialog(
      context: context,
      builder: (context) => PlaylistSelectionDialog(
        itemsToAdd: items,
        itemTypeLabel: itemTypeLabel,
        onCompleted: onCompleted,
      ),
    );
  }

  /// Determina o rótulo correto para tipos de notas
  static String _getNoteTypeLabel(List<NoteItem> notes) {
    if (notes.isEmpty) return 'item';
    if (notes.length == 1) {
      return notes.first.type == NotesContentType.lyrics ? 'letra' : 'nota';
    }
    
    // Verifica se todas são do mesmo tipo
    final firstType = notes.first.type;
    final allSameType = notes.every((note) => note.type == firstType);
    
    if (allSameType) {
      return firstType == NotesContentType.lyrics ? 'letras' : 'notas';
    }
    
    return 'itens';
  }

  /// Determina o rótulo correto para tipos de mídia
  static String _getMediaTypeLabel(List<MediaItem> mediaItems) {
    if (mediaItems.isEmpty) return 'item';
    if (mediaItems.length == 1) {
      return _getSingleMediaTypeLabel(mediaItems.first);
    }
    
    // Verifica se todas são do mesmo tipo
    final firstType = mediaItems.first.type;
    final allSameType = mediaItems.every((media) => media.type == firstType);
    
    if (allSameType) {
      return _getPluralMediaTypeLabel(firstType);
    }
    
    return 'mídias';
  }

  static String _getSingleMediaTypeLabel(MediaItem mediaItem) {
    switch (mediaItem.type) {
      case MediaContentType.audio: return 'áudio';
      case MediaContentType.video: return 'vídeo';
      case MediaContentType.image: return 'imagem';
    }
  }

  static String _getPluralMediaTypeLabel(MediaContentType type) {
    switch (type) {
      case MediaContentType.audio: return 'áudios';
      case MediaContentType.video: return 'vídeos';
      case MediaContentType.image: return 'imagens';
    }
  }

  /// Cria um PresentationItem de qualquer tipo de conteúdo comum
  static PresentationItem createPresentationItem({
    required String id,
    required String title,
    required ContentType type,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return PresentationItem(
      id: id,
      title: title,
      type: type,
      content: content,
      metadata: metadata,
    );
  }

  /// Cria PresentationItems a partir de diferentes tipos de conteúdo
  static List<PresentationItem> createFromMixedContent({
    List<BibleVerse>? verses,
    List<NoteItem>? notes,
    List<MediaItem>? mediaItems,
  }) {
    final items = <PresentationItem>[];

    // Adiciona versículos
    if (verses != null) {
      for (final verse in verses) {
        items.add(PresentationItem(
          id: '${verse.book}_${verse.chapter}_${verse.verse}',
          title: verse.reference,
          type: ContentType.bible,
          content: verse.text,
          metadata: {
            'reference': verse.reference,
            'version': verse.version,
            'book': verse.book,
            'chapter': verse.chapter,
            'verse': verse.verse,
          },
        ));
      }
    }

    // Adiciona notas
    if (notes != null) {
      for (final note in notes) {
        items.addAll(note.toPresentationItems());
      }
    }

    // Adiciona mídia
    if (mediaItems != null) {
      for (final media in mediaItems) {
        items.add(media.toPresentationItem());
      }
    }

    return items;
  }

  /// Mostra diálogo para conteúdo misto
  static void addMixedContentToPlaylist(
    BuildContext context, {
    List<BibleVerse>? verses,
    List<NoteItem>? notes,
    List<MediaItem>? mediaItems,
    VoidCallback? onCompleted,
  }) {
    final items = createFromMixedContent(
      verses: verses,
      notes: notes,
      mediaItems: mediaItems,
    );

    if (items.isEmpty) return;

    final typeLabel = _determineMixedContentLabel(verses, notes, mediaItems);

    showDialog(
      context: context,
      builder: (context) => PlaylistSelectionDialog(
        itemsToAdd: items,
        itemTypeLabel: typeLabel,
        onCompleted: onCompleted,
      ),
    );
  }

  static String _determineMixedContentLabel(
    List<BibleVerse>? verses,
    List<NoteItem>? notes,
    List<MediaItem>? mediaItems,
  ) {
    final types = <String>[];
    
    if (verses != null && verses.isNotEmpty) {
      types.add(verses.length == 1 ? 'versículo' : 'versículos');
    }
    
    if (notes != null && notes.isNotEmpty) {
      types.add(_getNoteTypeLabel(notes));
    }
    
    if (mediaItems != null && mediaItems.isNotEmpty) {
      types.add(_getMediaTypeLabel(mediaItems));
    }

    if (types.isEmpty) return 'item';
    if (types.length == 1) return types.first;
    if (types.length == 2) return '${types[0]} e ${types[1]}';
    
    // Para 3 ou mais tipos
    final lastType = types.removeLast();
    return '${types.join(', ')} e $lastType';
  }
}