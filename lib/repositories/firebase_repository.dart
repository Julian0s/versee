import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:versee/firestore/firestore_data_schema.dart';

/// Repository central para operações Firebase
/// Implementa o padrão Repository para abstrair operações de banco de dados
class FirebaseRepository {
  static final FirebaseRepository _instance = FirebaseRepository._internal();
  factory FirebaseRepository() => _instance;
  FirebaseRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isAuthenticated => _auth.currentUser != null;

  /// Operações de Autenticação
  
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      rethrow;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Operações de Firestore

  // Operações genéricas de documento
  Future<DocumentReference> addDocument(String collection, Map<String, dynamic> data) async {
    return await _firestore
        .collection(collection)
        .add(FirestoreConverter.prepareForFirestore(data));
  }

  Future<void> setDocument(String collection, String documentId, Map<String, dynamic> data) async {
    await _firestore
        .collection(collection)
        .doc(documentId)
        .set(FirestoreConverter.prepareForFirestore(data));
  }

  Future<void> updateDocument(String collection, String documentId, Map<String, dynamic> data) async {
    data['updatedAt'] = DateTime.now();
    await _firestore
        .collection(collection)
        .doc(documentId)
        .update(FirestoreConverter.prepareForFirestore(data));
  }

  Future<void> deleteDocument(String collection, String documentId) async {
    await _firestore.collection(collection).doc(documentId).delete();
  }

  Future<DocumentSnapshot> getDocument(String collection, String documentId) async {
    return await _firestore.collection(collection).doc(documentId).get();
  }

