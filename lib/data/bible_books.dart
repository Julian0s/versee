/// Bible books data with correct Scripture API Bible IDs
/// This file contains all 66 books of the Bible with proper IDs for API integration

enum Testament {
  oldTestament,
  newTestament,
}

class BibleBook {
  final String id;         // Scripture API Bible ID (e.g., "GEN", "JHN")
  final String name;       // Portuguese name (e.g., "Gênesis", "João")
  final Testament testament;
  final int chapters;

  BibleBook({
    required this.id,
    required this.name,
    required this.testament,
    required this.chapters,
  });

  /// Legacy compatibility - returns Portuguese abbreviation
  String get abbreviation => _getPortugueseAbbreviation();

  /// Legacy compatibility - returns whether it's Old Testament
  bool get isOldTestament => testament == Testament.oldTestament;

  String _getPortugueseAbbreviation() {
    const abbreviations = {
      'GEN': 'Gn', 'EXO': 'Ex', 'LEV': 'Lv', 'NUM': 'Nm', 'DEU': 'Dt',
      'JOS': 'Js', 'JDG': 'Jz', 'RUT': 'Rt', '1SA': '1Sm', '2SA': '2Sm',
      '1KI': '1Rs', '2KI': '2Rs', '1CH': '1Cr', '2CH': '2Cr', 'EZR': 'Ed',
      'NEH': 'Ne', 'EST': 'Et', 'JOB': 'Jó', 'PSA': 'Sl', 'PRO': 'Pv',
      'ECC': 'Ec', 'SNG': 'Ct', 'ISA': 'Is', 'JER': 'Jr', 'LAM': 'Lm',
      'EZK': 'Ez', 'DAN': 'Dn', 'HOS': 'Os', 'JOL': 'Jl', 'AMO': 'Am',
      'OBA': 'Ob', 'JON': 'Jn', 'MIC': 'Mq', 'NAM': 'Na', 'HAB': 'Hc',
      'ZEP': 'Sf', 'HAG': 'Ag', 'ZEC': 'Zc', 'MAL': 'Ml', 'MAT': 'Mt',
      'MRK': 'Mc', 'LUK': 'Lc', 'JHN': 'Jo', 'ACT': 'At', 'ROM': 'Rm',
      '1CO': '1Co', '2CO': '2Co', 'GAL': 'Gl', 'EPH': 'Ef', 'PHP': 'Fp',
      'COL': 'Cl', '1TH': '1Ts', '2TH': '2Ts', '1TI': '1Tm', '2TI': '2Tm',
      'TIT': 'Tt', 'PHM': 'Fm', 'HEB': 'Hb', 'JAS': 'Tg', '1PE': '1Pe',
      '2PE': '2Pe', '1JN': '1Jo', '2JN': '2Jo', '3JN': '3Jo', 'JUD': 'Jd',
      'REV': 'Ap',
    };
    return abbreviations[id] ?? id;
  }
}

