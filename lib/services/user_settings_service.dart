import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versee/services/auth_service.dart';

/// Serviço para gerenciar configurações do usuário
class UserSettingsService extends ChangeNotifier {
  static final UserSettingsService _instance = UserSettingsService._internal();
  factory UserSettingsService() => _instance;
  UserSettingsService._internal();

  AuthService? _authService;
  
  // Chaves para SharedPreferences
  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme';
  static const String _bibleVersionKey = 'selected_bible_version';

  // Estado atual
  String _currentLanguage = 'pt';
  ThemeMode _currentTheme = ThemeMode.system;
  String _selectedBibleVersion = 'KJV';

  // Getters
  String get currentLanguage => _currentLanguage;
  ThemeMode get currentTheme => _currentTheme;
  String get selectedBibleVersion => _selectedBibleVersion;

  /// Inicializa o AuthService (deve ser chamado após o Provider estar disponível)
  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  /// Carrega todas as configurações (local + Firebase)
  Future<void> loadSettings() async {
    debugPrint('🔄 [UserSettingsService] Iniciando loadSettings...');
    
    // Primeiro carrega configurações locais
    await _loadLanguage();
    await _loadTheme();
    await _loadBibleVersion();
    
    debugPrint('🔄 [UserSettingsService] Configurações locais carregadas');
    debugPrint('🔍 [UserSettingsService] Verificando autenticação para carregar do Firebase...');
    
    // Depois sincroniza com Firebase se autenticado
    if (_authService != null && _authService!.isAuthenticated) {
      debugPrint('✅ [UserSettingsService] Usuário autenticado, carregando do Firebase...');
      await _loadFromFirebase();
    } else {
      debugPrint('⚠️ [UserSettingsService] Usuário não autenticado no loadSettings');
    }
  }

