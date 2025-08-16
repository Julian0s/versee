import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// Serviço de autenticação local como fallback para quando Firebase não está disponível
class LocalAuthService extends ChangeNotifier {
  static const String _usersKey = 'local_users';
  static const String _currentUserKey = 'current_user';
  
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  LocalAuthService() {
    _loadCurrentUser();
  }

  /// Carregar usuário atual do armazenamento local
  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      if (userJson != null) {
        _currentUser = json.decode(userJson);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar usuário local: $e');
    }
  }

  /// Fazer login com email e senha (modo local)
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson == null) {
        _setError('Nenhum usuário encontrado. Registre-se primeiro.');
        return false;
      }

      final users = Map<String, dynamic>.from(json.decode(usersJson));
      final hashedPassword = _hashPassword(password);
      
      final userEmail = email.toLowerCase().trim();
      if (users.containsKey(userEmail)) {
        final userData = users[userEmail];
        if (userData['password'] == hashedPassword) {
          _currentUser = {
            'uid': userData['uid'],
            'email': userEmail,
            'displayName': userData['displayName'],
            'plan': userData['plan'] ?? 'free',
            'language': userData['language'] ?? 'pt',
            'theme': userData['theme'] ?? 'dark',
            'lastLogin': DateTime.now().toIso8601String(),
          };
          
          await prefs.setString(_currentUserKey, json.encode(_currentUser));
          notifyListeners();
          return true;
        } else {
          _setError('Senha incorreta.');
          return false;
        }
      } else {
        _setError('Usuário não encontrado.');
        return false;
      }
    } catch (e) {
      _setError('Erro ao fazer login: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registrar novo usuário (modo local)
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '{}';
      final users = Map<String, dynamic>.from(json.decode(usersJson));
      
      final userEmail = email.toLowerCase().trim();
      
      if (users.containsKey(userEmail)) {
        _setError('Este email já está sendo usado.');
        return false;
      }

      final uid = _generateUserId();
      final hashedPassword = _hashPassword(password);
      
      users[userEmail] = {
        'uid': uid,
        'email': userEmail,
        'displayName': displayName,
        'password': hashedPassword,
        'plan': 'free',
        'language': 'pt',
        'theme': 'dark',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_usersKey, json.encode(users));
      
      _currentUser = {
        'uid': uid,
        'email': userEmail,
        'displayName': displayName,
        'plan': 'free',
        'language': 'pt',
        'theme': 'dark',
        'lastLogin': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(_currentUserKey, json.encode(_currentUser));
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao registrar: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Fazer logout
  Future<void> signOut() async {
    try {
      _setLoading(true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Erro ao fazer logout: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Atualizar perfil do usuário
  Future<bool> updateUserProfile({
    String? displayName,
    String? language,
    String? theme,
    String? plan,
  }) async {
    if (_currentUser == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '{}';
      final users = Map<String, dynamic>.from(json.decode(usersJson));
      
      final userEmail = _currentUser!['email'];
      if (users.containsKey(userEmail)) {
        final userData = Map<String, dynamic>.from(users[userEmail]);
        
        if (displayName != null) {
          userData['displayName'] = displayName;
          _currentUser!['displayName'] = displayName;
        }
        if (language != null) {
          userData['language'] = language;
          _currentUser!['language'] = language;
        }
        if (theme != null) {
          userData['theme'] = theme;
          _currentUser!['theme'] = theme;
        }
        if (plan != null) {
          userData['plan'] = plan;
          _currentUser!['plan'] = plan;
        }
        
        userData['updatedAt'] = DateTime.now().toIso8601String();
        users[userEmail] = userData;
        
        await prefs.setString(_usersKey, json.encode(users));
        await prefs.setString(_currentUserKey, json.encode(_currentUser));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Erro ao atualizar perfil: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Resetar senha (simulado - na prática enviaria email)
  Future<bool> resetPassword(String email) async {
    _setError('Funcionalidade de reset de senha estará disponível quando Firebase estiver funcionando.');
    return false;
  }

  /// Excluir conta
  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '{}';
      final users = Map<String, dynamic>.from(json.decode(usersJson));
      
      final userEmail = _currentUser!['email'];
      users.remove(userEmail);
      
      await prefs.setString(_usersKey, json.encode(users));
      await prefs.remove(_currentUserKey);
      
      _currentUser = null;
      notifyListeners();
      return true;
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

  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'versee_salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateUserId() {
    return 'local_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000)).round()}';
  }
}