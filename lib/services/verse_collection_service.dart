import 'package:flutter/foundation.dart';
import 'package:versee/models/bible_models.dart';
import 'package:versee/services/typed_firebase_service.dart';
import 'dart:async';

/// Serviço para gerenciar coleções de versículos salvos integrado com Firebase
class VerseCollectionService extends ChangeNotifier {
  static final VerseCollectionService _instance = VerseCollectionService._internal();
  factory VerseCollectionService() => _instance;
  VerseCollectionService._internal() {
    _initializeFirebaseConnection();
  }

  final TypedFirebaseService _firebaseService = TypedFirebaseService();
  final List<VerseCollection> _collections = [];
  StreamSubscription<List<VerseCollection>>? _collectionsSubscription;

  @override
  void dispose() {
    _collectionsSubscription?.cancel();
    super.dispose();
  }

  List<VerseCollection> get collections => List.unmodifiable(_collections);

  /// Inicializa conexão com Firebase e sincroniza dados
  void _initializeFirebaseConnection() {
    if (_firebaseService.isAuthenticated) {
      _listenToCollectionChanges();
    } else {
      _firebaseService.authStateChanges.listen((user) {
        if (user != null) {
          _listenToCollectionChanges();
        } else {
          _clearLocalCollections();
        }
      });
    }
  }

  /// Escuta mudanças nas coleções do Firebase
  void _listenToCollectionChanges() {
    if (!_firebaseService.isAuthenticated) {
      debugPrint('⚠️ Usuário não autenticado - não carregando coleções');
      return;
    }
    
    _collectionsSubscription?.cancel();
    _collectionsSubscription = _firebaseService.getUserVerseCollections().listen(
      (collections) {
        try {
          debugPrint('🔄 Carregando ${collections.length} coleções do Firebase');
          _collections.clear();
          _collections.addAll(collections);
          debugPrint('✅ ${_collections.length} coleções carregadas com sucesso');
          notifyListeners();
        } catch (e) {
          debugPrint('❌ Erro ao processar coleções: $e');
        }
      },
      onError: (error) {
        debugPrint('❌ Erro ao carregar coleções: $error');
      },
    );
  }

  /// Limpa coleções locais
  void _clearLocalCollections() {
    _collections.clear();
    notifyListeners();
  }

  /// Adiciona uma nova coleção no Firebase
  Future<bool> addCollection(VerseCollection collection) async {
    try {
      if (!_firebaseService.isAuthenticated) {
        debugPrint('❌ Usuário não autenticado');
        return false;
      }

      final collectionId = await _firebaseService.createVerseCollection(collection);
      if (collectionId != null) {
        debugPrint('✅ Coleção criada no Firebase: $collectionId');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao adicionar coleção: $e');
      return false;
    }
  }

  /// Remove uma coleção do Firebase
  Future<bool> removeCollection(String id) async {
    try {
      if (!_firebaseService.isAuthenticated) {
        debugPrint('❌ Usuário não autenticado');
        return false;
      }

      final success = await _firebaseService.deleteVerseCollection(id);
      if (success) {
        debugPrint('✅ Coleção removida do Firebase: $id');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Erro ao remover coleção: $e');
      return false;
    }
  }

  /// Atualiza uma coleção existente no Firebase
  Future<bool> updateCollection(VerseCollection updatedCollection) async {
    try {
      if (!_firebaseService.isAuthenticated) {
        debugPrint('❌ Usuário não autenticado');
        return false;
      }

      final updates = {
        'title': updatedCollection.title,
        'verses': updatedCollection.verses.map((verse) => verse.toJson()).toList(),
        'updatedAt': DateTime.now(),
      };

      final success = await _firebaseService.updateVerseCollection(updatedCollection.id, updates);
      if (success) {
        debugPrint('✅ Coleção atualizada no Firebase: ${updatedCollection.id}');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Erro ao atualizar coleção: $e');
      return false;
    }
  }

  /// Busca uma coleção por ID
  VerseCollection? getCollectionById(String id) {
    try {
      return _collections.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Busca coleções por termo
  List<VerseCollection> searchCollections(String searchTerm) {
    if (searchTerm.isEmpty) return collections;
    
    final term = searchTerm.toLowerCase();
    return _collections.where((collection) {
      return collection.title.toLowerCase().contains(term) ||
          collection.verses.any((verse) => 
            verse.text.toLowerCase().contains(term) ||
            verse.reference.toLowerCase().contains(term)
          );
    }).toList();
  }

  /// Ordena coleções por critério
  void sortCollections(SortCriteria criteria) {
    switch (criteria) {
      case SortCriteria.dateNewest:
        _collections.sort((a, b) => b.createdDate.compareTo(a.createdDate));
        break;
      case SortCriteria.dateOldest:
        _collections.sort((a, b) => a.createdDate.compareTo(b.createdDate));
        break;
      case SortCriteria.alphabetical:
        _collections.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortCriteria.biblical:
        // Ordenação bíblica seria mais complexa, mas por ora fazemos por referência
        _collections.sort((a, b) {
          final aFirstRef = a.verses.isNotEmpty ? a.verses.first.reference : '';
          final bFirstRef = b.verses.isNotEmpty ? b.verses.first.reference : '';
          return aFirstRef.compareTo(bFirstRef);
        });
        break;
    }
    notifyListeners();
  }

  /// Força recarregamento das coleções do Firebase
  Future<void> refreshCollections() async {
    if (_firebaseService.isAuthenticated) {
      _listenToCollectionChanges();
    }
  }

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => _firebaseService.isAuthenticated;
}