  /// Carrega idioma das preferências
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null) {
        _currentLanguage = savedLanguage;
        debugPrint('✅ Idioma carregado: $_currentLanguage');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar idioma: $e');
    }
  }

  /// Carrega tema das preferências
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _currentTheme = ThemeMode.light;
            break;
          case 'dark':
            _currentTheme = ThemeMode.dark;
            break;
          case 'system':
          default:
            _currentTheme = ThemeMode.system;
            break;
        }
        debugPrint('✅ Tema carregado: $_currentTheme');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar tema: $e');
    }
  }

  /// Carrega versão da Bíblia das preferências
  Future<void> _loadBibleVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVersion = prefs.getString(_bibleVersionKey);
      if (savedVersion != null) {
        _selectedBibleVersion = savedVersion;
        debugPrint('✅ Versão da Bíblia carregada: $_selectedBibleVersion');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar versão da Bíblia: $e');
    }
  }

  /// Salva idioma
  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      await _saveLanguage();
      await _syncWithFirebase();
      notifyListeners();
      debugPrint('✅ Idioma alterado para: $_currentLanguage');
    }
  }

  /// Salva tema
  Future<void> setTheme(ThemeMode theme) async {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      await _saveTheme();
      await _syncWithFirebase();
      notifyListeners();
      debugPrint('✅ Tema alterado para: $_currentTheme');
    }
  }

  /// Salva versão da Bíblia
  Future<void> setBibleVersion(String version) async {
    if (_selectedBibleVersion != version) {
      _selectedBibleVersion = version;
      await _saveBibleVersion();
      await _syncWithFirebase();
      notifyListeners();
      debugPrint('✅ Versão da Bíblia alterada para: $_selectedBibleVersion');
    }
  }

  /// Salva idioma nas preferências locais
  Future<void> _saveLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _currentLanguage);
    } catch (e) {
      debugPrint('❌ Erro ao salvar idioma: $e');
    }
  }

  /// Salva tema nas preferências locais
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      switch (_currentTheme) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
        default:
          themeString = 'system';
          break;
      }
      await prefs.setString(_themeKey, themeString);
    } catch (e) {
      debugPrint('❌ Erro ao salvar tema: $e');
    }
  }

  /// Salva versão da Bíblia nas preferências locais
  Future<void> _saveBibleVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_bibleVersionKey, _selectedBibleVersion);
    } catch (e) {
      debugPrint('❌ Erro ao salvar versão da Bíblia: $e');
    }
  }

  /// Carrega configurações do Firebase usando AuthService
  Future<void> _loadFromFirebase() async {
    if (_authService == null || !_authService!.isAuthenticated) return;
    
    try {
      final userData = await _authService!.getUserData();
      
      if (userData != null) {
        debugPrint('🔄 [UserSettingsService] Dados do usuário carregados: $userData');
        
        // Atualiza configurações se existirem no Firebase
        if (userData['language'] != null && userData['language'] != _currentLanguage) {
          _currentLanguage = userData['language'];
          await _saveLanguage();
          debugPrint('🔄 Idioma sincronizado do Firebase: $_currentLanguage');
        }
        
        if (userData['theme'] != null) {
          final themeFromFirebase = _parseThemeMode(userData['theme']);
          if (themeFromFirebase != _currentTheme) {
            _currentTheme = themeFromFirebase;
            await _saveTheme();
            debugPrint('🔄 Tema sincronizado do Firebase: $_currentTheme');
          }
        }
        
        notifyListeners();
        debugPrint('✅ Configurações carregadas do Firebase via AuthService');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar configurações do Firebase: $e');
    }
  }

  /// Converte string para ThemeMode
  ThemeMode _parseThemeMode(String themeString) {
    switch (themeString.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Converte ThemeMode para string
  String _themeToString(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  /// Sincroniza configurações com Firebase usando AuthService
  Future<void> _syncWithFirebase() async {
    debugPrint('🔄 [UserSettingsService] Iniciando sincronização...');
    
    if (_authService == null) {
      debugPrint('⚠️ [UserSettingsService] AuthService não inicializado');
      return;
    }
    
    if (!_authService!.isAuthenticated) {
      debugPrint('⚠️ [UserSettingsService] Usuário não autenticado');
      return;
    }

    try {
      debugPrint('🔄 [UserSettingsService] Tentando sincronizar configurações com Firebase...');
      debugPrint('🔄 [UserSettingsService] Language: $_currentLanguage');
      debugPrint('🔄 [UserSettingsService] Theme: ${_themeToString(_currentTheme)}');
      
      final success = await _authService!.updateUserProfile(
        language: _currentLanguage,
        theme: _themeToString(_currentTheme),
      );
      
      if (success) {
        debugPrint('✅ [UserSettingsService] Configurações sincronizadas com Firebase via AuthService');
      } else {
        debugPrint('❌ [UserSettingsService] Falha ao sincronizar configurações com Firebase');
      }
    } catch (e) {
      debugPrint('❌ [UserSettingsService] Erro ao sincronizar com Firebase: $e');
      debugPrint('❌ [UserSettingsService] Stack trace: ${StackTrace.current}');
    }
  }

  /// Retorna locale baseado no idioma atual
  Locale get currentLocale {
    switch (_currentLanguage) {
      case 'en':
        return const Locale('en', 'US');
      case 'es':
        return const Locale('es', 'ES');
      case 'ja':
        return const Locale('ja', 'JP');
      case 'pt':
      default:
        return const Locale('pt', 'BR');
    }
  }

  /// Lista de idiomas suportados
  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'),
    Locale('en', 'US'),
    Locale('es', 'ES'),
    Locale('ja', 'JP'),
  ];

  /// Mapa de nomes dos idiomas
  static const Map<String, String> languageNames = {
    'pt': 'Português',
    'en': 'English',
    'es': 'Español',
    'ja': '日本語',
  };

  /// Lista de versões da Bíblia disponíveis
  static const List<String> availableBibleVersions = [
    'KJV',
    'ASV',
    'BSB',
  ];

  /// Mapa de nomes das versões da Bíblia
  static const Map<String, String> bibleVersionNames = {
    'KJV': 'King James Version',
    'ASV': 'American Standard Version',
    'BSB': 'Berean Standard Bible',
  };

  /// Lista de opções de tema
  static const List<ThemeMode> availableThemes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];
}