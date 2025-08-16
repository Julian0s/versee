// Bible-related data models for VERSEE

class BibleVerse {
  final String reference;
  final String text;
  final String version;
  final String book;
  final int chapter;
  final int verse;

  BibleVerse({
    required this.reference,
    required this.text,
    required this.version,
    required this.book,
    required this.chapter,
    required this.verse,
  });

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      reference: json['reference'] ?? '',
      text: json['text'] ?? '',
      version: json['version'] ?? '',
      book: json['book'] ?? '',
      chapter: json['chapter'] ?? 0,
      verse: json['verse'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'text': text,
      'version': version,
      'book': book,
      'chapter': chapter,
      'verse': verse,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BibleVerse &&
        other.reference == reference &&
        other.version == version;
  }

  @override
  int get hashCode => reference.hashCode ^ version.hashCode;
}

class VerseCollection {
  final String id;
  final String title;
  final List<BibleVerse> verses;
  final DateTime createdDate;

  VerseCollection({
    required this.id,
    required this.title,
    required this.verses,
    required this.createdDate,
  });

  factory VerseCollection.fromJson(Map<String, dynamic> json) {
    return VerseCollection(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      verses: (json['verses'] as List? ?? [])
          .map((v) => BibleVerse.fromJson(v))
          .toList(),
      createdDate: DateTime.parse(json['createdDate'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'verses': verses.map((v) => v.toJson()).toList(),
      'createdDate': createdDate.toIso8601String(),
    };
  }

  int get slideCount => verses.length;
  String get verseReferences => verses.map((v) => v.reference).join(', ');
}

class BibleBook {
  final String id;         // Scripture API Bible ID
  final String name;
  final int chapters;
  final String abbreviation;
  final bool isOldTestament;

  BibleBook({
    required this.id,
    required this.name,
    required this.chapters,
    required this.abbreviation,
    required this.isOldTestament,
  });

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      chapters: json['chapters'] ?? 0,
      abbreviation: json['abbreviation'] ?? '',
      isOldTestament: json['isOldTestament'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'chapters': chapters,
      'abbreviation': abbreviation,
      'isOldTestament': isOldTestament,
    };
  }
}

class BibleVersionInfo {
  final String id;
  final String name;
  final String abbreviation;
  final String language;
  final bool isPopular;
  final bool isImported;

  const BibleVersionInfo({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.language,
    required this.isPopular,
    this.isImported = false,
  });

  factory BibleVersionInfo.fromJson(Map<String, dynamic> json) {
    return BibleVersionInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      abbreviation: json['abbreviation'] ?? '',
      language: json['language'] ?? 'pt',
      isPopular: json['isPopular'] ?? false,
      isImported: json['isImported'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'abbreviation': abbreviation,
      'language': language,
      'isPopular': isPopular,
      'isImported': isImported,
    };
  }
}

class SearchHistory {
  final String query;
  final DateTime timestamp;
  final String? resultCount;

