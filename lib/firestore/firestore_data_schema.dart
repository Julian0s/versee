import 'package:cloud_firestore/cloud_firestore.dart';

/// Schema de dados para o Firestore do VERSEE
/// Este arquivo define a estrutura de todas as coleções do banco de dados

class FirestoreDataSchema {
  static const String usersCollection = 'users';
  static const String playlistsCollection = 'playlists';
  static const String notesCollection = 'notes';
  static const String lyricsCollection = 'lyrics';
  static const String mediaCollection = 'media';
  static const String verseCollectionsCollection = 'verseCollections';
  static const String settingsCollection = 'settings';

  /// Estrutura do documento de usuário
  /// Coleção: users
  /// Documento ID: userId (vem do Firebase Auth)
  static Map<String, dynamic> userDocument({
    required String email,
    required String displayName,
    required String plan, // 'free' ou 'premium'
    required String language, // 'pt', 'en', 'es'
    required String theme, // 'dark', 'light'
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return {
      'email': email,
      'displayName': displayName,
      'plan': plan,
      'language': language,
      'theme': theme,
      'createdAt': createdAt ?? now,
      'updatedAt': updatedAt ?? now,
    };
  }

  /// Estrutura do documento de playlist
  /// Coleção: playlists
  static Map<String, dynamic> playlistDocument({
    required String userId,
    required String title,
    required String description,
    required List<Map<String, dynamic>> items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'items': items,
      'itemCount': items.length,
      'createdAt': createdAt ?? now,
      'updatedAt': updatedAt ?? now,
    };
  }

  /// Estrutura do documento de nota
  /// Coleção: notes
  static Map<String, dynamic> noteDocument({
    required String userId,
    required String title,
    String? description,
    required List<Map<String, dynamic>> slides,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return {
      'userId': userId,
      'title': title,
      'description': description ?? '',
      'slides': slides,
      'slideCount': slides.length,
      'createdAt': createdAt ?? now,
      'updatedAt': updatedAt ?? now,
    };
  }

  /// Estrutura do documento de lyrics
  /// Coleção: lyrics
  static Map<String, dynamic> lyricsDocument({
    required String userId,
    required String title,
    String? description,
    required List<Map<String, dynamic>> slides,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return {
      'userId': userId,
      'title': title,
      'description': description ?? '',
      'slides': slides,
      'slideCount': slides.length,
      'createdAt': createdAt ?? now,
      'updatedAt': updatedAt ?? now,
    };
  }

  /// Estrutura do documento de mídia
  /// Coleção: media
  static Map<String, dynamic> mediaDocument({
    required String userId,
    required String type, // 'audio', 'video', 'image'
    required String name,
    required String fileName,
    required String storagePath,
    required int fileSize,
    String? duration, // Para áudio/vídeo
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return {
      'userId': userId,
      'type': type,
      'name': name,
      'fileName': fileName,
      'storagePath': storagePath,
      'fileSize': fileSize,
      'duration': duration,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt ?? now,
      'updatedAt': updatedAt ?? now,
    };
  }

  /// Estrutura do documento de coleção de versículos
  /// Coleção: verseCollections
  static Map<String, dynamic> verseCollectionDocument({
    required String userId,
    required String title,
    required List<Map<String, dynamic>> verses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return {
      'userId': userId,
      'title': title,
      'verses': verses,
      'verseCount': verses.length,
      'createdAt': createdAt ?? now,
      'updatedAt': updatedAt ?? now,
    };
  }

  /// Estrutura do documento de configurações
  /// Coleção: settings
  /// Documento ID: userId
  static Map<String, dynamic> settingsDocument({
    required String userId,
    required Map<String, dynamic> bibleVersions,
    required Map<String, dynamic> secondScreenSettings,
    required Map<String, dynamic> generalSettings,
    DateTime? updatedAt,
  }) {
    return {
      'userId': userId,
      'bibleVersions': bibleVersions,
      'secondScreenSettings': secondScreenSettings,
      'generalSettings': generalSettings,
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  /// Estrutura de um slide de nota
  static Map<String, dynamic> noteSlide({
    required int order,
    required String content,
    String? backgroundColor,
    String? textColor,
    String? fontSize,
  }) {
    return {
      'order': order,
      'content': content,
      'backgroundColor': backgroundColor ?? '#000000',
      'textColor': textColor ?? '#FFFFFF',
      'fontSize': fontSize ?? 'medium',
    };
  }

  /// Estrutura de um versículo
  static Map<String, dynamic> verse({
    required String book,
    required int chapter,
    required int verse,
    required String text,
    required String version,
  }) {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
      'version': version,
      'reference': '$book $chapter:$verse',
    };
  }

  /// Estrutura de um item de playlist
  static Map<String, dynamic> playlistItem({
    required int order,
    required String type, // 'note', 'media', 'verseCollection'
    required String itemId,
    required String title,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'order': order,
      'type': type,
      'itemId': itemId,
      'title': title,
      'metadata': metadata ?? {},
    };
  }
}

/// Utilitários para conversão de dados
class FirestoreConverter {
  /// Converte Timestamp do Firestore para DateTime
  static DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return null;
  }

  /// Converte DateTime para Timestamp do Firestore
  static Timestamp? dateTimeToTimestamp(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }

  /// Converte Map para incluir timestamps corretos
  static Map<String, dynamic> prepareForFirestore(Map<String, dynamic> data) {
    final prepared = Map<String, dynamic>.from(data);
    
    // Converte DateTime para Timestamp
    prepared.forEach((key, value) {
      if (value is DateTime) {
        prepared[key] = Timestamp.fromDate(value);
      }
    });
    
    return prepared;
  }

  /// Converte dados do Firestore para uso no app
  static Map<String, dynamic> parseFromFirestore(Map<String, dynamic> data) {
    final parsed = Map<String, dynamic>.from(data);
    
    // Converte Timestamp para DateTime
    parsed.forEach((key, value) {
      if (value is Timestamp) {
        parsed[key] = value.toDate();
      }
    });
    
    return parsed;
  }
}