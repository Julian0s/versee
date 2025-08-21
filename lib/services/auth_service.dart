import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:versee/firestore/firestore_data_schema.dart';
import 'package:versee/services/local_auth_service.dart';
import 'package:versee/providers/riverpod_providers.dart';

// Instância global para bridge híbrida
AuthService? _globalAuthService;

/// Serviço de autenticação para o VERSEE
/// Gerencia login, registro, logout e estado do usuário
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthService _localAuth = LocalAuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFirebaseConnected = true;
  bool _useLocalAuth = false;

  // Getters
  User? get user => _user;
  Map<String, dynamic>? get localUser => _localAuth.currentUser;
  bool get isLoading => _isLoading || _localAuth.isLoading;
  String? get errorMessage => _errorMessage ?? _localAuth.errorMessage;
  bool get isAuthenticated => _user != null || _localAuth.isAuthenticated;
  bool get isFirebaseConnected => _isFirebaseConnected;
  bool get isUsingLocalAuth => _useLocalAuth;

  AuthService() {
    _localAuth.addListener(_onLocalAuthChanged);
    _globalAuthService = this;
    debugPrint('🔐 [AUTH] AuthService criado (inicialização manual necessária)');
  }

  /// Inicializar serviço de autenticação com Firebase
  Future<bool> initialize() async {
    debugPrint('🔐 [AUTH] Inicializando AuthService com Firebase...');
    
    try {
      // Verificar se Firebase está disponível
      final isConnected = await _checkFirebaseConnectivity();
      debugPrint('🔐 [AUTH] Firebase conectividade: $isConnected');
      
      if (!isConnected) {
        _switchToLocalAuth();
        return false;
      }

      // Configurar listener do Firebase Auth
      _setupFirebaseAuthListener();
      _isFirebaseConnected = true;
      
      debugPrint('🔐 [AUTH] Firebase AuthService inicializado com sucesso');
      return true;
    } catch (e) {
      debugPrint('🔐 [AUTH] ❌ Erro ao inicializar Firebase Auth: $e');
      _switchToLocalAuth();
      return false;
    }
  }
  
  /// Inicializar apenas em modo offline
  void initializeOfflineMode() {
    debugPrint('🔐 [AUTH] Inicializando AuthService em modo offline...');
    _isFirebaseConnected = false;
    _switchToLocalAuth();
  }
  
  /// Configurar listener do Firebase Auth de forma segura
  void _setupFirebaseAuthListener() {
    try {
      _auth.authStateChanges().listen((User? user) {
        debugPrint('🔐 [AUTH] Estado de autenticação mudou: ${user?.uid ?? "null"}');
        _user = user;
        _isFirebaseConnected = true;
        if (user != null) {
          _useLocalAuth = false;
          debugPrint('🔐 [AUTH] Usuário autenticado: ${user.email}');
        } else {
          debugPrint('🔐 [AUTH] Usuário deslogado');
        }
        notifyListeners();
      }, onError: (error) {
        debugPrint('🔐 [AUTH] ❌ Erro na autenticação Firebase: $error');
        _isFirebaseConnected = false;
        _switchToLocalAuth();
      });
    } catch (e) {
      debugPrint('🔐 [AUTH] ❌ Erro ao configurar Firebase Auth listener: $e');
      _switchToLocalAuth();
    }
  }

  /// Verificar conectividade do Firebase
  Future<bool> _checkFirebaseConnectivity() async {
    try {
      // Tentar uma operação simples para verificar conectividade
      final currentUser = _auth.currentUser;
      debugPrint('Firebase conectividade verificada - usuário atual: ${currentUser?.uid}');
      return true;
    } catch (e) {
      debugPrint('Falha na verificação de conectividade Firebase: $e');
      return false;
    }
  }

  void _onLocalAuthChanged() {
    notifyListeners();
  }

  void _switchToLocalAuth() {
    _isFirebaseConnected = false;
    _useLocalAuth = true;
    _setError('Firebase indisponível. Usando modo offline. Seus dados serão sincronizados quando a conexão for restaurada.');
    notifyListeners();
  }

  /// Fazer login com email e senha
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    debugPrint('🔐 [AUTH] Tentando login para: $email');
    
    // Se Firebase não está disponível, usar autenticação local
    if (!_isFirebaseConnected || _useLocalAuth) {
      debugPrint('🔐 [AUTH] Usando autenticação local');
      return await _localAuth.signInWithEmailAndPassword(email, password);
    }

    try {
      _setLoading(true);
      _clearError();
      debugPrint('🔐 [AUTH] Chamando Firebase Auth signIn...');

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint('🔐 [AUTH] Resultado do login: ${result.user?.uid}');
      if (result.user != null) {
        // Atualizar o estado local do usuário imediatamente
        _user = result.user;
        _useLocalAuth = false;
        debugPrint('🔐 [AUTH] ✅ Login bem-sucedido, notificando listeners...');
        notifyListeners();
        
        // Aguardar um pouco para garantir que o estado seja propagado
        await Future.delayed(const Duration(milliseconds: 100));
        
        await _updateUserLastLogin(result.user!.uid);
        debugPrint('🔐 [AUTH] ✅ Login completado com sucesso');
        return true;
      }
      debugPrint('🔐 [AUTH] ❌ Login falhou: result.user é null');
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('🔐 [AUTH] ❌ Erro Firebase Auth: ${e.code} - ${e.message}');
      debugPrint('🔐 [AUTH] Stack: ${e.stackTrace}');
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e, stackTrace) {
      debugPrint('🔐 [AUTH] ❌ Erro de login Firebase: $e');
      debugPrint('🔐 [AUTH] Stack trace: $stackTrace');
      // Fallback para autenticação local
      _switchToLocalAuth();
      return await _localAuth.signInWithEmailAndPassword(email, password);
    } finally {
      _setLoading(false);
    }
  }

  /// Registrar novo usuário
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    debugPrint('🔐 [AUTH] Tentando registro para: $email');
    
    // Se Firebase não está disponível, usar autenticação local
    if (!_isFirebaseConnected || _useLocalAuth) {
      debugPrint('🔐 [AUTH] Usando registro local');
      return await _localAuth.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
    }

    try {
      _setLoading(true);
      _clearError();
      debugPrint('🔐 [AUTH] Chamando Firebase Auth createUser...');

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint('🔐 [AUTH] Resultado do registro: ${result.user?.uid}');
      if (result.user != null) {
        try {
          // Atualizar o perfil do usuário
          debugPrint('🔐 [AUTH] Atualizando perfil do usuário...');
          await result.user!.updateDisplayName(displayName);

          // Criar documento do usuário no Firestore
          debugPrint('🔐 [AUTH] Criando documento do usuário no Firestore...');
          await _createUserDocument(
            userId: result.user!.uid,
            email: email.trim(),
            displayName: displayName,
          );

          // Atualizar o estado local do usuário imediatamente
          _user = result.user;
          _useLocalAuth = false;
          debugPrint('🔐 [AUTH] ✅ Registro bem-sucedido, notificando listeners...');
          notifyListeners();
          
          // Aguardar um pouco para garantir que o estado seja propagado
          await Future.delayed(const Duration(milliseconds: 100));
          
          debugPrint('🔐 [AUTH] ✅ Usuário registrado com sucesso: ${result.user!.uid}');
          return true;
        } catch (firestoreError) {
          debugPrint('🔐 [AUTH] ⚠️ Erro ao criar documento do usuário: $firestoreError');
          // Usuário foi criado no Auth, mas não no Firestore
          // Atualizar o estado local do usuário mesmo assim
          _user = result.user;
          _useLocalAuth = false;
          debugPrint('🔐 [AUTH] ✅ Registro parcialmente bem-sucedido, notificando listeners...');
          notifyListeners();
          
          // Aguardar um pouco para garantir que o estado seja propagado
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Ainda consideramos sucesso, mas logamos o erro
          return true;
        }
      }
      debugPrint('🔐 [AUTH] ❌ Falha no registro: result.user é null');
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('🔐 [AUTH] ❌ Erro Firebase Auth no registro: ${e.code} - ${e.message}');
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      debugPrint('🔐 [AUTH] ❌ Erro de registro Firebase: $e');
      // Fallback para autenticação local
      _switchToLocalAuth();
      return await _localAuth.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Fazer logout
  Future<void> signOut() async {
    try {
      _setLoading(true);
      if (_useLocalAuth) {
        await _localAuth.signOut();
      } else {
        await _auth.signOut();
      }
    } catch (e) {
      _setError('Erro ao fazer logout: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Resetar senha
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Erro inesperado: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Atualizar perfil do usuário
  Future<bool> updateUserProfile({
    String? displayName,
    String? language,
    String? theme,
  }) async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _clearError();

      // Atualizar no Firebase Auth se necessário
      if (displayName != null) {
        await _user!.updateDisplayName(displayName);
      }

      // Atualizar no Firestore
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now(),
      };

      if (displayName != null) updates['displayName'] = displayName;
      if (language != null) updates['language'] = language;
      if (theme != null) updates['theme'] = theme;

      await _firestore
          .collection(FirestoreDataSchema.usersCollection)
          .doc(_user!.uid)
          .update(FirestoreConverter.prepareForFirestore(updates));

      return true;
    } catch (e) {
      _setError('Erro ao atualizar perfil: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Obter dados do usuário do Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (_user == null) return null;

    try {
      final doc = await _firestore
          .collection(FirestoreDataSchema.usersCollection)
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        return FirestoreConverter.parseFromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao obter dados do usuário: $e');
      return null;
    }
  }

  /// Excluir conta do usuário
  Future<bool> deleteAccount() async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _clearError();

      // Excluir dados do Firestore
      await _deleteUserData(_user!.uid);

      // Excluir conta do Firebase Auth
      await _user!.delete();

      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Erro ao excluir conta: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos privados

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Criar documento do usuário no Firestore
  Future<void> _createUserDocument({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    debugPrint('🔐 [AUTH] Criando documento para usuário: $userId');
    
    try {
      final userData = FirestoreDataSchema.userDocument(
        email: email,
        displayName: displayName,
        plan: 'free',
        language: 'pt',
        theme: 'dark',
      );

      debugPrint('🔐 [AUTH] Salvando documento do usuário...');
      await _firestore
          .collection(FirestoreDataSchema.usersCollection)
          .doc(userId)
          .set(FirestoreConverter.prepareForFirestore(userData));
      debugPrint('🔐 [AUTH] ✅ Documento do usuário criado');

      // Criar documento de configurações padrão
      final settingsData = FirestoreDataSchema.settingsDocument(
        userId: userId,
        bibleVersions: {
          'nvi': true,
          'arc': false,
          'ntlh': false,
        },
        secondScreenSettings: {
          'backgroundColor': '#000000',
          'textColor': '#FFFFFF',
          'fontSize': 'large',
          'alignment': 'center',
        },
        generalSettings: {
          'autoSave': true,
          'syncEnabled': true,
          'notifications': true,
        },
      );

      debugPrint('🔐 [AUTH] Salvando configurações do usuário...');
      await _firestore
          .collection(FirestoreDataSchema.settingsCollection)
          .doc(userId)
          .set(FirestoreConverter.prepareForFirestore(settingsData));
      debugPrint('🔐 [AUTH] ✅ Configurações do usuário criadas');
    } catch (e) {
      debugPrint('🔐 [AUTH] ❌ Erro ao criar documentos: $e');
      rethrow;
    }
  }

  /// Atualizar último login
  Future<void> _updateUserLastLogin(String userId) async {
    if (!_isFirebaseConnected) return;
    
    try {
      await _firestore
          .collection(FirestoreDataSchema.usersCollection)
          .doc(userId)
          .update({
        'lastLogin': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Erro ao atualizar último login: $e');
      // Não falhar o login por causa disso
    }
  }

  /// Excluir todos os dados do usuário
  Future<void> _deleteUserData(String userId) async {
    final batch = _firestore.batch();

    // Excluir documento do usuário
    batch.delete(_firestore.collection(FirestoreDataSchema.usersCollection).doc(userId));

    // Excluir configurações
    batch.delete(_firestore.collection(FirestoreDataSchema.settingsCollection).doc(userId));

    // Excluir playlists
    final playlistsQuery = await _firestore
        .collection(FirestoreDataSchema.playlistsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in playlistsQuery.docs) {
      batch.delete(doc.reference);
    }

    // Excluir notas
    final notesQuery = await _firestore
        .collection(FirestoreDataSchema.notesCollection)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in notesQuery.docs) {
      batch.delete(doc.reference);
    }

    // Excluir mídia
    final mediaQuery = await _firestore
        .collection(FirestoreDataSchema.mediaCollection)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in mediaQuery.docs) {
      batch.delete(doc.reference);
    }

    // Excluir coleções de versículos
    final verseCollectionsQuery = await _firestore
        .collection(FirestoreDataSchema.verseCollectionsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in verseCollectionsQuery.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Get current user (static method for compatibility)
  static Future<User?> getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }

  /// Converter códigos de erro do Firebase para mensagens em português
  String _getAuthErrorMessage(String code) {
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
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      case 'unknown':
        return 'Erro de conexão com Firebase. Verifique sua internet ou tente mais tarde.';
      default:
        return 'Erro de autenticação: $code';
    }
  }

  // ============= BRIDGE HÍBRIDA PARA RIVERPOD =============
  
  /// Getter estático para acesso global à instância
  static AuthService? get globalInstance => _globalAuthService;
  
  /// Método de sincronização com Riverpod
  void syncWithRiverpod(AuthState state) {
    bool hasChanged = false;
    
    if (_user?.uid != state.user?.uid ||
        _isLoading != state.isLoading ||
        _errorMessage != state.errorMessage ||
        _isFirebaseConnected != state.isFirebaseConnected ||
        _useLocalAuth != state.isUsingLocalAuth) {
      
      _user = state.user;
      _isLoading = state.isLoading;
      _errorMessage = state.errorMessage;
      _isFirebaseConnected = state.isFirebaseConnected;
      _useLocalAuth = state.isUsingLocalAuth;
      
      hasChanged = true;
    }
    
    if (hasChanged) {
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _localAuth.removeListener(_onLocalAuthChanged);
    if (_globalAuthService == this) {
      _globalAuthService = null;
    }
    super.dispose();
  }
}