/// Complete list of the 66 biblical books with Scripture API Bible IDs
final List<BibleBook> bibleBooks = [
  // Antigo Testamento (39 books)
  BibleBook(id: 'GEN', name: 'Gênesis', testament: Testament.oldTestament, chapters: 50),
  BibleBook(id: 'EXO', name: 'Êxodo', testament: Testament.oldTestament, chapters: 40),
  BibleBook(id: 'LEV', name: 'Levítico', testament: Testament.oldTestament, chapters: 27),
  BibleBook(id: 'NUM', name: 'Números', testament: Testament.oldTestament, chapters: 36),
  BibleBook(id: 'DEU', name: 'Deuteronômio', testament: Testament.oldTestament, chapters: 34),
  BibleBook(id: 'JOS', name: 'Josué', testament: Testament.oldTestament, chapters: 24),
  BibleBook(id: 'JDG', name: 'Juízes', testament: Testament.oldTestament, chapters: 21),
  BibleBook(id: 'RUT', name: 'Rute', testament: Testament.oldTestament, chapters: 4),
  BibleBook(id: '1SA', name: '1 Samuel', testament: Testament.oldTestament, chapters: 31),
  BibleBook(id: '2SA', name: '2 Samuel', testament: Testament.oldTestament, chapters: 24),
  BibleBook(id: '1KI', name: '1 Reis', testament: Testament.oldTestament, chapters: 22),
  BibleBook(id: '2KI', name: '2 Reis', testament: Testament.oldTestament, chapters: 25),
  BibleBook(id: '1CH', name: '1 Crônicas', testament: Testament.oldTestament, chapters: 29),
  BibleBook(id: '2CH', name: '2 Crônicas', testament: Testament.oldTestament, chapters: 36),
  BibleBook(id: 'EZR', name: 'Esdras', testament: Testament.oldTestament, chapters: 10),
  BibleBook(id: 'NEH', name: 'Neemias', testament: Testament.oldTestament, chapters: 13),
  BibleBook(id: 'EST', name: 'Ester', testament: Testament.oldTestament, chapters: 10),
  BibleBook(id: 'JOB', name: 'Jó', testament: Testament.oldTestament, chapters: 42),
  BibleBook(id: 'PSA', name: 'Salmos', testament: Testament.oldTestament, chapters: 150),
  BibleBook(id: 'PRO', name: 'Provérbios', testament: Testament.oldTestament, chapters: 31),
  BibleBook(id: 'ECC', name: 'Eclesiastes', testament: Testament.oldTestament, chapters: 12),
  BibleBook(id: 'SNG', name: 'Cânticos', testament: Testament.oldTestament, chapters: 8),
  BibleBook(id: 'ISA', name: 'Isaías', testament: Testament.oldTestament, chapters: 66),
  BibleBook(id: 'JER', name: 'Jeremias', testament: Testament.oldTestament, chapters: 52),
  BibleBook(id: 'LAM', name: 'Lamentações', testament: Testament.oldTestament, chapters: 5),
  BibleBook(id: 'EZK', name: 'Ezequiel', testament: Testament.oldTestament, chapters: 48),
  BibleBook(id: 'DAN', name: 'Daniel', testament: Testament.oldTestament, chapters: 12),
  BibleBook(id: 'HOS', name: 'Oséias', testament: Testament.oldTestament, chapters: 14),
  BibleBook(id: 'JOL', name: 'Joel', testament: Testament.oldTestament, chapters: 3),
  BibleBook(id: 'AMO', name: 'Amós', testament: Testament.oldTestament, chapters: 9),
  BibleBook(id: 'OBA', name: 'Obadias', testament: Testament.oldTestament, chapters: 1),
  BibleBook(id: 'JON', name: 'Jonas', testament: Testament.oldTestament, chapters: 4),
  BibleBook(id: 'MIC', name: 'Miquéias', testament: Testament.oldTestament, chapters: 7),
  BibleBook(id: 'NAM', name: 'Naum', testament: Testament.oldTestament, chapters: 3),
  BibleBook(id: 'HAB', name: 'Habacuque', testament: Testament.oldTestament, chapters: 3),
  BibleBook(id: 'ZEP', name: 'Sofonias', testament: Testament.oldTestament, chapters: 3),
  BibleBook(id: 'HAG', name: 'Ageu', testament: Testament.oldTestament, chapters: 2),
  BibleBook(id: 'ZEC', name: 'Zacarias', testament: Testament.oldTestament, chapters: 14),
  BibleBook(id: 'MAL', name: 'Malaquias', testament: Testament.oldTestament, chapters: 4),

  // Novo Testamento (27 books)
  BibleBook(id: 'MAT', name: 'Mateus', testament: Testament.newTestament, chapters: 28),
  BibleBook(id: 'MRK', name: 'Marcos', testament: Testament.newTestament, chapters: 16),
  BibleBook(id: 'LUK', name: 'Lucas', testament: Testament.newTestament, chapters: 24),
  BibleBook(id: 'JHN', name: 'João', testament: Testament.newTestament, chapters: 21),
  BibleBook(id: 'ACT', name: 'Atos', testament: Testament.newTestament, chapters: 28),
  BibleBook(id: 'ROM', name: 'Romanos', testament: Testament.newTestament, chapters: 16),
  BibleBook(id: '1CO', name: '1 Coríntios', testament: Testament.newTestament, chapters: 16),
  BibleBook(id: '2CO', name: '2 Coríntios', testament: Testament.newTestament, chapters: 13),
  BibleBook(id: 'GAL', name: 'Gálatas', testament: Testament.newTestament, chapters: 6),
  BibleBook(id: 'EPH', name: 'Efésios', testament: Testament.newTestament, chapters: 6),
  BibleBook(id: 'PHP', name: 'Filipenses', testament: Testament.newTestament, chapters: 4),
  BibleBook(id: 'COL', name: 'Colossenses', testament: Testament.newTestament, chapters: 4),
  BibleBook(id: '1TH', name: '1 Tessalonicenses', testament: Testament.newTestament, chapters: 5),
  BibleBook(id: '2TH', name: '2 Tessalonicenses', testament: Testament.newTestament, chapters: 3),
  BibleBook(id: '1TI', name: '1 Timóteo', testament: Testament.newTestament, chapters: 6),
  BibleBook(id: '2TI', name: '2 Timóteo', testament: Testament.newTestament, chapters: 4),
  BibleBook(id: 'TIT', name: 'Tito', testament: Testament.newTestament, chapters: 3),
  BibleBook(id: 'PHM', name: 'Filemom', testament: Testament.newTestament, chapters: 1),
  BibleBook(id: 'HEB', name: 'Hebreus', testament: Testament.newTestament, chapters: 13),
  BibleBook(id: 'JAS', name: 'Tiago', testament: Testament.newTestament, chapters: 5),
  BibleBook(id: '1PE', name: '1 Pedro', testament: Testament.newTestament, chapters: 5),
  BibleBook(id: '2PE', name: '2 Pedro', testament: Testament.newTestament, chapters: 3),
  BibleBook(id: '1JN', name: '1 João', testament: Testament.newTestament, chapters: 5),
  BibleBook(id: '2JN', name: '2 João', testament: Testament.newTestament, chapters: 1),
  BibleBook(id: '3JN', name: '3 João', testament: Testament.newTestament, chapters: 1),
  BibleBook(id: 'JUD', name: 'Judas', testament: Testament.newTestament, chapters: 1),
  BibleBook(id: 'REV', name: 'Apocalipse', testament: Testament.newTestament, chapters: 22),
];

/// Utility class for working with Bible books
class BibleBooksHelper {
  /// Get Old Testament books only
  static List<BibleBook> get oldTestamentBooks => 
      bibleBooks.where((book) => book.testament == Testament.oldTestament).toList();

  /// Get New Testament books only
  static List<BibleBook> get newTestamentBooks => 
      bibleBooks.where((book) => book.testament == Testament.newTestament).toList();

  /// Find a book by name (Portuguese)
  static BibleBook? findByName(String name) => 
      bibleBooks.cast<BibleBook?>().firstWhere((book) => book?.name == name, orElse: () => null);

  /// Find a book by API ID
  static BibleBook? findById(String id) => 
      bibleBooks.cast<BibleBook?>().firstWhere((book) => book?.id == id, orElse: () => null);

  /// Get API ID for a Portuguese book name
  static String? getApiId(String bookName) => findByName(bookName)?.id;
}