  SearchHistory({
    required this.query,
    required this.timestamp,
    this.resultCount,
  });

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      query: json['query'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      resultCount: json['resultCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'resultCount': resultCount,
    };
  }
}

// Enum for sorting criteria
enum SortCriteria {
  dateNewest,
  dateOldest,
  biblical,
  alphabetical,
}

// Predefined Bible books data
class BibleData {
  static final List<BibleBook> oldTestamentBooks = [
    BibleBook(id: 'GEN', name: 'Gênesis', chapters: 50, abbreviation: 'Gn', isOldTestament: true),
    BibleBook(id: 'EXO', name: 'Êxodo', chapters: 40, abbreviation: 'Ex', isOldTestament: true),
    BibleBook(id: 'LEV', name: 'Levítico', chapters: 27, abbreviation: 'Lv', isOldTestament: true),
    BibleBook(id: 'NUM', name: 'Números', chapters: 36, abbreviation: 'Nm', isOldTestament: true),
    BibleBook(id: 'DEU', name: 'Deuteronômio', chapters: 34, abbreviation: 'Dt', isOldTestament: true),
    BibleBook(id: 'JOS', name: 'Josué', chapters: 24, abbreviation: 'Js', isOldTestament: true),
    BibleBook(id: 'JDG', name: 'Juízes', chapters: 21, abbreviation: 'Jz', isOldTestament: true),
    BibleBook(id: 'RUT', name: 'Rute', chapters: 4, abbreviation: 'Rt', isOldTestament: true),
    BibleBook(id: '1SA', name: '1 Samuel', chapters: 31, abbreviation: '1Sm', isOldTestament: true),
    BibleBook(id: '2SA', name: '2 Samuel', chapters: 24, abbreviation: '2Sm', isOldTestament: true),
    BibleBook(id: '1KI', name: '1 Reis', chapters: 22, abbreviation: '1Rs', isOldTestament: true),
    BibleBook(id: '2KI', name: '2 Reis', chapters: 25, abbreviation: '2Rs', isOldTestament: true),
    BibleBook(id: '1CH', name: '1 Crônicas', chapters: 29, abbreviation: '1Cr', isOldTestament: true),
    BibleBook(id: '2CH', name: '2 Crônicas', chapters: 36, abbreviation: '2Cr', isOldTestament: true),
    BibleBook(id: 'EZR', name: 'Esdras', chapters: 10, abbreviation: 'Ed', isOldTestament: true),
    BibleBook(id: 'NEH', name: 'Neemias', chapters: 13, abbreviation: 'Ne', isOldTestament: true),
    BibleBook(id: 'EST', name: 'Ester', chapters: 10, abbreviation: 'Et', isOldTestament: true),
    BibleBook(id: 'JOB', name: 'Jó', chapters: 42, abbreviation: 'Jó', isOldTestament: true),
    BibleBook(id: 'PSA', name: 'Salmos', chapters: 150, abbreviation: 'Sl', isOldTestament: true),
    BibleBook(id: 'PRO', name: 'Provérbios', chapters: 31, abbreviation: 'Pv', isOldTestament: true),
    BibleBook(id: 'ECC', name: 'Eclesiastes', chapters: 12, abbreviation: 'Ec', isOldTestament: true),
    BibleBook(id: 'SNG', name: 'Cânticos', chapters: 8, abbreviation: 'Ct', isOldTestament: true),
    BibleBook(id: 'ISA', name: 'Isaías', chapters: 66, abbreviation: 'Is', isOldTestament: true),
    BibleBook(id: 'JER', name: 'Jeremias', chapters: 52, abbreviation: 'Jr', isOldTestament: true),
    BibleBook(id: 'LAM', name: 'Lamentações', chapters: 5, abbreviation: 'Lm', isOldTestament: true),
    BibleBook(id: 'EZK', name: 'Ezequiel', chapters: 48, abbreviation: 'Ez', isOldTestament: true),
    BibleBook(id: 'DAN', name: 'Daniel', chapters: 12, abbreviation: 'Dn', isOldTestament: true),
    BibleBook(id: 'HOS', name: 'Oséias', chapters: 14, abbreviation: 'Os', isOldTestament: true),
    BibleBook(id: 'JOL', name: 'Joel', chapters: 3, abbreviation: 'Jl', isOldTestament: true),
    BibleBook(id: 'AMO', name: 'Amós', chapters: 9, abbreviation: 'Am', isOldTestament: true),
    BibleBook(id: 'OBA', name: 'Obadias', chapters: 1, abbreviation: 'Ob', isOldTestament: true),
    BibleBook(id: 'JON', name: 'Jonas', chapters: 4, abbreviation: 'Jn', isOldTestament: true),
    BibleBook(id: 'MIC', name: 'Miquéias', chapters: 7, abbreviation: 'Mq', isOldTestament: true),
    BibleBook(id: 'NAM', name: 'Naum', chapters: 3, abbreviation: 'Na', isOldTestament: true),
    BibleBook(id: 'HAB', name: 'Habacuque', chapters: 3, abbreviation: 'Hc', isOldTestament: true),
    BibleBook(id: 'ZEP', name: 'Sofonias', chapters: 3, abbreviation: 'Sf', isOldTestament: true),
    BibleBook(id: 'HAG', name: 'Ageu', chapters: 2, abbreviation: 'Ag', isOldTestament: true),
    BibleBook(id: 'ZEC', name: 'Zacarias', chapters: 14, abbreviation: 'Zc', isOldTestament: true),
    BibleBook(id: 'MAL', name: 'Malaquias', chapters: 4, abbreviation: 'Ml', isOldTestament: true),
  ];