  Stream<DocumentSnapshot> watchDocument(String collection, String documentId) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }

  // Queries específicas para coleções do usuário
  Stream<QuerySnapshot> getUserCollection(String collection, {String? orderBy, bool descending = true}) {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    Query query = _firestore
        .collection(collection)
        .where('userId', isEqualTo: currentUserId);
    
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    return query.snapshots();
  }

  // Operações batch para múltiplas operações
  WriteBatch createBatch() => _firestore.batch();

  Future<void> commitBatch(WriteBatch batch) => batch.commit();

  /// Operações de Storage

  Reference getStorageRef(String path) => _storage.ref(path);

  String getUserStoragePath(String fileName) => 'users/$currentUserId/$fileName';

  Future<String> uploadFile(String path, Uint8List data, {String? contentType}) async {
    final ref = _storage.ref(path);
    final uploadTask = ref.putData(data, SettableMetadata(contentType: contentType));
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadUserFile(String fileName, Uint8List data, {String? contentType}) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final path = getUserStoragePath(fileName);
    return await uploadFile(path, data, contentType: contentType);
  }

  Future<void> deleteFile(String path) async {
    await _storage.ref(path).delete();
  }

  Future<String> getDownloadURL(String path) async {
    return await _storage.ref(path).getDownloadURL();
  }

  /// Operações específicas do VERSEE

  // Playlists
  Future<String> createPlaylist(Map<String, dynamic> playlistData) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    playlistData['userId'] = currentUserId;
    playlistData['createdAt'] = DateTime.now();
    playlistData['updatedAt'] = DateTime.now();
    
    final docRef = await addDocument(FirestoreDataSchema.playlistsCollection, playlistData);
    return docRef.id;
  }

  Stream<List<Map<String, dynamic>>> getUserPlaylists() {
    return getUserCollection(FirestoreDataSchema.playlistsCollection, orderBy: 'updatedAt')
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>)
                })
            .toList());
  }

  // Notes
  Future<String> createNote(Map<String, dynamic> noteData) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    noteData['userId'] = currentUserId;
    noteData['createdAt'] = DateTime.now();
    noteData['updatedAt'] = DateTime.now();
    
    final docRef = await addDocument(FirestoreDataSchema.notesCollection, noteData);
    return docRef.id;
  }

  Stream<List<Map<String, dynamic>>> getUserNotes() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection(FirestoreDataSchema.notesCollection)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>)
                })
            .toList());
  }

  Future<void> updateNote(String noteId, Map<String, dynamic> data) async {
    await updateDocument(FirestoreDataSchema.notesCollection, noteId, data);
  }

  Future<void> deleteNote(String noteId) async {
    await deleteDocument(FirestoreDataSchema.notesCollection, noteId);
  }

  Future<Map<String, dynamic>?> getNote(String noteId) async {
    final doc = await getDocument(FirestoreDataSchema.notesCollection, noteId);
    if (doc.exists) {
      return {
        'id': doc.id,
        ...FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>)
      };
    }
    return null;
  }

  // Lyrics
  Future<String> createLyrics(Map<String, dynamic> lyricsData) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    lyricsData['userId'] = currentUserId;
    lyricsData['createdAt'] = DateTime.now();
    lyricsData['updatedAt'] = DateTime.now();
    
    final docRef = await addDocument(FirestoreDataSchema.lyricsCollection, lyricsData);
    return docRef.id;
  }

  Stream<List<Map<String, dynamic>>> getUserLyrics() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection(FirestoreDataSchema.lyricsCollection)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>)
                })
            .toList());
  }

  Future<void> updateLyrics(String lyricsId, Map<String, dynamic> data) async {
    await updateDocument(FirestoreDataSchema.lyricsCollection, lyricsId, data);
  }

  Future<void> deleteLyrics(String lyricsId) async {
    await deleteDocument(FirestoreDataSchema.lyricsCollection, lyricsId);
  }

  Future<Map<String, dynamic>?> getLyrics(String lyricsId) async {
    final doc = await getDocument(FirestoreDataSchema.lyricsCollection, lyricsId);
    if (doc.exists) {
      return {
        'id': doc.id,
        ...FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>)
      };
    }
    return null;
  }

  // Media
  Future<String> createMedia(Map<String, dynamic> mediaData) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    mediaData['userId'] = currentUserId;
    mediaData['createdAt'] = DateTime.now();
    mediaData['updatedAt'] = DateTime.now();
    
    final docRef = await addDocument(FirestoreDataSchema.mediaCollection, mediaData);
    return docRef.id;
  }

  Stream<List<Map<String, dynamic>>> getUserMedia({String? type}) {
    if (currentUserId == null) return Stream.value([]);
    
    Query query = _firestore
        .collection(FirestoreDataSchema.mediaCollection)
        .where('userId', isEqualTo: currentUserId);
    
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    
    return query
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>)
                })
            .toList());
  }

  Future<void> updateMedia(String mediaId, Map<String, dynamic> data) async {
    await updateDocument(FirestoreDataSchema.mediaCollection, mediaId, data);
  }

  Future<void> deleteMedia(String mediaId) async {
    await deleteDocument(FirestoreDataSchema.mediaCollection, mediaId);
  }

  Future<Map<String, dynamic>?> getMedia(String mediaId) async {
    final doc = await getDocument(FirestoreDataSchema.mediaCollection, mediaId);
    if (doc.exists) {
      return {
        'id': doc.id,
        ...FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>)
      };
    }
    return null;
  }

  // Verse Collections
  Future<String> createVerseCollection(Map<String, dynamic> collectionData) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    collectionData['userId'] = currentUserId;
    collectionData['createdAt'] = DateTime.now();
    collectionData['updatedAt'] = DateTime.now();
    
    final docRef = await addDocument(FirestoreDataSchema.verseCollectionsCollection, collectionData);
    return docRef.id;
  }

  Stream<List<Map<String, dynamic>>> getUserVerseCollections() {
    return getUserCollection(FirestoreDataSchema.verseCollectionsCollection, orderBy: 'updatedAt')
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>)
                })
            .toList());
  }

  Future<void> updatePlaylist(String playlistId, Map<String, dynamic> data) async {
    await updateDocument(FirestoreDataSchema.playlistsCollection, playlistId, data);
  }

  Future<void> deletePlaylist(String playlistId) async {
    await deleteDocument(FirestoreDataSchema.playlistsCollection, playlistId);
  }

  Future<Map<String, dynamic>?> getPlaylist(String playlistId) async {
    final doc = await getDocument(FirestoreDataSchema.playlistsCollection, playlistId);
    if (doc.exists) {
      return {
        'id': doc.id,
        ...FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>)
      };
    }
    return null;
  }

  Future<void> updateVerseCollection(String collectionId, Map<String, dynamic> data) async {
    await updateDocument(FirestoreDataSchema.verseCollectionsCollection, collectionId, data);
  }

  Future<void> deleteVerseCollection(String collectionId) async {
    await deleteDocument(FirestoreDataSchema.verseCollectionsCollection, collectionId);
  }

  Future<Map<String, dynamic>?> getVerseCollection(String collectionId) async {
    final doc = await getDocument(FirestoreDataSchema.verseCollectionsCollection, collectionId);
    if (doc.exists) {
      return {
        'id': doc.id,
        ...FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>)
      };
    }
    return null;
  }

  // Settings
  Future<Map<String, dynamic>?> getUserSettings() async {
    if (currentUserId == null) return null;
    
    final doc = await getDocument(FirestoreDataSchema.settingsCollection, currentUserId!);
    
    if (doc.exists) {
      return FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    await updateDocument(FirestoreDataSchema.settingsCollection, currentUserId!, settings);
  }

  /// Utility methods
  
  Future<void> enableOfflinePersistence() async {
    try {
      await _firestore.enableNetwork();
    } catch (e) {
      debugPrint('Offline persistence error: $e');
    }
  }

  Future<void> disableOfflinePersistence() async {
    try {
      await _firestore.disableNetwork();
    } catch (e) {
      debugPrint('Disable network error: $e');
    }
  }

  Future<void> clearOfflineCache() async {
    try {
      await _firestore.clearPersistence();
    } catch (e) {
      debugPrint('Clear cache error: $e');
    }
  }

  /// Error handling helpers
  
  static String getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-disabled':
        return 'Esta conta foi desabilitada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'requires-recent-login':
        return 'Esta operação requer um login recente.';
      default:
        return 'Erro de autenticação: $code';
    }
  }

  static String getFirestoreErrorMessage(String message) {
    if (message.contains('permission-denied')) {
      return 'Acesso negado. Verifique suas permissões.';
    } else if (message.contains('unavailable')) {
      return 'Serviço temporariamente indisponível.';
    } else if (message.contains('deadline-exceeded')) {
      return 'Tempo limite excedido. Tente novamente.';
    }
    return 'Erro no banco de dados: $message';
  }
}