  static final List<BibleBook> newTestamentBooks = [
    BibleBook(id: 'MAT', name: 'Mateus', chapters: 28, abbreviation: 'Mt', isOldTestament: false),
    BibleBook(id: 'MRK', name: 'Marcos', chapters: 16, abbreviation: 'Mc', isOldTestament: false),
    BibleBook(id: 'LUK', name: 'Lucas', chapters: 24, abbreviation: 'Lc', isOldTestament: false),
    BibleBook(id: 'JHN', name: 'João', chapters: 21, abbreviation: 'Jo', isOldTestament: false),
    BibleBook(id: 'ACT', name: 'Atos', chapters: 28, abbreviation: 'At', isOldTestament: false),
    BibleBook(id: 'ROM', name: 'Romanos', chapters: 16, abbreviation: 'Rm', isOldTestament: false),
    BibleBook(id: '1CO', name: '1 Coríntios', chapters: 16, abbreviation: '1Co', isOldTestament: false),
    BibleBook(id: '2CO', name: '2 Coríntios', chapters: 13, abbreviation: '2Co', isOldTestament: false),
    BibleBook(id: 'GAL', name: 'Gálatas', chapters: 6, abbreviation: 'Gl', isOldTestament: false),
    BibleBook(id: 'EPH', name: 'Efésios', chapters: 6, abbreviation: 'Ef', isOldTestament: false),
    BibleBook(id: 'PHP', name: 'Filipenses', chapters: 4, abbreviation: 'Fp', isOldTestament: false),
    BibleBook(id: 'COL', name: 'Colossenses', chapters: 4, abbreviation: 'Cl', isOldTestament: false),
    BibleBook(id: '1TH', name: '1 Tessalonicenses', chapters: 5, abbreviation: '1Ts', isOldTestament: false),
    BibleBook(id: '2TH', name: '2 Tessalonicenses', chapters: 3, abbreviation: '2Ts', isOldTestament: false),
    BibleBook(id: '1TI', name: '1 Timóteo', chapters: 6, abbreviation: '1Tm', isOldTestament: false),
    BibleBook(id: '2TI', name: '2 Timóteo', chapters: 4, abbreviation: '2Tm', isOldTestament: false),
    BibleBook(id: 'TIT', name: 'Tito', chapters: 3, abbreviation: 'Tt', isOldTestament: false),
    BibleBook(id: 'PHM', name: 'Filemom', chapters: 1, abbreviation: 'Fm', isOldTestament: false),
    BibleBook(id: 'HEB', name: 'Hebreus', chapters: 13, abbreviation: 'Hb', isOldTestament: false),
    BibleBook(id: 'JAS', name: 'Tiago', chapters: 5, abbreviation: 'Tg', isOldTestament: false),
    BibleBook(id: '1PE', name: '1 Pedro', chapters: 5, abbreviation: '1Pe', isOldTestament: false),
    BibleBook(id: '2PE', name: '2 Pedro', chapters: 3, abbreviation: '2Pe', isOldTestament: false),
    BibleBook(id: '1JN', name: '1 João', chapters: 5, abbreviation: '1Jo', isOldTestament: false),
    BibleBook(id: '2JN', name: '2 João', chapters: 1, abbreviation: '2Jo', isOldTestament: false),
    BibleBook(id: '3JN', name: '3 João', chapters: 1, abbreviation: '3Jo', isOldTestament: false),
    BibleBook(id: 'JUD', name: 'Judas', chapters: 1, abbreviation: 'Jd', isOldTestament: false),
    BibleBook(id: 'REV', name: 'Apocalipse', chapters: 22, abbreviation: 'Ap', isOldTestament: false),
  ];

  static List<BibleBook> get allBooks => [...oldTestamentBooks, ...newTestamentBooks];
}