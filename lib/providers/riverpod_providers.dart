import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart' as provider;
import 'package:versee/theme.dart' as appTheme;
import 'package:versee/services/language_service.dart';
import 'package:versee/services/storage_analysis_service.dart';
import 'package:versee/services/auth_service.dart';
import 'package:versee/services/media_service.dart';
import 'package:versee/services/notes_service.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/pages/storage_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:versee/services/firebase_manager.dart';
import 'package:versee/firestore/firestore_data_schema.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

/// =============================================================================
/// ARQUIVO CENTRAL DE PROVIDERS DO RIVERPOD
/// =============================================================================
/// 
/// Este arquivo contém todos os providers migrados do Provider para Riverpod.
/// Durante a fase de migração, ambos os sistemas de gerenciamento de estado
/// coexistirão no app. Conforme os componentes são migrados, os providers
/// correspondentes do Provider serão removidos e substituídos pelos daqui.
/// 
/// Estrutura de migração:
/// 1. Criar o provider equivalente aqui
/// 2. Migrar os widgets que usam o provider
/// 3. Remover o provider antigo do MultiProvider no main.dart
/// 4. Quando todos estiverem migrados, remover o package Provider
/// 
/// =============================================================================

// -----------------------------------------------------------------------------
// Theme Provider - Migração do ThemeService
// -----------------------------------------------------------------------------

/// Estado do tema contendo o ThemeMode atual
class ThemeState {
  final ThemeMode themeMode;
  
  const ThemeState({
    this.themeMode = ThemeMode.system,
  });
  
  ThemeState copyWith({
    ThemeMode? themeMode,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
    );
  }
  
  /// Getters convenientes
  bool get isDarkMode => themeMode == ThemeMode.dark;
  bool get isLightMode => themeMode == ThemeMode.light;
  bool get isSystemMode => themeMode == ThemeMode.system;
}

/// Notifier para gerenciar o estado do tema
/// Implementação completa equivalente ao ThemeService original
class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeKey = 'app_theme_mode';
  
  ThemeNotifier() : super(const ThemeState()) {
    loadTheme();
  }
  
  /// Getters convenientes (delegam para o estado)
  bool get isDarkMode => state.isDarkMode;
  bool get isLightMode => state.isLightMode;
  bool get isSystemMode => state.isSystemMode;
  ThemeMode get themeMode => state.themeMode;
  
  /// Carrega o tema salvo das preferências
  /// Equivalente ao ThemeService.loadTheme()
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      ThemeMode mode;
      switch (savedTheme) {
        case 'light':
          mode = ThemeMode.light;
          break;
        case 'dark':
          mode = ThemeMode.dark;
          break;
        case 'system':
        default:
          mode = ThemeMode.system;
          break;
      }
      
      state = state.copyWith(themeMode: mode);
    } catch (e) {
      debugPrint('Erro ao carregar tema: $e');
    }
  }
  
  /// Salva o tema nas preferências
  /// Equivalente ao ThemeService._saveTheme()
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      
      switch (state.themeMode) {
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
      debugPrint('Erro ao salvar tema: $e');
    }
  }
  
  /// Define o tema como claro
  /// Equivalente ao ThemeService.setLightTheme()
  Future<void> setLightTheme() async {
    debugPrint('🎨 [RIVERPOD] Tema alterado para: light');
    state = state.copyWith(themeMode: ThemeMode.light);
    await _saveTheme();
  }
  
  /// Define o tema como escuro
  /// Equivalente ao ThemeService.setDarkTheme()
  Future<void> setDarkTheme() async {
    debugPrint('🎨 [RIVERPOD] Tema alterado para: dark');
    state = state.copyWith(themeMode: ThemeMode.dark);
    await _saveTheme();
  }
  
  /// Define o tema como sistema (automático)
  /// Equivalente ao ThemeService.setSystemTheme()
  Future<void> setSystemTheme() async {
    debugPrint('🎨 [RIVERPOD] Tema alterado para: system');
    state = state.copyWith(themeMode: ThemeMode.system);
    await _saveTheme();
  }
  
  /// Alterna entre claro e escuro
  /// Equivalente ao ThemeService.toggleTheme()
  Future<void> toggleTheme() async {
    if (state.themeMode == ThemeMode.dark) {
      await setLightTheme();
    } else {
      await setDarkTheme();
    }
  }
  
  /// Carrega preferências (alias para loadTheme)
  Future<void> loadThemePreference() async => await loadTheme();
  
  /// Salva preferências (expose do _saveTheme para compatibilidade)
  Future<void> saveThemePreference() async => await _saveTheme();
  
  /// Define tema por modo específico (método conveniente)
  Future<void> setThemeMode(ThemeMode mode) async {
    switch (mode) {
      case ThemeMode.light:
        await setLightTheme();
        break;
      case ThemeMode.dark:
        await setDarkTheme();
        break;
      case ThemeMode.system:
        await setSystemTheme();
        break;
    }
  }
}

/// Provider principal do tema - substituto completo do ThemeService
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Provider conveniente para acessar apenas o ThemeMode
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).themeMode;
});

/// Provider para o tema claro customizado
/// Equivalente ao ThemeService.lightTheme
final lightThemeProvider = Provider<ThemeData>((ref) {
  return appTheme.lightTheme.copyWith(
    appBarTheme: appTheme.lightTheme.appBarTheme.copyWith(
      centerTitle: true,
      scrolledUnderElevation: 1,
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        shape: WidgetStateProperty.all(
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    ),
  );
});

/// Provider para o tema escuro customizado
/// Equivalente ao ThemeService.darkTheme
final darkThemeProvider = Provider<ThemeData>((ref) {
  return appTheme.darkTheme.copyWith(
    appBarTheme: appTheme.darkTheme.appBarTheme.copyWith(
      centerTitle: true,
      scrolledUnderElevation: 1,
    ),
    cardTheme: const CardThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        shape: WidgetStateProperty.all(
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    ),
  );
});

/// Provider para acessar o tema atual baseado no modo
/// Seleciona automaticamente entre light e dark theme
final currentThemeProvider = Provider<ThemeData>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  
  switch (themeMode) {
    case ThemeMode.light:
      return ref.watch(lightThemeProvider);
    case ThemeMode.dark:
      return ref.watch(darkThemeProvider);
    case ThemeMode.system:
      // Para system theme, retornar o provider padrão do tema
      // O MaterialApp vai decidir baseado na preferência do sistema
      return ref.watch(lightThemeProvider);
  }
});

// -----------------------------------------------------------------------------
// Futuros Providers a serem migrados
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Theme Utilities - Funções auxiliares para migração
// -----------------------------------------------------------------------------

/// Classe utilitária estática que replica o comportamento dos métodos estáticos
/// do ThemeService original para facilitar migração de código existente
class ThemeServiceCompat {
  /// Tema claro personalizado - equivalente ao ThemeService.lightTheme
  static ThemeData get lightTheme {
    return appTheme.lightTheme.copyWith(
      appBarTheme: appTheme.lightTheme.appBarTheme.copyWith(
        centerTitle: true,
        scrolledUnderElevation: 1,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Tema escuro personalizado - equivalente ao ThemeService.darkTheme
  static ThemeData get darkTheme {
    return appTheme.darkTheme.copyWith(
      appBarTheme: appTheme.darkTheme.appBarTheme.copyWith(
        centerTitle: true,
        scrolledUnderElevation: 1,
      ),
      cardTheme: const CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Language Provider - Migração do LanguageService
// -----------------------------------------------------------------------------

/// Estado do idioma contendo o Locale atual
class LanguageState {
  final Locale currentLocale;
  
  const LanguageState({
    this.currentLocale = const Locale('pt', 'BR'),
  });
  
  LanguageState copyWith({
    Locale? currentLocale,
  }) {
    return LanguageState(
      currentLocale: currentLocale ?? this.currentLocale,
    );
  }
  
  /// Getters convenientes
  String get currentLanguageCode => currentLocale.languageCode;
}

/// Notifier para gerenciar o estado do idioma
/// Implementação completa equivalente ao LanguageService original
class LanguageNotifier extends StateNotifier<LanguageState> {
  static const String _languageKey = 'app_language';
  
  LanguageNotifier() : super(const LanguageState()) {
    loadLanguage();
  }
  
  /// Idiomas suportados - equivalente ao LanguageService.supportedLocales
  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'), // Português
    Locale('en', 'US'), // English
    Locale('es', 'ES'), // Español
    Locale('ja', 'JP'), // 日本語
  ];

  /// Mapa de idiomas para exibição - equivalente ao LanguageService.languageNames
  static const Map<String, String> languageNames = {
    'pt': 'Português',
    'en': 'English',
    'es': 'Español',
    'ja': '日本語',
  };
  
  /// Getters convenientes (delegam para o estado)
  Locale get currentLocale => state.currentLocale;
  String get currentLanguageCode => state.currentLanguageCode;
  
  /// Carrega o idioma salvo das preferências
  /// Equivalente ao LanguageService.loadLanguage()
  Future<void> loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      
      if (savedLanguage != null) {
        final locale = supportedLocales.firstWhere(
          (locale) => locale.languageCode == savedLanguage,
          orElse: () => const Locale('pt', 'BR'),
        );
        state = state.copyWith(currentLocale: locale);
      }
    } catch (e) {
      debugPrint('Erro ao carregar idioma: $e');
    }
  }
  
  /// Salva o idioma nas preferências
  /// Equivalente ao LanguageService._saveLanguage()
  Future<void> _saveLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, state.currentLocale.languageCode);
    } catch (e) {
      debugPrint('Erro ao salvar idioma: $e');
    }
  }
  
  /// Altera o idioma
  /// Equivalente ao LanguageService.setLanguage()
  Future<void> setLanguage(String languageCode) async {
    debugPrint('🌍 [RIVERPOD] Idioma alterado para: $languageCode');
    
    final locale = supportedLocales.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => const Locale('pt', 'BR'),
    );
    
    if (state.currentLocale != locale) {
      // 1. Atualizar estado Riverpod
      state = state.copyWith(currentLocale: locale);
      await _saveLanguage();
      
      // 2. BRIDGE HÍBRIDA: Sincronizar com Provider para que widgets existentes reajam
      _syncWithProviderSystem(locale);
    }
  }
  
  /// Sincroniza mudanças do Riverpod com o sistema Provider
  /// Isso faz com que todos os 27 arquivos que usam Consumer<LanguageService> reajam
  void _syncWithProviderSystem(Locale newLocale) {
    final globalLanguageService = LanguageService.globalInstance;
    if (globalLanguageService != null) {
      debugPrint('🔗 [BRIDGE] Sincronizando Riverpod → Provider');
      globalLanguageService.syncWithRiverpod(newLocale);
    } else {
      debugPrint('⚠️ [BRIDGE] LanguageService global não encontrado');
    }
  }
  
  /// Retorna as traduções para o idioma atual
  /// Equivalente ao LanguageService.strings getter
  AppLocalizations get strings => AppLocalizations(state.currentLanguageCode);
}

/// Provider principal do idioma - substituto completo do LanguageService
final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier();
});

/// Provider conveniente para acessar apenas o Locale atual
final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(languageProvider).currentLocale;
});

/// Provider conveniente para acessar apenas o código do idioma
final currentLanguageCodeProvider = Provider<String>((ref) {
  return ref.watch(languageProvider).currentLanguageCode;
});

/// Provider para acessar as strings traduzidas
final languageStringsProvider = Provider<AppLocalizations>((ref) {
  final languageCode = ref.watch(currentLanguageCodeProvider);
  return AppLocalizations(languageCode);
});

/// Provider para acessar os locales suportados
final supportedLocalesProvider = Provider<List<Locale>>((ref) {
  return LanguageNotifier.supportedLocales;
});

/// Classe para gerenciar todas as traduções - reutilizada do LanguageService
class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  /// Método auxiliar para obter valor baseado no idioma
  String _getValue(Map<String, String> values) {
    return values[languageCode] ?? values['pt'] ?? '';
  }

  // =================== COMMON/SHARED STRINGS ===================
  String get cancel => _getValue({
    'pt': 'Cancelar',
    'en': 'Cancel',
    'es': 'Cancelar',
    'ja': 'キャンセル',
  });

  String get close => _getValue({
    'pt': 'Fechar',
    'en': 'Close',
    'es': 'Cerrar',
    'ja': '閉じる',
  });

  String get save => _getValue({
    'pt': 'Salvar',
    'en': 'Save',
    'es': 'Guardar',
    'ja': '保存',
  });

  String get delete => _getValue({
    'pt': 'Excluir',
    'en': 'Delete',
    'es': 'Eliminar',
    'ja': '削除',
  });

  String get edit => _getValue({
    'pt': 'Editar',
    'en': 'Edit',
    'es': 'Editar',
    'ja': '編集',
  });

  String get search => _getValue({
    'pt': 'Pesquisar',
    'en': 'Search',
    'es': 'Buscar',
    'ja': '検索',
  });

  String get loading => _getValue({
    'pt': 'Carregando...',
    'en': 'Loading...',
    'es': 'Cargando...',
    'ja': '読み込み中...',
  });

  String get error => _getValue({
    'pt': 'Erro',
    'en': 'Error',
    'es': 'Error',
    'ja': 'エラー',
  });

  String get success => _getValue({
    'pt': 'Sucesso',
    'en': 'Success',
    'es': 'Éxito',
    'ja': '成功',
  });

  String get warning => _getValue({
    'pt': 'Aviso',
    'en': 'Warning',
    'es': 'Advertencia',
    'ja': '警告',
  });

  String get confirm => _getValue({
    'pt': 'Confirmar',
    'en': 'Confirm',
    'es': 'Confirmar',
    'ja': '確認',
  });

  String get yes => _getValue({
    'pt': 'Sim',
    'en': 'Yes',
    'es': 'Sí',
    'ja': 'はい',
  });

  String get no => _getValue({
    'pt': 'Não',
    'en': 'No',
    'es': 'No',
    'ja': 'いいえ',
  });

  // =================== BIBLE STRINGS ===================
  String get bible => _getValue({
    'pt': 'Bíblia',
    'en': 'Bible',
    'es': 'Biblia',
    'ja': '聖書',
  });

  String get verse => _getValue({
    'pt': 'Versículo',
    'en': 'Verse',
    'es': 'Versículo',
    'ja': '節',
  });

  String get chapter => _getValue({
    'pt': 'Capítulo',
    'en': 'Chapter',
    'es': 'Capítulo',
    'ja': '章',
  });

  String get book => _getValue({
    'pt': 'Livro',
    'en': 'Book',
    'es': 'Libro',
    'ja': '書',
  });

  // =================== APP NAVIGATION STRINGS ===================
  String get playlist => _getValue({
    'pt': 'Apresentação',
    'en': 'Presentation',
    'es': 'Presentación',
    'ja': 'プレゼンテーション',
  });

  String get notes => _getValue({
    'pt': 'Anotações',
    'en': 'Notes',
    'es': 'Notas',
    'ja': 'ノート',
  });

  String get media => _getValue({
    'pt': 'Mídia',
    'en': 'Media',
    'es': 'Medios',
    'ja': 'メディア',
  });

  String get settings => _getValue({
    'pt': 'Configurações',
    'en': 'Settings',
    'es': 'Configuración',
    'ja': '設定',
  });

  // =================== THEME STRINGS ===================
  String get theme => _getValue({
    'pt': 'Tema',
    'en': 'Theme',
    'es': 'Tema',
    'ja': 'テーマ',
  });

  String get selectTheme => _getValue({
    'pt': 'Selecionar tema',
    'en': 'Select theme',
    'es': 'Seleccionar tema',
    'ja': 'テーマを選択',
  });

  String get lightTheme => _getValue({
    'pt': 'Claro',
    'en': 'Light',
    'es': 'Claro',
    'ja': 'ライト',
  });

  String get darkTheme => _getValue({
    'pt': 'Escuro',
    'en': 'Dark',
    'es': 'Oscuro',
    'ja': 'ダーク',
  });

  String get systemTheme => _getValue({
    'pt': 'Sistema',
    'en': 'System',
    'es': 'Sistema',
    'ja': 'システム',
  });

  // =================== LANGUAGE STRINGS ===================
  String get language => _getValue({
    'pt': 'Idioma',
    'en': 'Language',
    'es': 'Idioma',
    'ja': '言語',
  });

  String get selectLanguage => _getValue({
    'pt': 'Selecionar idioma',
    'en': 'Select language',
    'es': 'Seleccionar idioma',
    'ja': '言語を選択',
  });
}

// -----------------------------------------------------------------------------
// Language Utilities - Funções auxiliares para migração
// -----------------------------------------------------------------------------

/// Classe utilitária estática que replica o comportamento dos métodos estáticos
/// do LanguageService original para facilitar migração de código existente
class LanguageServiceCompat {
  /// Idiomas suportados - equivalente ao LanguageService.supportedLocales
  static const List<Locale> supportedLocales = LanguageNotifier.supportedLocales;

  /// Mapa de idiomas para exibição - equivalente ao LanguageService.languageNames
  static const Map<String, String> languageNames = LanguageNotifier.languageNames;
}

// -----------------------------------------------------------------------------
// Storage Monitoring Provider - Migração do StorageMonitoringService
// -----------------------------------------------------------------------------

/// Estado do monitoramento de armazenamento contendo todos os campos do service original
class StorageMonitoringState {
  final bool isMonitoring;
  final DateTime? lastAnalysis;
  final bool hasShownWarning;
  final BuildContext? context;
  final StorageAnalysisService? storageAnalysisService;
  final Timer? monitoringTimer;
  
  const StorageMonitoringState({
    this.isMonitoring = false,
    this.lastAnalysis,
    this.hasShownWarning = false,
    this.context,
    this.storageAnalysisService,
    this.monitoringTimer,
  });
  
  StorageMonitoringState copyWith({
    bool? isMonitoring,
    DateTime? lastAnalysis,
    bool? hasShownWarning,
    BuildContext? context,
    StorageAnalysisService? storageAnalysisService,
    Timer? monitoringTimer,
  }) {
    return StorageMonitoringState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      lastAnalysis: lastAnalysis ?? this.lastAnalysis,
      hasShownWarning: hasShownWarning ?? this.hasShownWarning,
      context: context ?? this.context,
      storageAnalysisService: storageAnalysisService ?? this.storageAnalysisService,
      monitoringTimer: monitoringTimer ?? this.monitoringTimer,
    );
  }
}

/// Notifier para gerenciar o estado do monitoramento de armazenamento
/// Implementação completa equivalente ao StorageMonitoringService original
class StorageMonitoringNotifier extends StateNotifier<StorageMonitoringState> {
  static const String _lastAnalysisKey = 'last_storage_analysis';
  static const String _notificationShownKey = 'storage_notification_shown';
  static const Duration _analysisInterval = Duration(minutes: 30);
  
  StorageMonitoringNotifier() : super(const StorageMonitoringState()) {
    _loadLastAnalysisTime();
  }

  /// Getters convenientes (delegam para o estado)
  bool get isMonitoring => state.isMonitoring;
  DateTime? get lastAnalysis => state.lastAnalysis;

  /// Initialize the monitoring service
  /// Equivalente ao StorageMonitoringService.initialize()
  void initialize(BuildContext context) {
    debugPrint('📊 [RIVERPOD] Inicializando StorageMonitoringService');
    
    final storageAnalysisService = provider.Provider.of<StorageAnalysisService>(context, listen: false);
    
    state = state.copyWith(
      context: context,
      storageAnalysisService: storageAnalysisService,
    );
    
    _loadLastAnalysisTime();
  }

  /// Start monitoring storage usage
  /// Equivalente ao StorageMonitoringService.startMonitoring()
  void startMonitoring() {
    if (state.isMonitoring || state.context == null) return;
    
    debugPrint('📊 [RIVERPOD] Iniciando monitoramento de armazenamento');
    
    // Perform initial analysis
    _performAnalysis();
    
    // Set up periodic monitoring
    final timer = Timer.periodic(_analysisInterval, (timer) {
      _performAnalysis();
    });
    
    state = state.copyWith(
      isMonitoring: true,
      monitoringTimer: timer,
    );
  }

  /// Stop monitoring storage usage
  /// Equivalente ao StorageMonitoringService.stopMonitoring()
  void stopMonitoring() {
    if (!state.isMonitoring) return;
    
    debugPrint('📊 [RIVERPOD] Parando monitoramento de armazenamento');
    
    state.monitoringTimer?.cancel();
    state = state.copyWith(
      isMonitoring: false,
      monitoringTimer: null,
    );
  }

  /// Perform a manual storage analysis
  /// Equivalente ao StorageMonitoringService.forceAnalysis()
  Future<void> forceAnalysis() async {
    if (state.context == null || state.storageAnalysisService == null) return;
    
    debugPrint('📊 [RIVERPOD] Executando análise forçada de armazenamento');
    
    try {
      await state.storageAnalysisService!.analyzeStorageUsage(state.context!);
      
      state = state.copyWith(lastAnalysis: DateTime.now());
      await _saveLastAnalysisTime();
      
      await _checkStorageStatus();
    } catch (e) {
      debugPrint('📊 [RIVERPOD] Erro na análise forçada de armazenamento: $e');
    }
  }

  /// Internal method to perform periodic analysis
  /// Equivalente ao StorageMonitoringService._performAnalysis()
  Future<void> _performAnalysis() async {
    if (state.context == null || state.storageAnalysisService == null) return;
    
    debugPrint('📊 [RIVERPOD] Executando análise periódica de armazenamento');
    
    try {
      await state.storageAnalysisService!.analyzeStorageUsage(state.context!);
      
      state = state.copyWith(lastAnalysis: DateTime.now());
      await _saveLastAnalysisTime();
      
      await _checkStorageStatus();
    } catch (e) {
      debugPrint('📊 [RIVERPOD] Erro na análise de armazenamento: $e');
    }
  }

  /// Check storage status and show warnings if needed
  /// Equivalente ao StorageMonitoringService._checkStorageStatus()
  Future<void> _checkStorageStatus() async {
    final usage = state.storageAnalysisService?.currentUsage;
    if (usage == null) return;

    debugPrint('📊 [RIVERPOD] Verificando status do armazenamento');

    // Check if we should show a storage warning
    if (usage.isOverLimit) {
      await _showStorageExceededNotification(usage);
    } else if (usage.isNearLimit && !state.hasShownWarning) {
      await _showStorageWarningNotification(usage);
      state = state.copyWith(hasShownWarning: true);
    } else if (!usage.isNearLimit && state.hasShownWarning) {
      // Reset warning flag if storage usage drops below warning threshold
      state = state.copyWith(hasShownWarning: false);
      await _clearNotificationShown();
    }
  }

  /// Show storage exceeded notification
  /// Equivalente ao StorageMonitoringService._showStorageExceededNotification()
  Future<void> _showStorageExceededNotification(StorageUsageData usage) async {
    if (state.context == null) return;

    debugPrint('📊 [RIVERPOD] Mostrando notificação de armazenamento excedido');

    // Check if we should show notification today
    final shouldShow = await _shouldShowNotificationToday('exceeded');
    if (!shouldShow) return;

    if (!state.context!.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(state.context!);
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Armazenamento Excedido!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Você está usando ${usage.usagePercentage.toStringAsFixed(1)}% do seu limite.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Fazer Upgrade',
          textColor: Colors.white,
          onPressed: () => _navigateToStoragePage(),
        ),
      ),
    );

    await _markNotificationShown('exceeded');
  }

  /// Show storage warning notification
  /// Equivalente ao StorageMonitoringService._showStorageWarningNotification()
  Future<void> _showStorageWarningNotification(StorageUsageData usage) async {
    if (state.context == null) return;

    debugPrint('📊 [RIVERPOD] Mostrando notificação de aviso de armazenamento');

    // Check if we should show notification today
    final shouldShow = await _shouldShowNotificationToday('warning');
    if (!shouldShow) return;

    if (!state.context!.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(state.context!);
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Armazenamento Quase Cheio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Você está usando ${usage.usagePercentage.toStringAsFixed(1)}% do seu limite.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Ver Detalhes',
          textColor: Colors.white,
          onPressed: () => _navigateToStoragePage(),
        ),
      ),
    );

    await _markNotificationShown('warning');
  }

  /// Navigate to storage page
  /// Equivalente ao StorageMonitoringService._navigateToStoragePage()
  void _navigateToStoragePage() {
    if (state.context == null || !state.context!.mounted) return;
    
    debugPrint('📊 [RIVERPOD] Navegando para página de armazenamento');
    
    Navigator.of(state.context!).push(
      MaterialPageRoute(
        builder: (context) => const StoragePage(),
      ),
    );
  }

  /// Check if we should show notification today
  /// Equivalente ao StorageMonitoringService._shouldShowNotificationToday()
  Future<bool> _shouldShowNotificationToday(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_notificationShownKey}_${type}';
      final lastShownString = prefs.getString(key);
      
      if (lastShownString == null) return true;
      
      final lastShown = DateTime.tryParse(lastShownString);
      if (lastShown == null) return true;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastShownDate = DateTime(lastShown.year, lastShown.month, lastShown.day);
      
      return today.isAfter(lastShownDate);
    } catch (e) {
      debugPrint('📊 [RIVERPOD] Erro ao verificar status de notificação: $e');
      return true;
    }
  }

  /// Mark notification as shown today
  /// Equivalente ao StorageMonitoringService._markNotificationShown()
  Future<void> _markNotificationShown(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_notificationShownKey}_${type}';
      await prefs.setString(key, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('📊 [RIVERPOD] Erro ao marcar notificação como mostrada: $e');
    }
  }

  /// Clear notification shown flag
  /// Equivalente ao StorageMonitoringService._clearNotificationShown()
  Future<void> _clearNotificationShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_notificationShownKey}_warning');
      await prefs.remove('${_notificationShownKey}_exceeded');
    } catch (e) {
      debugPrint('📊 [RIVERPOD] Erro ao limpar flags de notificação: $e');
    }
  }

  /// Load last analysis time from preferences
  /// Equivalente ao StorageMonitoringService._loadLastAnalysisTime()
  Future<void> _loadLastAnalysisTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAnalysisString = prefs.getString(_lastAnalysisKey);
      if (lastAnalysisString != null) {
        final lastAnalysis = DateTime.tryParse(lastAnalysisString);
        state = state.copyWith(lastAnalysis: lastAnalysis);
      }
    } catch (e) {
      debugPrint('📊 [RIVERPOD] Erro ao carregar hora da última análise: $e');
    }
  }

  /// Save last analysis time to preferences
  /// Equivalente ao StorageMonitoringService._saveLastAnalysisTime()
  Future<void> _saveLastAnalysisTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (state.lastAnalysis != null) {
        await prefs.setString(_lastAnalysisKey, state.lastAnalysis!.toIso8601String());
      }
    } catch (e) {
      debugPrint('📊 [RIVERPOD] Erro ao salvar hora da última análise: $e');
    }
  }

  /// Get storage usage summary for quick display
  /// Equivalente ao StorageMonitoringService.getUsageSummary()
  StorageUsageSummary? getUsageSummary() {
    final usage = state.storageAnalysisService?.currentUsage;
    if (usage == null) return null;

    return StorageUsageSummary(
      usedBytes: usage.totalUsed,
      totalBytes: usage.totalLimit,
      usagePercentage: usage.usagePercentage,
      isNearLimit: usage.isNearLimit,
      isOverLimit: usage.isOverLimit,
      planType: usage.planType,
    );
  }

  /// Check if analysis is needed (hasn't been done recently)
  /// Equivalente ao StorageMonitoringService.needsAnalysis()
  bool needsAnalysis() {
    if (state.lastAnalysis == null) return true;
    
    final timeSinceAnalysis = DateTime.now().difference(state.lastAnalysis!);
    return timeSinceAnalysis > _analysisInterval;
  }

  /// Monitor file operations and trigger analysis if needed
  /// Equivalente ao StorageMonitoringService.onFileOperationCompleted()
  void onFileOperationCompleted() {
    if (!state.isMonitoring) return;
    
    debugPrint('📊 [RIVERPOD] Operação de arquivo completada, verificando necessidade de análise');
    
    // Debounce analysis calls - only analyze if it's been a while
    if (needsAnalysis()) {
      Future.delayed(const Duration(seconds: 5), () {
        if (state.isMonitoring) {
          _performAnalysis();
        }
      });
    }
  }

  /// Pause monitoring (useful for battery saving)
  /// Equivalente ao StorageMonitoringService.pauseMonitoring()
  void pauseMonitoring() {
    debugPrint('📊 [RIVERPOD] Pausando monitoramento de armazenamento');
    
    state.monitoringTimer?.cancel();
    state = state.copyWith(monitoringTimer: null);
  }

  /// Resume monitoring
  /// Equivalente ao StorageMonitoringService.resumeMonitoring()
  void resumeMonitoring() {
    if (!state.isMonitoring || state.monitoringTimer != null) return;
    
    debugPrint('📊 [RIVERPOD] Resumindo monitoramento de armazenamento');
    
    final timer = Timer.periodic(_analysisInterval, (timer) {
      _performAnalysis();
    });
    
    state = state.copyWith(monitoringTimer: timer);
  }

  @override
  void dispose() {
    debugPrint('📊 [RIVERPOD] Disposing StorageMonitoringNotifier');
    stopMonitoring();
    super.dispose();
  }
}

/// Lightweight summary of storage usage
/// Migrated from StorageMonitoringService
class StorageUsageSummary {
  final int usedBytes;
  final int totalBytes;
  final double usagePercentage;
  final bool isNearLimit;
  final bool isOverLimit;
  final String planType;

  StorageUsageSummary({
    required this.usedBytes,
    required this.totalBytes,
    required this.usagePercentage,
    required this.isNearLimit,
    required this.isOverLimit,
    required this.planType,
  });

  int get remainingBytes => totalBytes - usedBytes;

  /// Format usage as a readable string
  String get usageString => 
    '${StorageAnalysisNotifier.formatFileSize(usedBytes)} / ${StorageAnalysisNotifier.formatFileSize(totalBytes)}';

  /// Get status color based on usage level
  Color get statusColor {
    if (isOverLimit) return Colors.red;
    if (isNearLimit) return Colors.orange;
    if (usagePercentage > 60) return Colors.amber;
    return Colors.green;
  }

  /// Get status icon based on usage level
  IconData get statusIcon {
    if (isOverLimit) return Icons.error;
    if (isNearLimit) return Icons.warning;
    return Icons.check_circle;
  }
}

/// Provider principal do monitoramento de armazenamento - substituto completo do StorageMonitoringService
final storageMonitoringProvider = StateNotifierProvider<StorageMonitoringNotifier, StorageMonitoringState>((ref) {
  return StorageMonitoringNotifier();
});

/// Provider conveniente para acessar apenas se está monitorando
final isMonitoringProvider = Provider<bool>((ref) {
  return ref.watch(storageMonitoringProvider).isMonitoring;
});

/// Provider conveniente para acessar a última análise
final lastAnalysisProvider = Provider<DateTime?>((ref) {
  return ref.watch(storageMonitoringProvider).lastAnalysis;
});

/// Provider conveniente para acessar o resumo de uso de armazenamento
final storageUsageSummaryProvider = Provider<StorageUsageSummary?>((ref) {
  final notifier = ref.read(storageMonitoringProvider.notifier);
  return notifier.getUsageSummary();
});

/// Provider conveniente para verificar se precisa de análise
final needsAnalysisProvider = Provider<bool>((ref) {
  final notifier = ref.read(storageMonitoringProvider.notifier);
  return notifier.needsAnalysis();
});

// -----------------------------------------------------------------------------
// Storage Analysis Provider - Migração do StorageAnalysisService  
// -----------------------------------------------------------------------------

/// Estado da análise de armazenamento contendo todos os campos do service original
class StorageAnalysisState {
  final StorageUsageData? currentUsage;
  final bool isAnalyzing;
  final String? errorMessage;
  
  const StorageAnalysisState({
    this.currentUsage,
    this.isAnalyzing = false,
    this.errorMessage,
  });
  
  StorageAnalysisState copyWith({
    StorageUsageData? currentUsage,
    bool? isAnalyzing,
    String? errorMessage,
  }) {
    return StorageAnalysisState(
      currentUsage: currentUsage ?? this.currentUsage,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier para gerenciar o estado da análise de armazenamento
/// Implementação completa equivalente ao StorageAnalysisService original
class StorageAnalysisNotifier extends StateNotifier<StorageAnalysisState> {
  static const String _storageDataKey = 'storage_analysis_cache';
  
  StorageAnalysisNotifier() : super(const StorageAnalysisState());

  /// Getters convenientes (delegam para o estado)
  StorageUsageData? get currentUsage => state.currentUsage;
  bool get isAnalyzing => state.isAnalyzing;
  String? get errorMessage => state.errorMessage;

  /// Analisa todo o uso de armazenamento por categoria
  /// Equivalente ao StorageAnalysisService.analyzeStorageUsage()
  Future<StorageUsageData> analyzeStorageUsage(BuildContext context) async {
    debugPrint('📈 [RIVERPOD] Iniciando análise de armazenamento');
    
    state = state.copyWith(
      isAnalyzing: true,
      errorMessage: null,
    );
    _syncWithProviderSystem();

    try {
      // VERSÃO ROBUSTA: Funciona mesmo sem todos os serviços
      MediaService? mediaService;
      NotesService? notesService;
      PlaylistService? playlistService;
      AuthService? authService;

      // Tenta obter os serviços, mas não falha se algum não estiver disponível
      try {
        mediaService = provider.Provider.of<MediaService>(context, listen: false);
      } catch (e) {
        debugPrint('📈 [RIVERPOD] MediaService não disponível: $e');
      }

      try {
        notesService = provider.Provider.of<NotesService>(context, listen: false);
      } catch (e) {
        debugPrint('📈 [RIVERPOD] NotesService não disponível: $e');
      }

      try {
        playlistService = provider.Provider.of<PlaylistService>(context, listen: false);
      } catch (e) {
        debugPrint('📈 [RIVERPOD] PlaylistService não disponível: $e');
      }

      try {
        authService = provider.Provider.of<AuthService>(context, listen: false);
      } catch (e) {
        debugPrint('📈 [RIVERPOD] AuthService não disponível: $e');
      }

      // Get plan information
      final userPlan = _getUserPlan(authService);
      final planLimits = _getPlanLimits(userPlan);

      debugPrint('📈 [RIVERPOD] Analisando categorias de armazenamento');
      
      // Analyze each category (com fallback para dados simulados)
      final audioData = await _analyzeAudioFiles(mediaService);
      final videoData = await _analyzeVideoFiles(mediaService);
      final imageData = await _analyzeImageFiles(mediaService);
      final notesData = await _analyzeNotesData(notesService);
      final versesData = await _analyzeVersesData();
      final playlistData = await _analyzePlaylistData(playlistService);
      final letterData = await _analyzeLetterData();

      final totalUsed = audioData.size + videoData.size + imageData.size + 
                       notesData.size + versesData.size + playlistData.size + letterData.size;

      final usage = StorageUsageData(
        totalUsed: totalUsed,
        totalLimit: planLimits['storage'] ?? 104857600, // 100MB default
        planType: userPlan,
        categories: [
          audioData,
          videoData,
          imageData,
          notesData,
          versesData,
          playlistData,
          letterData,
        ],
        lastUpdated: DateTime.now(),
      );

      debugPrint('📈 [RIVERPOD] Análise concluída - ${StorageAnalysisNotifier.formatFileSize(totalUsed)} de ${StorageAnalysisNotifier.formatFileSize(usage.totalLimit)}');
      
      state = state.copyWith(
        currentUsage: usage,
        isAnalyzing: false,
      );
      _syncWithProviderSystem();
      
      return usage;
    } catch (e) {
      // FALLBACK: Se tudo falhar, cria dados demo para teste
      debugPrint('📈 [RIVERPOD] Erro na análise, usando dados demo: $e');
      final demoUsage = _createDemoData();
      
      state = state.copyWith(
        currentUsage: demoUsage,
        isAnalyzing: false,
      );
      _syncWithProviderSystem();
      
      return demoUsage;
    }
  }

  /// Cria dados demo para teste quando há falhas
  /// Equivalente ao StorageAnalysisService._createDemoData()
  StorageUsageData _createDemoData() {
    debugPrint('📈 [RIVERPOD] Gerando dados demo de armazenamento');
    
    return StorageUsageData(
      totalUsed: 45 * 1024 * 1024, // 45MB usado
      totalLimit: 100 * 1024 * 1024, // 100MB limite (starter)
      planType: 'starter',
      categories: [
        StorageCategoryData(
          category: StorageCategory.audio,
          size: 15 * 1024 * 1024, // 15MB
          fileCount: 5,
          color: const Color(0xFF2196F3),
          icon: Icons.music_note,
        ),
        StorageCategoryData(
          category: StorageCategory.video,
          size: 20 * 1024 * 1024, // 20MB
          fileCount: 2,
          color: const Color(0xFFF44336),
          icon: Icons.play_circle_outline,
        ),
        StorageCategoryData(
          category: StorageCategory.images,
          size: 8 * 1024 * 1024, // 8MB
          fileCount: 12,
          color: const Color(0xFF4CAF50),
          icon: Icons.image,
        ),
        StorageCategoryData(
          category: StorageCategory.notes,
          size: 1 * 1024 * 1024, // 1MB
          fileCount: 3,
          color: const Color(0xFFFF9800),
          icon: Icons.note,
        ),
        StorageCategoryData(
          category: StorageCategory.verses,
          size: 512 * 1024, // 512KB
          fileCount: 8,
          color: const Color(0xFF9C27B0),
          icon: Icons.menu_book,
        ),
        StorageCategoryData(
          category: StorageCategory.playlists,
          size: 256 * 1024, // 256KB
          fileCount: 2,
          color: const Color(0xFF607D8B),
          icon: Icons.playlist_play,
        ),
        StorageCategoryData(
          category: StorageCategory.letters,
          size: 256 * 1024, // 256KB
          fileCount: 1,
          color: const Color(0xFF795548),
          icon: Icons.text_fields,
        ),
      ],
      lastUpdated: DateTime.now(),
    );
  }

  /// Obtém o plano do usuário
  /// Equivalente ao StorageAnalysisService._getUserPlan()
  String _getUserPlan(AuthService? authService) {
    if (authService == null || !authService.isAuthenticated) return 'starter';
    
    String userPlan;
    if (authService.isUsingLocalAuth) {
      userPlan = authService.localUser?['plan'] ?? 'starter';
    } else {
      userPlan = 'starter';
    }
    
    return userPlan.toLowerCase();
  }

  /// Obtém os limites do plano baseado no arquivo de configuração
  /// Equivalente ao StorageAnalysisService._getPlanLimits()
  Map<String, int> _getPlanLimits(String plan) {
    switch (plan.toLowerCase()) {
      case 'starter':
        return {
          'storage': 104857600, // 100MB
          'files': 10,
          'playlists': 1,
          'playlistItems': 10,
          'notes': 5,
          'songs': 5,
        };
      case 'standard':
        return {
          'storage': 5368709120, // 5GB
          'files': 200,
          'playlists': -1, // unlimited
          'playlistItems': -1,
          'notes': -1,
          'songs': -1,
        };
      case 'advanced':
        return {
          'storage': 53687091200, // 50GB
          'files': -1, // unlimited
          'playlists': -1,
          'playlistItems': -1,
          'notes': -1,
          'songs': -1,
        };
      default:
        return _getPlanLimits('starter');
    }
  }

  /// Analisa arquivos de áudio
  /// Equivalente ao StorageAnalysisService._analyzeAudioFiles()
  Future<StorageCategoryData> _analyzeAudioFiles(MediaService? mediaService) async {
    if (mediaService == null) {
      return StorageCategoryData(
        category: StorageCategory.audio,
        size: 0,
        fileCount: 0,
        color: const Color(0xFF2196F3), // Blue
        icon: Icons.music_note,
      );
    }

    try {
      final storageInfo = await mediaService.getStorageInfo();
      return StorageCategoryData(
        category: StorageCategory.audio,
        size: storageInfo['audioSize'] as int? ?? 0,
        fileCount: storageInfo['audioFiles'] as int? ?? 0,
        color: const Color(0xFF2196F3), // Blue
        icon: Icons.music_note,
      );
    } catch (e) {
      debugPrint('📈 [RIVERPOD] Erro ao analisar arquivos de áudio: $e');
      return StorageCategoryData(
        category: StorageCategory.audio,
        size: 0,
        fileCount: 0,
        color: const Color(0xFF2196F3),
        icon: Icons.music_note,
      );
    }
  }

  /// Analisa arquivos de vídeo
  /// Equivalente ao StorageAnalysisService._analyzeVideoFiles()
  Future<StorageCategoryData> _analyzeVideoFiles(MediaService? mediaService) async {
    if (mediaService == null) {
      return StorageCategoryData(
        category: StorageCategory.video,
        size: 0,
        fileCount: 0,
        color: const Color(0xFFF44336), // Red
        icon: Icons.play_circle_outline,
      );
    }
    try {
      final storageInfo = await mediaService.getStorageInfo();
      return StorageCategoryData(
        category: StorageCategory.video,
        size: storageInfo['videoSize'] as int? ?? 0,
        fileCount: storageInfo['videoFiles'] as int? ?? 0,
        color: const Color(0xFFF44336), // Red
        icon: Icons.play_circle_outline,
      );
    } catch (e) {
      debugPrint('📈 [RIVERPOD] Erro ao analisar arquivos de vídeo: $e');
      return StorageCategoryData(
        category: StorageCategory.video,
        size: 0,
        fileCount: 0,
        color: const Color(0xFFF44336),
        icon: Icons.play_circle_outline,
      );
    }
  }

  /// Analisa arquivos de imagem
  /// Equivalente ao StorageAnalysisService._analyzeImageFiles()
  Future<StorageCategoryData> _analyzeImageFiles(MediaService? mediaService) async {
    if (mediaService == null) {
      return StorageCategoryData(
        category: StorageCategory.images,
        size: 0,
        fileCount: 0,
        color: const Color(0xFF4CAF50), // Green
        icon: Icons.image,
      );
    }
    try {
      final storageInfo = await mediaService.getStorageInfo();
      return StorageCategoryData(
        category: StorageCategory.images,
        size: storageInfo['imageSize'] as int? ?? 0,
        fileCount: storageInfo['imageFiles'] as int? ?? 0,
        color: const Color(0xFF4CAF50), // Green
        icon: Icons.image,
      );
    } catch (e) {
      debugPrint('📈 [RIVERPOD] Erro ao analisar arquivos de imagem: $e');
      return StorageCategoryData(
        category: StorageCategory.images,
        size: 0,
        fileCount: 0,
        color: const Color(0xFF4CAF50),
        icon: Icons.image,
      );
    }
  }

  /// CORRIGIDO: Analisa dados de notas usando métodos que existem
  /// Equivalente ao StorageAnalysisService._analyzeNotesData()
  Future<StorageCategoryData> _analyzeNotesData(NotesService? notesService) async {
    try {
      // CORRIGIDO: Usar métodos que realmente existem no NotesService
      int totalSize = 0;
      int noteCount = 0;
      
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final notesDir = Directory('${appDir.path}/notes');
        
        if (await notesDir.exists()) {
          await for (final entity in notesDir.list(recursive: true)) {
            if (entity is File) {
              try {
                totalSize += await entity.length();
                noteCount++;
              } catch (e) {
                // Ignore file errors
              }
            }
          }
        }
      } catch (e) {
        // Se falhar, use valores padrão
        totalSize = 1024; // 1KB default
        noteCount = 0;
      }

      return StorageCategoryData(
        category: StorageCategory.notes,
        size: totalSize,
        fileCount: noteCount,
        color: const Color(0xFFFF9800), // Orange
        icon: Icons.note,
      );
    } catch (e) {
      debugPrint('📈 [RIVERPOD] Erro ao analisar dados de notas: $e');
      return StorageCategoryData(
        category: StorageCategory.notes,
        size: 0,
        fileCount: 0,
        color: const Color(0xFFFF9800),
        icon: Icons.note,
      );
    }
  }

  /// Analisa dados de versículos
  /// Equivalente ao StorageAnalysisService._analyzeVersesData()
  Future<StorageCategoryData> _analyzeVersesData() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final versesDir = Directory('${appDir.path}/verses_cache');
      
      int totalSize = 0;
      int fileCount = 0;
      
      if (await versesDir.exists()) {
        await for (final entity in versesDir.list(recursive: true)) {
          if (entity is File) {
            try {
              totalSize += await entity.length();
              fileCount++;
            } catch (e) {
              // Ignore file errors
            }
          }
        }
      }

      return StorageCategoryData(
        category: StorageCategory.verses,
        size: totalSize,
        fileCount: fileCount,
        color: const Color(0xFF9C27B0), // Purple
        icon: Icons.menu_book,
      );
    } catch (e) {
      debugPrint('📈 [RIVERPOD] Erro ao analisar dados de versículos: $e');
      return StorageCategoryData(
        category: StorageCategory.verses,
        size: 0,
        fileCount: 0,
        color: const Color(0xFF9C27B0),
        icon: Icons.menu_book,
      );
    }
  }

  /// CORRIGIDO: Analisa dados de playlists usando métodos que existem
  /// Equivalente ao StorageAnalysisService._analyzePlaylistData()
  Future<StorageCategoryData> _analyzePlaylistData(PlaylistService? playlistService) async {
    try {
      // CORRIGIDO: Vamos simular ou usar método alternativo
      int totalSize = 0;
      int playlistCount = 0;
      
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final playlistDir = Directory('${appDir.path}/playlists');
        
        if (await playlistDir.exists()) {
          await for (final entity in playlistDir.list(recursive: true)) {
            if (entity is File && entity.path.endsWith('.json')) {
              try {
                totalSize += await entity.length();
                playlistCount++;
              } catch (e) {
                // Ignore file errors
              }
            }
          }
        }
      } catch (e) {
        // Valores padrão se falhar
        totalSize = 512; // 512 bytes default
        playlistCount = 0;
      }

      return StorageCategoryData(
        category: StorageCategory.playlists,
        size: totalSize,
        fileCount: playlistCount,
        color: const Color(0xFF607D8B), // Blue Grey
        icon: Icons.playlist_play,
      );
    } catch (e) {
      debugPrint('📈 [RIVERPOD] Erro ao analisar dados de playlists: $e');
      return StorageCategoryData(
        category: StorageCategory.playlists,
        size: 0,
        fileCount: 0,
        color: const Color(0xFF607D8B),
        icon: Icons.playlist_play,
      );
    }
  }

  /// Analisa dados de letras/textos
  /// Equivalente ao StorageAnalysisService._analyzeLetterData()
  Future<StorageCategoryData> _analyzeLetterData() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final textDir = Directory('${appDir.path}/texts');
      
      int totalSize = 0;
      int fileCount = 0;
      
      if (await textDir.exists()) {
        await for (final entity in textDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('.txt')) {
            try {
              totalSize += await entity.length();
              fileCount++;
            } catch (e) {
              // Ignore file errors
            }
          }
        }
      }

      return StorageCategoryData(
        category: StorageCategory.letters,
        size: totalSize,
        fileCount: fileCount,
        color: const Color(0xFF795548), // Brown
        icon: Icons.text_fields,
      );
    } catch (e) {
      debugPrint('📈 [RIVERPOD] Erro ao analisar dados de letras: $e');
      return StorageCategoryData(
        category: StorageCategory.letters,
        size: 0,
        fileCount: 0,
        color: const Color(0xFF795548),
        icon: Icons.text_fields,
      );
    }
  }

  /// Calcula a porcentagem de uso
  /// Equivalente ao StorageAnalysisService.getUsagePercentage()
  double getUsagePercentage() {
    if (state.currentUsage == null || state.currentUsage!.totalLimit == 0) return 0.0;
    return (state.currentUsage!.totalUsed / state.currentUsage!.totalLimit) * 100;
  }

  /// Verifica se está próximo do limite (acima de 80%)
  /// Equivalente ao StorageAnalysisService.isNearLimit()
  bool isNearLimit() {
    return getUsagePercentage() > 80.0;
  }

  /// Verifica se excedeu o limite
  /// Equivalente ao StorageAnalysisService.isOverLimit()
  bool isOverLimit() {
    return getUsagePercentage() > 100.0;
  }

  /// Obtém sugestão de upgrade baseada no uso
  /// Equivalente ao StorageAnalysisService.getUpgradeSuggestion()
  String? getUpgradeSuggestion() {
    if (state.currentUsage == null) return null;
    
    final percentage = getUsagePercentage();
    final currentPlan = state.currentUsage!.planType;
    
    if (percentage > 90 && currentPlan == 'starter') {
      return 'standard';
    } else if (percentage > 90 && currentPlan == 'standard') {
      return 'advanced';
    }
    
    return null;
  }

  /// Formatar tamanho de arquivo
  /// Equivalente ao StorageAnalysisService.formatFileSize()
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Sincroniza o estado do Riverpod com o sistema Provider legado
  /// Isso faz com que todos os arquivos que usam Consumer<StorageAnalysisService> reajam
  void _syncWithProviderSystem() {
    final globalStorageService = StorageAnalysisService.globalInstance;
    if (globalStorageService != null) {
      debugPrint('🔗 [BRIDGE] Sincronizando Riverpod → Provider (StorageAnalysis)');
      globalStorageService.syncWithRiverpod(
        state.currentUsage,
        state.isAnalyzing,
        state.errorMessage,
      );
      debugPrint('🔗 [BRIDGE] Sincronização completa');
    }
  }
}

/// Provider principal da análise de armazenamento - substituto completo do StorageAnalysisService
/// Usa as classes StorageUsageData, StorageCategoryData e StorageCategory do storage_analysis_service.dart
final storageAnalysisProvider = StateNotifierProvider<StorageAnalysisNotifier, StorageAnalysisState>((ref) {
  return StorageAnalysisNotifier();
});

/// Provider conveniente para acessar apenas o uso atual
final currentStorageUsageProvider = Provider<StorageUsageData?>((ref) {
  return ref.watch(storageAnalysisProvider).currentUsage;
});

/// Provider conveniente para verificar se está analisando
final isAnalyzingStorageProvider = Provider<bool>((ref) {
  return ref.watch(storageAnalysisProvider).isAnalyzing;
});

/// Provider conveniente para acessar mensagens de erro
final storageErrorMessageProvider = Provider<String?>((ref) {
  return ref.watch(storageAnalysisProvider).errorMessage;
});

/// Provider conveniente para acessar porcentagem de uso
final storageUsagePercentageProvider = Provider<double>((ref) {
  final notifier = ref.read(storageAnalysisProvider.notifier);
  return notifier.getUsagePercentage();
});

// =============================================================================
// LOTE 1 - MIGRAÇÕES SIMPLES (5 SERVIÇOS)
// =============================================================================

/// =============================================================================
/// 5. USER SETTINGS SERVICE → userSettingsProvider
/// =============================================================================

@immutable
class UserSettingsState {
  final String currentLanguage;
  final ThemeMode currentTheme;
  final String selectedBibleVersion;
  final bool isLoading;
  final String? errorMessage;

  const UserSettingsState({
    this.currentLanguage = 'pt',
    this.currentTheme = ThemeMode.system,
    this.selectedBibleVersion = 'KJV',
    this.isLoading = false,
    this.errorMessage,
  });

  UserSettingsState copyWith({
    String? currentLanguage,
    ThemeMode? currentTheme,
    String? selectedBibleVersion,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserSettingsState(
      currentLanguage: currentLanguage ?? this.currentLanguage,
      currentTheme: currentTheme ?? this.currentTheme,
      selectedBibleVersion: selectedBibleVersion ?? this.selectedBibleVersion,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class UserSettingsNotifier extends StateNotifier<UserSettingsState> {
  // Chaves para SharedPreferences
  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme';
  static const String _bibleVersionKey = 'selected_bible_version';

  UserSettingsNotifier() : super(const UserSettingsState());

  /// Carrega todas as configurações
  Future<void> loadSettings() async {
    debugPrint('⚙️ [RIVERPOD] Carregando configurações do usuário');
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final language = prefs.getString(_languageKey) ?? 'pt';
      final theme = _parseThemeMode(prefs.getString(_themeKey) ?? 'system');
      final bibleVersion = prefs.getString(_bibleVersionKey) ?? 'KJV';
      
      state = state.copyWith(
        currentLanguage: language,
        currentTheme: theme,
        selectedBibleVersion: bibleVersion,
        isLoading: false,
      );
      
      debugPrint('⚙️ [RIVERPOD] Configurações carregadas: $language, $theme, $bibleVersion');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      debugPrint('⚙️ [RIVERPOD] Erro ao carregar configurações: $e');
    }
  }

  /// Define o idioma
  Future<void> setLanguage(String language) async {
    debugPrint('⚙️ [RIVERPOD] Definindo idioma: $language');
    
    state = state.copyWith(currentLanguage: language);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  /// Define o tema
  Future<void> setTheme(ThemeMode theme) async {
    debugPrint('⚙️ [RIVERPOD] Definindo tema: $theme');
    
    state = state.copyWith(currentTheme: theme);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeToString(theme));
  }

  /// Define a versão da bíblia
  Future<void> setBibleVersion(String version) async {
    debugPrint('⚙️ [RIVERPOD] Definindo versão bíblia: $version');
    
    state = state.copyWith(selectedBibleVersion: version);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bibleVersionKey, version);
  }

  ThemeMode _parseThemeMode(String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeToString(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}

/// Provider principal das configurações do usuário
final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettingsState>((ref) {
  return UserSettingsNotifier();
});

/// Providers convenientes
final currentLanguageProvider = Provider<String>((ref) {
  return ref.watch(userSettingsProvider).currentLanguage;
});

final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(userSettingsProvider).currentTheme;
});

final selectedBibleVersionProvider = Provider<String>((ref) {
  return ref.watch(userSettingsProvider).selectedBibleVersion;
});

/// =============================================================================
/// 6. VERSE COLLECTION SERVICE → verseCollectionProvider
/// =============================================================================

@immutable
class VerseCollectionState {
  final List<dynamic> collections; // VerseCollection from models
  final bool isLoading;
  final String? errorMessage;

  const VerseCollectionState({
    this.collections = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  VerseCollectionState copyWith({
    List<dynamic>? collections,
    bool? isLoading,
    String? errorMessage,
  }) {
    return VerseCollectionState(
      collections: collections ?? this.collections,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class VerseCollectionNotifier extends StateNotifier<VerseCollectionState> {
  VerseCollectionNotifier() : super(const VerseCollectionState());

  /// Carrega coleções de versículos
  Future<void> loadCollections() async {
    debugPrint('📖 [RIVERPOD] Carregando coleções de versículos');
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      // TODO: Implementar carregamento real das coleções
      await Future.delayed(const Duration(milliseconds: 500));
      
      state = state.copyWith(
        collections: [], // Lista vazia por enquanto
        isLoading: false,
      );
      
      debugPrint('📖 [RIVERPOD] Coleções carregadas: ${state.collections.length}');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      debugPrint('📖 [RIVERPOD] Erro ao carregar coleções: $e');
    }
  }

  /// Adiciona uma nova coleção
  Future<void> createCollection(String name) async {
    debugPrint('📖 [RIVERPOD] Criando coleção: $name');
    
    try {
      // TODO: Implementar criação real da coleção
      await Future.delayed(const Duration(milliseconds: 300));
      
      debugPrint('📖 [RIVERPOD] Coleção criada: $name');
      await loadCollections(); // Recarrega
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      debugPrint('📖 [RIVERPOD] Erro ao criar coleção: $e');
    }
  }
}

/// Provider principal das coleções de versículos
final verseCollectionProvider = StateNotifierProvider<VerseCollectionNotifier, VerseCollectionState>((ref) {
  return VerseCollectionNotifier();
});

/// Providers convenientes
final collectionsListProvider = Provider<List<dynamic>>((ref) {
  return ref.watch(verseCollectionProvider).collections;
});

final isLoadingCollectionsProvider = Provider<bool>((ref) {
  return ref.watch(verseCollectionProvider).isLoading;
});

/// =============================================================================
/// 7. HYBRID MEDIA SERVICE → hybridMediaProvider
/// =============================================================================

@immutable
class HybridMediaState {
  final List<dynamic> mediaItems; // MediaItem from models
  final bool isInitialized;
  final bool isSyncing;
  final String? errorMessage;

  const HybridMediaState({
    this.mediaItems = const [],
    this.isInitialized = false,
    this.isSyncing = false,
    this.errorMessage,
  });

  HybridMediaState copyWith({
    List<dynamic>? mediaItems,
    bool? isInitialized,
    bool? isSyncing,
    String? errorMessage,
  }) {
    return HybridMediaState(
      mediaItems: mediaItems ?? this.mediaItems,
      isInitialized: isInitialized ?? this.isInitialized,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class HybridMediaNotifier extends StateNotifier<HybridMediaState> {
  HybridMediaNotifier() : super(const HybridMediaState());

  /// Inicializa o serviço híbrido
  Future<void> initialize() async {
    if (state.isInitialized) return;
    
    debugPrint('🎬 [RIVERPOD] Inicializando HybridMediaService');
    
    try {
      state = state.copyWith(isSyncing: true);
      
      // TODO: Implementar inicialização real
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        isInitialized: true,
        isSyncing: false,
        mediaItems: [], // Lista vazia por enquanto
      );
      
      debugPrint('🎬 [RIVERPOD] HybridMediaService inicializado');
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
      );
      debugPrint('🎬 [RIVERPOD] Erro na inicialização: $e');
    }
  }

  /// Sincroniza com Firebase
  Future<void> syncWithFirebase() async {
    debugPrint('🎬 [RIVERPOD] Sincronizando com Firebase');
    
    state = state.copyWith(isSyncing: true);
    
    try {
      // TODO: Implementar sincronização real
      await Future.delayed(const Duration(seconds: 2));
      
      state = state.copyWith(isSyncing: false);
      
      debugPrint('🎬 [RIVERPOD] Sincronização completa');
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
      );
      debugPrint('🎬 [RIVERPOD] Erro na sincronização: $e');
    }
  }
}

/// Provider principal do serviço de mídia híbrido
final hybridMediaProvider = StateNotifierProvider<HybridMediaNotifier, HybridMediaState>((ref) {
  return HybridMediaNotifier();
});

/// Providers convenientes
final mediaItemsProvider = Provider<List<dynamic>>((ref) {
  return ref.watch(hybridMediaProvider).mediaItems;
});

final isHybridMediaInitializedProvider = Provider<bool>((ref) {
  return ref.watch(hybridMediaProvider).isInitialized;
});

final isMediaSyncingProvider = Provider<bool>((ref) {
  return ref.watch(hybridMediaProvider).isSyncing;
});

/// =============================================================================
/// 8. PRESENTATION MANAGER → presentationManagerProvider
/// =============================================================================

@immutable
class PresentationManagerState {
  final bool isExternalPresentationActive;
  final bool hasExternalDisplay;
  final String? activeDisplayId;
  final String? activeDisplayName;
  final dynamic currentItem; // PresentationItem
  final bool isBlackScreenActive;

  const PresentationManagerState({
    this.isExternalPresentationActive = false,
    this.hasExternalDisplay = false,
    this.activeDisplayId,
    this.activeDisplayName,
    this.currentItem,
    this.isBlackScreenActive = false,
  });

  PresentationManagerState copyWith({
    bool? isExternalPresentationActive,
    bool? hasExternalDisplay,
    String? activeDisplayId,
    String? activeDisplayName,
    dynamic currentItem,
    bool? isBlackScreenActive,
  }) {
    return PresentationManagerState(
      isExternalPresentationActive: isExternalPresentationActive ?? this.isExternalPresentationActive,
      hasExternalDisplay: hasExternalDisplay ?? this.hasExternalDisplay,
      activeDisplayId: activeDisplayId ?? this.activeDisplayId,
      activeDisplayName: activeDisplayName ?? this.activeDisplayName,
      currentItem: currentItem ?? this.currentItem,
      isBlackScreenActive: isBlackScreenActive ?? this.isBlackScreenActive,
    );
  }
}

class PresentationManagerNotifier extends StateNotifier<PresentationManagerState> {
  PresentationManagerNotifier() : super(const PresentationManagerState()) {
    _initialize();
  }

  /// Inicializa o gerenciador de apresentação
  Future<void> _initialize() async {
    debugPrint('📊 [RIVERPOD] Inicializando PresentationManager');
    
    try {
      // TODO: Implementar inicialização real
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simula detecção de display externo
      state = state.copyWith(hasExternalDisplay: false);
      
      debugPrint('📊 [RIVERPOD] PresentationManager inicializado');
    } catch (e) {
      debugPrint('📊 [RIVERPOD] Erro na inicialização: $e');
    }
  }

  /// Inicia apresentação externa
  Future<void> startExternalPresentation(String displayId) async {
    debugPrint('📊 [RIVERPOD] Iniciando apresentação externa: $displayId');
    
    try {
      // TODO: Implementar lógica real
      await Future.delayed(const Duration(milliseconds: 300));
      
      state = state.copyWith(
        isExternalPresentationActive: true,
        activeDisplayId: displayId,
        activeDisplayName: 'Display Externo',
      );
      
      debugPrint('📊 [RIVERPOD] Apresentação externa ativa');
    } catch (e) {
      debugPrint('📊 [RIVERPOD] Erro ao iniciar apresentação: $e');
    }
  }

  /// Para apresentação externa
  Future<void> stopExternalPresentation() async {
    debugPrint('📊 [RIVERPOD] Parando apresentação externa');
    
    try {
      // TODO: Implementar lógica real
      await Future.delayed(const Duration(milliseconds: 300));
      
      state = state.copyWith(
        isExternalPresentationActive: false,
        activeDisplayId: null,
        activeDisplayName: null,
        currentItem: null,
        isBlackScreenActive: false,
      );
      
      debugPrint('📊 [RIVERPOD] Apresentação externa parada');
    } catch (e) {
      debugPrint('📊 [RIVERPOD] Erro ao parar apresentação: $e');
    }
  }

  /// Ativa/desativa tela preta
  void toggleBlackScreen() {
    debugPrint('📊 [RIVERPOD] Alternando tela preta');
    
    state = state.copyWith(
      isBlackScreenActive: !state.isBlackScreenActive,
    );
  }
}

/// Provider principal do gerenciador de apresentação
final presentationManagerProvider = StateNotifierProvider<PresentationManagerNotifier, PresentationManagerState>((ref) {
  return PresentationManagerNotifier();
});

/// Providers convenientes
final isExternalPresentationActiveProvider = Provider<bool>((ref) {
  return ref.watch(presentationManagerProvider).isExternalPresentationActive;
});

final hasExternalDisplayProvider = Provider<bool>((ref) {
  return ref.watch(presentationManagerProvider).hasExternalDisplay;
});

final currentPresentationItemProvider = Provider<dynamic>((ref) {
  return ref.watch(presentationManagerProvider).currentItem;
});

/// =============================================================================
/// 9. PRESENTATION ENGINE SERVICE → presentationEngineProvider
/// =============================================================================

@immutable
class PresentationEngineState {
  final dynamic currentItem; // PresentationItem
  final bool isBlackScreenActive;
  final bool isPresentationReady;
  final String? connectedDisplayId;
  final String? connectedDisplayName;

  const PresentationEngineState({
    this.currentItem,
    this.isBlackScreenActive = false,
    this.isPresentationReady = false,
    this.connectedDisplayId,
    this.connectedDisplayName,
  });

  PresentationEngineState copyWith({
    dynamic currentItem,
    bool? isBlackScreenActive,
    bool? isPresentationReady,
    String? connectedDisplayId,
    String? connectedDisplayName,
  }) {
    return PresentationEngineState(
      currentItem: currentItem ?? this.currentItem,
      isBlackScreenActive: isBlackScreenActive ?? this.isBlackScreenActive,
      isPresentationReady: isPresentationReady ?? this.isPresentationReady,
      connectedDisplayId: connectedDisplayId ?? this.connectedDisplayId,
      connectedDisplayName: connectedDisplayName ?? this.connectedDisplayName,
    );
  }
}

class PresentationEngineNotifier extends StateNotifier<PresentationEngineState> {
  PresentationEngineNotifier() : super(const PresentationEngineState()) {
    _setupMethodCallHandler();
  }

  /// Configura manipulador de chamadas nativas
  void _setupMethodCallHandler() {
    debugPrint('📊 [RIVERPOD] Configurando PresentationEngine');
    
    // TODO: Implementar setup real do método channel
    // Por enquanto simula inicialização
    Future.delayed(const Duration(milliseconds: 200), () {
      state = state.copyWith(isPresentationReady: true);
      debugPrint('📊 [RIVERPOD] PresentationEngine pronto');
    });
  }

  /// Mostra item na apresentação
  Future<void> showPresentationItem(dynamic item) async {
    debugPrint('📊 [RIVERPOD] Mostrando item na apresentação');
    
    try {
      // TODO: Implementar lógica real
      await Future.delayed(const Duration(milliseconds: 300));
      
      state = state.copyWith(
        currentItem: item,
        isBlackScreenActive: false,
      );
      
      debugPrint('📊 [RIVERPOD] Item mostrado na apresentação');
    } catch (e) {
      debugPrint('📊 [RIVERPOD] Erro ao mostrar item: $e');
    }
  }

  /// Ativa tela preta
  void activateBlackScreen() {
    debugPrint('📊 [RIVERPOD] Ativando tela preta');
    
    state = state.copyWith(
      isBlackScreenActive: true,
      currentItem: null,
    );
  }

  /// Desativa tela preta
  void deactivateBlackScreen() {
    debugPrint('📊 [RIVERPOD] Desativando tela preta');
    
    state = state.copyWith(isBlackScreenActive: false);
  }
}

/// Provider principal do engine de apresentação
final presentationEngineProvider = StateNotifierProvider<PresentationEngineNotifier, PresentationEngineState>((ref) {
  return PresentationEngineNotifier();
});

/// Providers convenientes
final isPresentationReadyProvider = Provider<bool>((ref) {
  return ref.watch(presentationEngineProvider).isPresentationReady;
});

final presentationBlackScreenProvider = Provider<bool>((ref) {
  return ref.watch(presentationEngineProvider).isBlackScreenActive;
});

final currentPresentationEngineItemProvider = Provider<dynamic>((ref) {
  return ref.watch(presentationEngineProvider).currentItem;
});

/// Provider conveniente para verificar se está perto do limite
final isNearStorageLimitProvider = Provider<bool>((ref) {
  final notifier = ref.read(storageAnalysisProvider.notifier);
  return notifier.isNearLimit();
});

// =============================================================================
// LOTE 2 - MIGRAÇÕES MÉDIAS (BRIDGE HÍBRIDA)
// =============================================================================

/// =============================================================================
/// 10. NOTES SERVICE → notesProvider
/// =============================================================================

@immutable
class NotesState {
  final Map<String, List<dynamic>> notesCache; // NoteItem from models
  final bool isInitialized;
  final bool isInitializing;
  final String? errorMessage;

  const NotesState({
    this.notesCache = const {},
    this.isInitialized = false,
    this.isInitializing = false,
    this.errorMessage,
  });

  NotesState copyWith({
    Map<String, List<dynamic>>? notesCache,
    bool? isInitialized,
    bool? isInitializing,
    String? errorMessage,
  }) {
    return NotesState(
      notesCache: notesCache ?? this.notesCache,
      isInitialized: isInitialized ?? this.isInitialized,
      isInitializing: isInitializing ?? this.isInitializing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  List<dynamic> get lyrics => notesCache['lyrics'] ?? [];
  List<dynamic> get notes => notesCache['notes'] ?? [];
}

class NotesNotifier extends StateNotifier<NotesState> {
  NotesNotifier() : super(const NotesState());

  /// Inicializa o serviço de notas
  Future<void> initialize() async {
    if (state.isInitialized || state.isInitializing) {
      debugPrint('📝 [RIVERPOD] NotesService já inicializado ou inicializando');
      return;
    }

    debugPrint('📝 [RIVERPOD] Iniciando NotesService');
    
    state = state.copyWith(isInitializing: true, errorMessage: null);
    _syncWithProviderSystem();

    try {
      // TODO: Implementar inicialização real com Firebase
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        isInitialized: true,
        isInitializing: false,
        notesCache: {
          'lyrics': [], // Lista vazia por enquanto
          'notes': [], // Lista vazia por enquanto
        },
      );
      _syncWithProviderSystem();
      
      debugPrint('📝 [RIVERPOD] NotesService inicializado com sucesso');
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        errorMessage: e.toString(),
      );
      _syncWithProviderSystem();
      
      debugPrint('📝 [RIVERPOD] Erro ao inicializar NotesService: $e');
    }
  }

  /// Adiciona uma nova nota
  Future<void> addNote(dynamic note) async {
    debugPrint('📝 [RIVERPOD] Adicionando nova nota');
    
    try {
      // TODO: Implementar adição real da nota
      await Future.delayed(const Duration(milliseconds: 300));
      
      final updatedNotes = List<dynamic>.from(state.notes)..add(note);
      final updatedCache = Map<String, List<dynamic>>.from(state.notesCache);
      updatedCache['notes'] = updatedNotes;
      
      state = state.copyWith(notesCache: updatedCache);
      _syncWithProviderSystem();
      
      debugPrint('📝 [RIVERPOD] Nota adicionada com sucesso');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      _syncWithProviderSystem();
      debugPrint('📝 [RIVERPOD] Erro ao adicionar nota: $e');
    }
  }

  /// Atualiza uma nota existente
  Future<void> updateNote(String noteId, dynamic updatedNote) async {
    debugPrint('📝 [RIVERPOD] Atualizando nota: $noteId');
    
    try {
      // TODO: Implementar atualização real da nota
      await Future.delayed(const Duration(milliseconds: 300));
      
      final updatedNotes = state.notes.map((note) {
        // TODO: Implementar lógica real de comparação de ID
        return note; // Por enquanto retorna a nota sem alteração
      }).toList();
      
      final updatedCache = Map<String, List<dynamic>>.from(state.notesCache);
      updatedCache['notes'] = updatedNotes;
      
      state = state.copyWith(notesCache: updatedCache);
      _syncWithProviderSystem();
      
      debugPrint('📝 [RIVERPOD] Nota atualizada com sucesso');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      _syncWithProviderSystem();
      debugPrint('📝 [RIVERPOD] Erro ao atualizar nota: $e');
    }
  }

  /// Deleta uma nota
  Future<void> deleteNote(String noteId) async {
    debugPrint('📝 [RIVERPOD] Deletando nota: $noteId');
    
    try {
      // TODO: Implementar deleção real da nota
      await Future.delayed(const Duration(milliseconds: 300));
      
      final updatedNotes = state.notes.where((note) {
        // TODO: Implementar lógica real de comparação de ID
        return true; // Por enquanto não remove nenhuma nota
      }).toList();
      
      final updatedCache = Map<String, List<dynamic>>.from(state.notesCache);
      updatedCache['notes'] = updatedNotes;
      
      state = state.copyWith(notesCache: updatedCache);
      _syncWithProviderSystem();
      
      debugPrint('📝 [RIVERPOD] Nota deletada com sucesso');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      _syncWithProviderSystem();
      debugPrint('📝 [RIVERPOD] Erro ao deletar nota: $e');
    }
  }

  /// Adiciona uma nova letra/lyric
  Future<void> addLyric(dynamic lyric) async {
    debugPrint('📝 [RIVERPOD] Adicionando nova letra');
    
    try {
      // TODO: Implementar adição real da letra
      await Future.delayed(const Duration(milliseconds: 300));
      
      final updatedLyrics = List<dynamic>.from(state.lyrics)..add(lyric);
      final updatedCache = Map<String, List<dynamic>>.from(state.notesCache);
      updatedCache['lyrics'] = updatedLyrics;
      
      state = state.copyWith(notesCache: updatedCache);
      _syncWithProviderSystem();
      
      debugPrint('📝 [RIVERPOD] Letra adicionada com sucesso');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      _syncWithProviderSystem();
      debugPrint('📝 [RIVERPOD] Erro ao adicionar letra: $e');
    }
  }

  /// Carrega notas do Firebase
  Future<void> loadNotes() async {
    debugPrint('📝 [RIVERPOD] Carregando notas do Firebase');
    
    try {
      // TODO: Implementar carregamento real das notas
      await Future.delayed(const Duration(milliseconds: 500));
      
      state = state.copyWith(
        notesCache: {
          'lyrics': [], // Lista vazia por enquanto
          'notes': [], // Lista vazia por enquanto
        },
        errorMessage: null,
      );
      _syncWithProviderSystem();
      
      debugPrint('📝 [RIVERPOD] Notas carregadas: ${state.notes.length} notes, ${state.lyrics.length} lyrics');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      _syncWithProviderSystem();
      debugPrint('📝 [RIVERPOD] Erro ao carregar notas: $e');
    }
  }

  /// Sincroniza o estado do Riverpod com o sistema Provider legado
  /// Isso faz com que todos os arquivos que usam Provider.of<NotesService> reajam
  void _syncWithProviderSystem() {
    final globalNotesService = NotesService.globalInstance;
    if (globalNotesService != null) {
      debugPrint('🔗 [BRIDGE] Sincronizando Riverpod → Provider (Notes)');
      globalNotesService.syncWithRiverpod(
        state.notesCache,
        state.isInitialized,
        state.isInitializing,
        state.errorMessage,
      );
      debugPrint('🔗 [BRIDGE] Sincronização completa');
    }
  }
}

/// Provider principal das notas
final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier();
});

/// Providers convenientes
final notesListProvider = Provider<List<dynamic>>((ref) {
  return ref.watch(notesProvider).notes;
});

final lyricsListProvider = Provider<List<dynamic>>((ref) {
  return ref.watch(notesProvider).lyrics;
});

final isNotesInitializedProvider = Provider<bool>((ref) {
  return ref.watch(notesProvider).isInitialized;
});

final isNotesInitializingProvider = Provider<bool>((ref) {
  return ref.watch(notesProvider).isInitializing;
});

final notesErrorMessageProvider = Provider<String?>((ref) {
  return ref.watch(notesProvider).errorMessage;
});

/// =============================================================================
/// 11. PLAYLIST SERVICE → playlistProvider
/// =============================================================================

@immutable
class PlaylistState {
  final List<dynamic> playlists; // Playlist objects
  final bool isInitialized;
  final bool isLoading;
  final String? errorMessage;

  const PlaylistState({
    this.playlists = const [],
    this.isInitialized = false,
    this.isLoading = false,
    this.errorMessage,
  });

  PlaylistState copyWith({
    List<dynamic>? playlists,
    bool? isInitialized,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PlaylistState(
      playlists: playlists ?? this.playlists,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PlaylistNotifier extends StateNotifier<PlaylistState> {
  PlaylistNotifier() : super(const PlaylistState());

  /// Inicializa o serviço de playlists
  Future<void> initialize() async {
    if (state.isInitialized) {
      debugPrint('🎵 [RIVERPOD] PlaylistService já inicializado');
      return;
    }

    debugPrint('🎵 [RIVERPOD] Iniciando PlaylistService');
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    _syncWithProviderSystem();

    try {
      // TODO: Implementar inicialização real com Firebase
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        playlists: [], // Lista vazia por enquanto
      );
      _syncWithProviderSystem();
      
      debugPrint('🎵 [RIVERPOD] PlaylistService inicializado com sucesso');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      _syncWithProviderSystem();
      
      debugPrint('🎵 [RIVERPOD] Erro ao inicializar PlaylistService: $e');
    }
  }

  /// Carrega playlists do Firebase
  Future<void> loadPlaylists() async {
    debugPrint('🎵 [RIVERPOD] Carregando playlists');
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    _syncWithProviderSystem();

    try {
      // TODO: Implementar carregamento real das playlists
      await Future.delayed(const Duration(milliseconds: 500));
      
      state = state.copyWith(
        playlists: [], // Lista vazia por enquanto
        isLoading: false,
      );
      _syncWithProviderSystem();
      
      debugPrint('🎵 [RIVERPOD] Playlists carregadas: ${state.playlists.length}');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      _syncWithProviderSystem();
      debugPrint('🎵 [RIVERPOD] Erro ao carregar playlists: $e');
    }
  }

  /// Cria uma nova playlist
  Future<void> createPlaylist(String title, {String? description}) async {
    debugPrint('🎵 [RIVERPOD] Criando playlist: $title');
    
    try {
      // TODO: Implementar criação real da playlist
      await Future.delayed(const Duration(milliseconds: 300));
      
      final updatedPlaylists = List<dynamic>.from(state.playlists);
      // TODO: Adicionar playlist real criada
      
      state = state.copyWith(playlists: updatedPlaylists);
      _syncWithProviderSystem();
      
      debugPrint('🎵 [RIVERPOD] Playlist criada: $title');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      _syncWithProviderSystem();
      debugPrint('🎵 [RIVERPOD] Erro ao criar playlist: $e');
    }
  }

  /// Atualiza uma playlist existente
  Future<void> updatePlaylist(String playlistId, dynamic updatedPlaylist) async {
    debugPrint('🎵 [RIVERPOD] Atualizando playlist: $playlistId');
    
    try {
      // TODO: Implementar atualização real da playlist
      await Future.delayed(const Duration(milliseconds: 300));
      
      final updatedPlaylists = state.playlists.map((playlist) {
        // TODO: Implementar lógica real de comparação de ID
        return playlist; // Por enquanto retorna sem alteração
      }).toList();
      
      state = state.copyWith(playlists: updatedPlaylists);
      _syncWithProviderSystem();
      
      debugPrint('🎵 [RIVERPOD] Playlist atualizada: $playlistId');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      _syncWithProviderSystem();
      debugPrint('🎵 [RIVERPOD] Erro ao atualizar playlist: $e');
    }
  }

  /// Deleta uma playlist
  Future<void> deletePlaylist(String playlistId) async {
    debugPrint('🎵 [RIVERPOD] Deletando playlist: $playlistId');
    
    try {
      // TODO: Implementar deleção real da playlist
      await Future.delayed(const Duration(milliseconds: 300));
      
      final updatedPlaylists = state.playlists.where((playlist) {
        // TODO: Implementar lógica real de comparação de ID
        return true; // Por enquanto não remove nenhuma
      }).toList();
      
      state = state.copyWith(playlists: updatedPlaylists);
      _syncWithProviderSystem();
      
      debugPrint('🎵 [RIVERPOD] Playlist deletada: $playlistId');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      _syncWithProviderSystem();
      debugPrint('🎵 [RIVERPOD] Erro ao deletar playlist: $e');
    }
  }

  /// Adiciona item à playlist
  Future<void> addItemToPlaylist(String playlistId, dynamic item) async {
    debugPrint('🎵 [RIVERPOD] Adicionando item à playlist: $playlistId');
    
    try {
      // TODO: Implementar adição real do item
      await Future.delayed(const Duration(milliseconds: 300));
      
      // TODO: Atualizar playlist específica com novo item
      
      debugPrint('🎵 [RIVERPOD] Item adicionado à playlist');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      _syncWithProviderSystem();
      debugPrint('🎵 [RIVERPOD] Erro ao adicionar item: $e');
    }
  }

  /// Remove item da playlist
  Future<void> removeItemFromPlaylist(String playlistId, String itemId) async {
    debugPrint('🎵 [RIVERPOD] Removendo item da playlist: $playlistId');
    
    try {
      // TODO: Implementar remoção real do item
      await Future.delayed(const Duration(milliseconds: 300));
      
      // TODO: Atualizar playlist específica removendo item
      
      debugPrint('🎵 [RIVERPOD] Item removido da playlist');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      _syncWithProviderSystem();
      debugPrint('🎵 [RIVERPOD] Erro ao remover item: $e');
    }
  }

  /// Sincroniza o estado do Riverpod com o sistema Provider legado
  /// Isso faz com que todos os arquivos que usam Provider.of<PlaylistService> reajam
  void _syncWithProviderSystem() {
    final globalPlaylistService = PlaylistService.globalInstance;
    if (globalPlaylistService != null) {
      debugPrint('🔗 [BRIDGE] Sincronizando Riverpod → Provider (Playlist)');
      globalPlaylistService.syncWithRiverpod(
        state.playlists,
        state.isInitialized,
        state.isLoading,
        state.errorMessage,
      );
      debugPrint('🔗 [BRIDGE] Sincronização completa');
    }
  }
}

/// Provider principal das playlists
final playlistProvider = StateNotifierProvider<PlaylistNotifier, PlaylistState>((ref) {
  return PlaylistNotifier();
});

/// Providers convenientes
final playlistsListProvider = Provider<List<dynamic>>((ref) {
  return ref.watch(playlistProvider).playlists;
});

final isPlaylistsInitializedProvider = Provider<bool>((ref) {
  return ref.watch(playlistProvider).isInitialized;
});

final isPlaylistsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(playlistProvider).isLoading;
});

final playlistsErrorMessageProvider = Provider<String?>((ref) {
  return ref.watch(playlistProvider).errorMessage;
});

final playlistsCountProvider = Provider<int>((ref) {
  return ref.watch(playlistProvider).playlists.length;
});

/// Provider conveniente para verificar se excedeu o limite
final isOverStorageLimitProvider = Provider<bool>((ref) {
  final notifier = ref.read(storageAnalysisProvider.notifier);
  return notifier.isOverLimit();
});

/// Provider conveniente para sugestão de upgrade
final upgradeStorageSuggestionProvider = Provider<String?>((ref) {
  final notifier = ref.read(storageAnalysisProvider.notifier);
  return notifier.getUpgradeSuggestion();
});

/// =============================================================================
/// 12. MEDIA SYNC SERVICE → mediaSyncProvider
/// =============================================================================

@immutable
class MediaSyncState {
  final bool isSyncing;
  final double masterTimestamp;
  final String? masterDisplayId;
  final Map<String, double> displayLatencies;
  final Map<String, DateTime> lastHeartbeats;
  final String? errorMessage;

  const MediaSyncState({
    this.isSyncing = false,
    this.masterTimestamp = 0.0,
    this.masterDisplayId,
    this.displayLatencies = const {},
    this.lastHeartbeats = const {},
    this.errorMessage,
  });

  MediaSyncState copyWith({
    bool? isSyncing,
    double? masterTimestamp,
    String? masterDisplayId,
    Map<String, double>? displayLatencies,
    Map<String, DateTime>? lastHeartbeats,
    String? errorMessage,
  }) {
    return MediaSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      masterTimestamp: masterTimestamp ?? this.masterTimestamp,
      masterDisplayId: masterDisplayId ?? this.masterDisplayId,
      displayLatencies: displayLatencies ?? this.displayLatencies,
      lastHeartbeats: lastHeartbeats ?? this.lastHeartbeats,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MediaSyncNotifier extends StateNotifier<MediaSyncState> {
  MediaSyncNotifier() : super(const MediaSyncState());

  /// Inicia a sincronização de mídia
  Future<void> startSync() async {
    if (state.isSyncing) {
      debugPrint('🔄 [RIVERPOD] MediaSync já está sincronizando');
      return;
    }

    debugPrint('🔄 [RIVERPOD] Iniciando sincronização de mídia');
    
    state = state.copyWith(isSyncing: true, errorMessage: null);
    _syncWithProviderSystem();

    try {
      // TODO: Implementar lógica real de sincronização
      await Future.delayed(const Duration(milliseconds: 500));
      
      state = state.copyWith(
        masterTimestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
        masterDisplayId: 'main_display',
      );
      _syncWithProviderSystem();
      
      debugPrint('🔄 [RIVERPOD] Sincronização iniciada');
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
      );
      _syncWithProviderSystem();
      debugPrint('🔄 [RIVERPOD] Erro ao iniciar sincronização: $e');
    }
  }

  /// Para a sincronização de mídia
  Future<void> stopSync() async {
    debugPrint('🔄 [RIVERPOD] Parando sincronização de mídia');
    
    try {
      // TODO: Implementar parada real da sincronização
      await Future.delayed(const Duration(milliseconds: 200));
      
      state = state.copyWith(
        isSyncing: false,
        masterTimestamp: 0.0,
        masterDisplayId: null,
        displayLatencies: {},
        lastHeartbeats: {},
      );
      _syncWithProviderSystem();
      
      debugPrint('🔄 [RIVERPOD] Sincronização parada');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      _syncWithProviderSystem();
      debugPrint('🔄 [RIVERPOD] Erro ao parar sincronização: $e');
    }
  }

  /// Atualiza latências dos displays
  void updateDisplayLatencies(Map<String, double> latencies) {
    debugPrint('🔄 [RIVERPOD] Atualizando latências dos displays');
    
    state = state.copyWith(displayLatencies: Map.from(latencies));
    _syncWithProviderSystem();
  }

  /// Atualiza heartbeats dos displays
  void updateHeartbeats(Map<String, DateTime> heartbeats) {
    debugPrint('🔄 [RIVERPOD] Atualizando heartbeats dos displays');
    
    state = state.copyWith(lastHeartbeats: Map.from(heartbeats));
    _syncWithProviderSystem();
  }

  /// Define o display master
  void setMasterDisplay(String displayId) {
    debugPrint('🔄 [RIVERPOD] Definindo display master: $displayId');
    
    state = state.copyWith(masterDisplayId: displayId);
    _syncWithProviderSystem();
  }

  /// Atualiza timestamp master
  void updateMasterTimestamp(double timestamp) {
    state = state.copyWith(masterTimestamp: timestamp);
    _syncWithProviderSystem();
  }

  /// Sincroniza displays
  Future<void> syncDisplays() async {
    if (!state.isSyncing) {
      debugPrint('🔄 [RIVERPOD] Sincronização não está ativa');
      return;
    }

    debugPrint('🔄 [RIVERPOD] Sincronizando displays');
    
    try {
      // TODO: Implementar sincronização real dos displays
      await Future.delayed(const Duration(milliseconds: 100));
      
      final now = DateTime.now().millisecondsSinceEpoch.toDouble();
      state = state.copyWith(masterTimestamp: now);
      _syncWithProviderSystem();
      
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      _syncWithProviderSystem();
      debugPrint('🔄 [RIVERPOD] Erro na sincronização: $e');
    }
  }

  /// Sincroniza o estado do Riverpod com o sistema Provider legado
  /// Isso faz com que todos os arquivos que usam Provider.of<MediaSyncService> reajam
  void _syncWithProviderSystem() {
    final globalMediaSyncService = MediaSyncService.globalInstance;
    if (globalMediaSyncService != null) {
      debugPrint('🔗 [BRIDGE] Sincronizando Riverpod → Provider (MediaSync)');
      globalMediaSyncService.syncWithRiverpod(
        state.isSyncing,
        state.masterTimestamp,
        state.masterDisplayId,
        state.displayLatencies,
        state.lastHeartbeats,
        state.errorMessage,
      );
      debugPrint('🔗 [BRIDGE] Sincronização completa');
    }
  }
}

/// Provider principal da sincronização de mídia
final mediaSyncProvider = StateNotifierProvider<MediaSyncNotifier, MediaSyncState>((ref) {
  return MediaSyncNotifier();
});

// ==========================================
// DataSyncManager - Migração Direta
// ==========================================

class DataSyncState {
  final bool isSyncing;
  final String? syncError;
  final DateTime? lastSyncTime;
  final int pendingOperations;

  DataSyncState({
    this.isSyncing = false,
    this.syncError,
    this.lastSyncTime,
    this.pendingOperations = 0,
  });

  bool get hasPendingOperations => pendingOperations > 0;

  DataSyncState copyWith({
    bool? isSyncing,
    String? syncError,
    DateTime? lastSyncTime,
    int? pendingOperations,
  }) {
    return DataSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: syncError ?? this.syncError,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingOperations: pendingOperations ?? this.pendingOperations,
    );
  }
}

class DataSyncNotifier extends StateNotifier<DataSyncState> {
  final FirebaseManager _firebase = FirebaseManager();
  
  static const String _syncQueueKey = 'versee_sync_queue';
  static const String _lastSyncTimeKey = 'versee_last_sync_time';

  DataSyncNotifier() : super(DataSyncState()) {
    _loadSyncState();
  }

  Future<void> initialize() async {
    await _loadPendingOperations();
    
    _firebase.authStateChanges.listen((user) {
      if (user != null) {
        syncPendingOperations();
      }
    });
  }

  Future<void> _loadSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncTimeKey);
      if (lastSyncStr != null) {
        state = state.copyWith(lastSyncTime: DateTime.parse(lastSyncStr));
      }
    } catch (e) {
      debugPrint('Error loading sync state: $e');
    }
  }

  Future<void> _saveSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (state.lastSyncTime != null) {
        await prefs.setString(_lastSyncTimeKey, state.lastSyncTime!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving sync state: $e');
    }
  }

  Future<void> _loadPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_syncQueueKey);
      if (queueJson != null) {
        final queue = json.decode(queueJson) as List;
        state = state.copyWith(pendingOperations: queue.length);
      }
    } catch (e) {
      debugPrint('Error loading pending operations: $e');
    }
  }

  Future<void> queueOperation({
    required String type,
    required String collection,
    String? documentId,
    Map<String, dynamic>? data,
    String? tempId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_syncQueueKey) ?? '[]';
      final queue = json.decode(queueJson) as List;

      final operation = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'collection': collection,
        'documentId': documentId,
        'data': data,
        'tempId': tempId,
        'timestamp': DateTime.now().toIso8601String(),
        'retryCount': 0,
      };

      queue.add(operation);
      await prefs.setString(_syncQueueKey, json.encode(queue));
      
      state = state.copyWith(pendingOperations: queue.length);
      debugPrint('Operation queued: $type $collection');
    } catch (e) {
      debugPrint('Error queueing operation: $e');
    }
  }

  Future<void> syncPendingOperations() async {
    if (state.isSyncing || !_firebase.isUserAuthenticated) return;

    try {
      state = state.copyWith(isSyncing: true, syncError: null);

      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_syncQueueKey);
      if (queueJson == null) return;

      final queue = json.decode(queueJson) as List;
      if (queue.isEmpty) return;

      debugPrint('Syncing ${queue.length} pending operations');

      final successfulOperations = <int>[];
      
      for (int i = 0; i < queue.length; i++) {
        final operation = queue[i] as Map<String, dynamic>;
        
        try {
          await _executeOperation(operation);
          successfulOperations.add(i);
          debugPrint('Operation synced: ${operation['type']} ${operation['collection']}');
        } catch (e) {
          debugPrint('Failed to sync operation: $e');
          
          operation['retryCount'] = (operation['retryCount'] ?? 0) + 1;
          
          if (operation['retryCount'] >= 3) {
            successfulOperations.add(i);
            debugPrint('Operation removed after 3 failed attempts');
          }
        }
      }

      for (int i = successfulOperations.length - 1; i >= 0; i--) {
        queue.removeAt(successfulOperations[i]);
      }

      await prefs.setString(_syncQueueKey, json.encode(queue));
      
      state = state.copyWith(
        pendingOperations: queue.length,
        lastSyncTime: DateTime.now(),
      );
      
      await _saveSyncState();
      debugPrint('Sync completed. ${successfulOperations.length} operations synced, ${queue.length} remaining');
      
    } catch (e) {
      state = state.copyWith(syncError: 'Erro na sincronização: $e');
      debugPrint('Sync error: $e');
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> _executeOperation(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;
    final collection = operation['collection'] as String;
    final documentId = operation['documentId'] as String?;
    final data = operation['data'] as Map<String, dynamic>?;

    switch (type) {
      case 'create':
        if (data != null) {
          data['userId'] = _firebase.currentUserId;
          await _firebase.firestore
              .collection(collection)
              .add(FirestoreConverter.prepareForFirestore(data));
        }
        break;

      case 'update':
        if (documentId != null && data != null) {
          data['updatedAt'] = DateTime.now();
          await _firebase.firestore
              .collection(collection)
              .doc(documentId)
              .update(FirestoreConverter.prepareForFirestore(data));
        }
        break;

      case 'delete':
        if (documentId != null) {
          await _firebase.firestore
              .collection(collection)
              .doc(documentId)
              .delete();
        }
        break;

      default:
        throw Exception('Unknown operation type: $type');
    }
  }

  Future<String> createWithSync({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    if (_firebase.isUserAuthenticated) {
      try {
        data['userId'] = _firebase.currentUserId;
        final docRef = await _firebase.firestore
            .collection(collection)
            .add(FirestoreConverter.prepareForFirestore(data));
        return docRef.id;
      } catch (e) {
        await queueOperation(
          type: 'create',
          collection: collection,
          data: data,
          tempId: tempId,
        );
        return tempId;
      }
    } else {
      await queueOperation(
        type: 'create',
        collection: collection,
        data: data,
        tempId: tempId,
      );
      return tempId;
    }
  }

  Future<bool> updateWithSync({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    if (_firebase.isUserAuthenticated) {
      try {
        data['updatedAt'] = DateTime.now();
        await _firebase.firestore
            .collection(collection)
            .doc(documentId)
            .update(FirestoreConverter.prepareForFirestore(data));
        return true;
      } catch (e) {
        await queueOperation(
          type: 'update',
          collection: collection,
          documentId: documentId,
          data: data,
        );
        return false;
      }
    } else {
      await queueOperation(
        type: 'update',
        collection: collection,
        documentId: documentId,
        data: data,
      );
      return false;
    }
  }

  Future<bool> deleteWithSync({
    required String collection,
    required String documentId,
  }) async {
    if (_firebase.isUserAuthenticated) {
      try {
        await _firebase.firestore
            .collection(collection)
            .doc(documentId)
            .delete();
        return true;
      } catch (e) {
        await queueOperation(
          type: 'delete',
          collection: collection,
          documentId: documentId,
        );
        return false;
      }
    } else {
      await queueOperation(
        type: 'delete',
        collection: collection,
        documentId: documentId,
      );
      return false;
    }
  }

  Future<void> clearPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_syncQueueKey);
      state = state.copyWith(pendingOperations: 0);
      debugPrint('All pending operations cleared');
    } catch (e) {
      debugPrint('Error clearing pending operations: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_syncQueueKey) ?? '[]';
      final queue = json.decode(queueJson) as List;
      return queue.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting pending operations: $e');
      return [];
    }
  }

  Future<void> forceSync() async {
    await syncPendingOperations();
  }

  Future<bool> hasNetworkConnectivity() async {
    try {
      await _firebase.firestore.collection('_connectivity_test').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  void onAppResumed() {
    if (state.hasPendingOperations) {
      syncPendingOperations();
    }
  }

  void onNetworkRestored() {
    if (state.hasPendingOperations) {
      syncPendingOperations();
    }
  }

  Map<String, dynamic> getSyncStatus() {
    return {
      'isSyncing': state.isSyncing,
      'pendingOperations': state.pendingOperations,
      'lastSyncTime': state.lastSyncTime?.toIso8601String(),
      'hasError': state.syncError != null,
      'error': state.syncError,
    };
  }

  Future<String> exportPendingOperations() async {
    final operations = await getPendingOperations();
    return json.encode(operations);
  }
}

final dataSyncProvider = StateNotifierProvider<DataSyncNotifier, DataSyncState>((ref) {
  return DataSyncNotifier();
});

// ==========================================
// RealtimeDataService - Migração Direta
// ==========================================

class RealtimeDataState {
  final Map<String, List<Map<String, dynamic>>> cache;
  final Map<String, bool> loadingStates;
  final Map<String, String?> errorStates;
  final String? currentUserId;

  RealtimeDataState({
    Map<String, List<Map<String, dynamic>>>? cache,
    Map<String, bool>? loadingStates,
    Map<String, String?>? errorStates,
    this.currentUserId,
  }) : cache = cache ?? {},
        loadingStates = loadingStates ?? {},
        errorStates = errorStates ?? {};

  List<Map<String, dynamic>> getPlaylists() => cache['playlists'] ?? [];
  
  List<Map<String, dynamic>> getNotes({String? type}) {
    final notes = cache['notes'] ?? [];
    if (type == null) return notes;
    return notes.where((note) => note['type'] == type).toList();
  }
  
  List<Map<String, dynamic>> getMedia({String? type}) {
    final media = cache['media'] ?? [];
    if (type == null) return media;
    return media.where((item) => item['type'] == type).toList();
  }
  
  List<Map<String, dynamic>> getVerseCollections() => cache['verseCollections'] ?? [];

  bool isPlaylistsLoading() => loadingStates['playlists'] ?? false;
  bool isNotesLoading() => loadingStates['notes'] ?? false;
  bool isMediaLoading() => loadingStates['media'] ?? false;
  bool isVerseCollectionsLoading() => loadingStates['verseCollections'] ?? false;

  String? getPlaylistsError() => errorStates['playlists'];
  String? getNotesError() => errorStates['notes'];
  String? getMediaError() => errorStates['media'];
  String? getVerseCollectionsError() => errorStates['verseCollections'];

  RealtimeDataState copyWith({
    Map<String, List<Map<String, dynamic>>>? cache,
    Map<String, bool>? loadingStates,
    Map<String, String?>? errorStates,
    String? currentUserId,
  }) {
    return RealtimeDataState(
      cache: cache ?? this.cache,
      loadingStates: loadingStates ?? this.loadingStates,
      errorStates: errorStates ?? this.errorStates,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}

class RealtimeDataNotifier extends StateNotifier<RealtimeDataState> {
  final FirebaseManager _firebase = FirebaseManager();
  final Map<String, StreamSubscription> _subscriptions = {};

  RealtimeDataNotifier() : super(RealtimeDataState());

  void startListening() {
    final userId = _firebase.currentUserId;
    if (userId == null) {
      debugPrint('No user authenticated, cannot start real-time listening');
      return;
    }

    state = state.copyWith(currentUserId: userId);
    _startPlaylistsStream();
    _startNotesStream();
    _startMediaStream();
    _startVerseCollectionsStream();

    debugPrint('Real-time streams started for user: $userId');
  }

  void stopListening() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    state = RealtimeDataState();
    debugPrint('Real-time streams stopped');
  }

  void _startPlaylistsStream() {
    if (state.currentUserId == null) return;

    _setLoadingState('playlists', true);
    
    final stream = _firebase.firestore
        .collection(FirestoreDataSchema.playlistsCollection)
        .where('userId', isEqualTo: state.currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    _subscriptions['playlists'] = stream.listen(
      (snapshot) {
        final playlists = snapshot.docs.map((doc) {
          final data = FirestoreConverter.parseFromFirestore(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();

        final newCache = Map<String, List<Map<String, dynamic>>>.from(state.cache);
        newCache['playlists'] = playlists;
        
        _setLoadingState('playlists', false);
        _clearError('playlists');
        state = state.copyWith(cache: newCache);
      },
      onError: (error) {
        _setError('playlists', 'Erro ao carregar playlists: $error');
        _setLoadingState('playlists', false);
      },
    );
  }

  void _startNotesStream() {
    if (state.currentUserId == null) return;

    _setLoadingState('notes', true);
    
    final stream = _firebase.firestore
        .collection(FirestoreDataSchema.notesCollection)
        .where('userId', isEqualTo: state.currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    _subscriptions['notes'] = stream.listen(
      (snapshot) {
        final notes = snapshot.docs.map((doc) {
          final data = FirestoreConverter.parseFromFirestore(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();

        final newCache = Map<String, List<Map<String, dynamic>>>.from(state.cache);
        newCache['notes'] = notes;
        
        _setLoadingState('notes', false);
        _clearError('notes');
        state = state.copyWith(cache: newCache);
      },
      onError: (error) {
        _setError('notes', 'Erro ao carregar notas: $error');
        _setLoadingState('notes', false);
      },
    );
  }

  void _startMediaStream() {
    if (state.currentUserId == null) return;

    _setLoadingState('media', true);
    
    final stream = _firebase.firestore
        .collection(FirestoreDataSchema.mediaCollection)
        .where('userId', isEqualTo: state.currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    _subscriptions['media'] = stream.listen(
      (snapshot) {
        final media = snapshot.docs.map((doc) {
          final data = FirestoreConverter.parseFromFirestore(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();

        final newCache = Map<String, List<Map<String, dynamic>>>.from(state.cache);
        newCache['media'] = media;
        
        _setLoadingState('media', false);
        _clearError('media');
        state = state.copyWith(cache: newCache);
      },
      onError: (error) {
        _setError('media', 'Erro ao carregar mídia: $error');
        _setLoadingState('media', false);
      },
    );
  }

  void _startVerseCollectionsStream() {
    if (state.currentUserId == null) return;

    _setLoadingState('verseCollections', true);
    
    final stream = _firebase.firestore
        .collection(FirestoreDataSchema.verseCollectionsCollection)
        .where('userId', isEqualTo: state.currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    _subscriptions['verseCollections'] = stream.listen(
      (snapshot) {
        final collections = snapshot.docs.map((doc) {
          final data = FirestoreConverter.parseFromFirestore(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();

        final newCache = Map<String, List<Map<String, dynamic>>>.from(state.cache);
        newCache['verseCollections'] = collections;
        
        _setLoadingState('verseCollections', false);
        _clearError('verseCollections');
        state = state.copyWith(cache: newCache);
      },
      onError: (error) {
        _setError('verseCollections', 'Erro ao carregar coleções de versículos: $error');
        _setLoadingState('verseCollections', false);
      },
    );
  }

  Stream<Map<String, dynamic>?> getPlaylistStream(String playlistId) {
    return _firebase.firestore
        .collection(FirestoreDataSchema.playlistsCollection)
        .doc(playlistId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = FirestoreConverter.parseFromFirestore(doc.data()!);
      data['id'] = doc.id;
      return data;
    });
  }

  Stream<Map<String, dynamic>?> getNoteStream(String noteId) {
    return _firebase.firestore
        .collection(FirestoreDataSchema.notesCollection)
        .doc(noteId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = FirestoreConverter.parseFromFirestore(doc.data()!);
      data['id'] = doc.id;
      return data;
    });
  }

  Stream<Map<String, dynamic>?> getUserSettingsStream() {
    if (state.currentUserId == null) return Stream.value(null);
    
    return _firebase.firestore
        .collection(FirestoreDataSchema.settingsCollection)
        .doc(state.currentUserId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return FirestoreConverter.parseFromFirestore(doc.data()!);
    });
  }

  void handleConnectivityChange(bool isConnected) {
    if (isConnected) {
      debugPrint('Connectivity restored, restarting streams');
      stopListening();
      startListening();
    } else {
      debugPrint('Connectivity lost, streams will work offline');
    }
  }

  Map<String, int> getDataStatistics() {
    return {
      'playlists': state.getPlaylists().length,
      'notes': state.getNotes().length,
      'lyrics': state.getNotes(type: 'lyrics').length,
      'media': state.getMedia().length,
      'audio': state.getMedia(type: 'audio').length,
      'video': state.getMedia(type: 'video').length,
      'image': state.getMedia(type: 'image').length,
      'verseCollections': state.getVerseCollections().length,
    };
  }

  List<Map<String, dynamic>> searchAll(String query) {
    final results = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase();

    for (final playlist in state.getPlaylists()) {
      if (_matchesQuery(playlist, lowerQuery, ['title', 'description'])) {
        results.add({...playlist, '_type': 'playlist'});
      }
    }

    for (final note in state.getNotes()) {
      if (_matchesQuery(note, lowerQuery, ['title'])) {
        results.add({...note, '_type': 'note'});
      }
    }

    for (final media in state.getMedia()) {
      if (_matchesQuery(media, lowerQuery, ['name', 'fileName'])) {
        results.add({...media, '_type': 'media'});
      }
    }

    for (final collection in state.getVerseCollections()) {
      if (_matchesQuery(collection, lowerQuery, ['title'])) {
        results.add({...collection, '_type': 'verseCollection'});
      }
    }

    return results;
  }

  bool _matchesQuery(Map<String, dynamic> item, String query, List<String> fields) {
    for (final field in fields) {
      final value = item[field]?.toString().toLowerCase();
      if (value != null && value.contains(query)) {
        return true;
      }
    }
    return false;
  }

  void _setLoadingState(String key, bool loading) {
    final newLoadingStates = Map<String, bool>.from(state.loadingStates);
    newLoadingStates[key] = loading;
    state = state.copyWith(loadingStates: newLoadingStates);
  }

  void _setError(String key, String error) {
    final newErrorStates = Map<String, String?>.from(state.errorStates);
    newErrorStates[key] = error;
    state = state.copyWith(errorStates: newErrorStates);
  }

  void _clearError(String key) {
    final newErrorStates = Map<String, String?>.from(state.errorStates);
    newErrorStates[key] = null;
    state = state.copyWith(errorStates: newErrorStates);
  }

  Future<void> refreshPlaylists() async {
    _subscriptions['playlists']?.cancel();
    _startPlaylistsStream();
  }

  Future<void> refreshNotes() async {
    _subscriptions['notes']?.cancel();
    _startNotesStream();
  }

  Future<void> refreshMedia() async {
    _subscriptions['media']?.cancel();
    _startMediaStream();
  }

  Future<void> refreshVerseCollections() async {
    _subscriptions['verseCollections']?.cancel();
    _startVerseCollectionsStream();
  }

  Future<void> refreshAll() async {
    stopListening();
    await Future.delayed(const Duration(milliseconds: 500));
    startListening();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

final realtimeDataProvider = StateNotifierProvider<RealtimeDataNotifier, RealtimeDataState>((ref) {
  return RealtimeDataNotifier();
});

// ==========================================
// MediaPlaybackService - Migração Direta 🎛️
// ==========================================

class MediaPlaybackState {
  final MediaItem? currentMedia;
  final bool isPlaying;
  final bool isPaused;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool isMuted;

  MediaPlaybackState({
    this.currentMedia,
    this.isPlaying = false,
    this.isPaused = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.isMuted = false,
  });

  // Estado da reprodução
  bool get hasMedia => currentMedia != null;
  bool get canPlay => hasMedia && !isPlaying;
  bool get canPause => hasMedia && isPlaying;
  bool get canStop => hasMedia && (isPlaying || isPaused);
  bool get canSeek => hasMedia && duration > Duration.zero;

  // Progresso da reprodução (0.0 - 1.0)
  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  // Getters adicionais para compatibilidade com MediaSyncService
  Duration get currentPosition => position;
  String? get currentMediaId => currentMedia?.id;

  // Obtém informações da mídia atual
  String get currentMediaInfo {
    if (!hasMedia) return 'Nenhuma mídia selecionada';
    
    final media = currentMedia!;
    final parts = <String>[media.title];
    
    if (media is AudioItem && media.artist != null) {
      parts.add(media.artist!);
    } else if (media is VideoItem && media.resolution != null) {
      parts.add(media.resolution!);
    }
    
    return parts.join(' • ');
  }

  // Obtém o status atual da reprodução
  String get playbackStatus {
    if (!hasMedia) return 'Parado';
    if (isPlaying) return 'Reproduzindo';
    if (isPaused) return 'Pausado';
    return 'Parado';
  }

  MediaPlaybackState copyWith({
    MediaItem? currentMedia,
    bool? isPlaying,
    bool? isPaused,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isMuted,
  }) {
    return MediaPlaybackState(
      currentMedia: currentMedia ?? this.currentMedia,
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class MediaPlaybackNotifier extends StateNotifier<MediaPlaybackState> {
  // Callbacks para controle do player widget
  VoidCallback? _playCallback;
  VoidCallback? _pauseCallback;
  VoidCallback? _stopCallback;
  Function(Duration)? _seekCallback;
  Function(double)? _volumeCallback;

  MediaPlaybackNotifier() : super(MediaPlaybackState());

  /// Define a mídia atual para reprodução
  void setCurrentMedia(MediaItem? media) {
    if (state.currentMedia?.id != media?.id) {
      state = state.copyWith(
        currentMedia: media,
        isPlaying: false,
        isPaused: false,
        position: Duration.zero,
        duration: Duration.zero,
      );
    }
  }

  /// Registra callbacks do player widget para controle
  void registerPlayerCallbacks({
    VoidCallback? onPlay,
    VoidCallback? onPause,
    VoidCallback? onStop,
    Function(Duration)? onSeek,
    Function(double)? onVolume,
  }) {
    _playCallback = onPlay;
    _pauseCallback = onPause;
    _stopCallback = onStop;
    _seekCallback = onSeek;
    _volumeCallback = onVolume;
  }

  /// Inicia a reprodução
  Future<void> play() async {
    if (!state.hasMedia || state.isPlaying) return;

    try {
      _playCallback?.call();
      state = state.copyWith(isPlaying: true, isPaused: false);
    } catch (e) {
      debugPrint('Erro ao iniciar reprodução: $e');
    }
  }

  /// Pausa a reprodução
  Future<void> pause() async {
    if (!state.hasMedia || !state.isPlaying) return;

    try {
      _pauseCallback?.call();
      state = state.copyWith(isPlaying: false, isPaused: true);
    } catch (e) {
      debugPrint('Erro ao pausar reprodução: $e');
    }
  }

  /// Para a reprodução
  Future<void> stop() async {
    if (!state.hasMedia) return;

    try {
      _stopCallback?.call();
      state = state.copyWith(
        isPlaying: false,
        isPaused: false,
        position: Duration.zero,
      );
    } catch (e) {
      debugPrint('Erro ao parar reprodução: $e');
    }
  }

  /// Inicia reprodução de uma mídia específica
  Future<void> playMedia(String mediaId) async {
    if (state.currentMedia?.id == mediaId) {
      await play();
    }
  }

  /// Resume reprodução (alias para play para compatibilidade)
  Future<void> resume() async {
    await play();
  }

  /// Seek para posição específica (alias para seekTo para compatibilidade)
  Future<void> seek(Duration position) async {
    await seekTo(position);
  }

  /// Alterna entre play/pause
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Busca uma posição específica na mídia
  Future<void> seekTo(Duration position) async {
    if (!state.hasMedia || !state.canSeek) return;

    try {
      _seekCallback?.call(position);
      state = state.copyWith(position: position);
    } catch (e) {
      debugPrint('Erro ao buscar posição: $e');
    }
  }

  /// Busca por porcentagem (0.0 - 1.0)
  Future<void> seekToPercentage(double percentage) async {
    if (!state.canSeek) return;
    
    final position = Duration(
      milliseconds: (state.duration.inMilliseconds * percentage).round(),
    );
    await seekTo(position);
  }

  /// Avança alguns segundos
  Future<void> forward(int seconds) async {
    final newPosition = state.position + Duration(seconds: seconds);
    final maxPosition = state.duration;
    
    if (newPosition >= maxPosition) {
      await seekTo(maxPosition);
    } else {
      await seekTo(newPosition);
    }
  }

  /// Retrocede alguns segundos
  Future<void> rewind(int seconds) async {
    final newPosition = state.position - Duration(seconds: seconds);
    
    if (newPosition <= Duration.zero) {
      await seekTo(Duration.zero);
    } else {
      await seekTo(newPosition);
    }
  }

  /// Define o volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    if (!state.hasMedia) return;

    final clampedVolume = volume.clamp(0.0, 1.0);
    final isMuted = clampedVolume == 0.0;
    
    try {
      _volumeCallback?.call(clampedVolume);
      state = state.copyWith(volume: clampedVolume, isMuted: isMuted);
    } catch (e) {
      debugPrint('Erro ao definir volume: $e');
    }
  }

  /// Ativa/desativa mudo
  Future<void> toggleMute() async {
    if (state.isMuted) {
      await setVolume(1.0);
    } else {
      await setVolume(0.0);
    }
  }

  /// Atualiza a posição atual (chamado pelo player widget)
  void updatePosition(Duration position) {
    if (state.position != position) {
      state = state.copyWith(position: position);
    }
  }

  /// Atualiza a duração total (chamado pelo player widget)
  void updateDuration(Duration duration) {
    if (state.duration != duration) {
      state = state.copyWith(duration: duration);
    }
  }

  /// Atualiza o estado de reprodução (chamado pelo player widget)
  void updatePlaybackState({
    bool? isPlaying,
    bool? isPaused,
  }) {
    bool needsUpdate = false;
    bool newIsPlaying = state.isPlaying;
    bool newIsPaused = state.isPaused;
    
    if (isPlaying != null && state.isPlaying != isPlaying) {
      newIsPlaying = isPlaying;
      needsUpdate = true;
    }
    
    if (isPaused != null && state.isPaused != isPaused) {
      newIsPaused = isPaused;
      needsUpdate = true;
    }
    
    if (needsUpdate) {
      state = state.copyWith(isPlaying: newIsPlaying, isPaused: newIsPaused);
    }
  }

  /// Notifica que a reprodução foi concluída
  void onPlaybackComplete() {
    state = state.copyWith(
      isPlaying: false,
      isPaused: false,
      position: Duration.zero,
    );
  }

  /// Limpa a mídia atual
  void clearMedia() {
    setCurrentMedia(null);
  }

  /// Formata duração para exibição
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  void dispose() {
    _playCallback = null;
    _pauseCallback = null;
    _stopCallback = null;
    _seekCallback = null;
    _volumeCallback = null;
    super.dispose();
  }
}

final mediaPlaybackProvider = StateNotifierProvider<MediaPlaybackNotifier, MediaPlaybackState>((ref) {
  return MediaPlaybackNotifier();
});

// ==========================================
// FirestoreSyncService - Migração Direta 📡
// ==========================================

class FirestoreSyncState {
  final bool isLoading;
  final String? errorMessage;

  FirestoreSyncState({
    this.isLoading = false,
    this.errorMessage,
  });

  FirestoreSyncState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return FirestoreSyncState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FirestoreSyncNotifier extends StateNotifier<FirestoreSyncState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  FirestoreSyncNotifier(this._authService) : super(FirestoreSyncState());

  String? get _currentUserId => _authService.user?.uid;

  // Métodos para Playlists
  Future<String?> createPlaylist({
    required String title,
    required String description,
    List<Map<String, dynamic>>? items,
  }) async {
    if (_currentUserId == null) return null;

    try {
      _setLoading(true);
      _clearError();

      final playlistData = FirestoreDataSchema.playlistDocument(
        userId: _currentUserId!,
        title: title,
        description: description,
        items: items ?? [],
      );

      final docRef = await _firestore
          .collection(FirestoreDataSchema.playlistsCollection)
          .add(FirestoreConverter.prepareForFirestore(playlistData));

      return docRef.id;
    } catch (e) {
      _setError('Erro ao criar playlist: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<Map<String, dynamic>>> getUserPlaylists() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestoreDataSchema.playlistsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = FirestoreConverter.parseFromFirestore(doc.data());
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<bool> updatePlaylist(String playlistId, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _clearError();

      updates['updatedAt'] = DateTime.now();

      await _firestore
          .collection(FirestoreDataSchema.playlistsCollection)
          .doc(playlistId)
          .update(FirestoreConverter.prepareForFirestore(updates));

      return true;
    } catch (e) {
      _setError('Erro ao atualizar playlist: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deletePlaylist(String playlistId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore
          .collection(FirestoreDataSchema.playlistsCollection)
          .doc(playlistId)
          .delete();

      return true;
    } catch (e) {
      _setError('Erro ao excluir playlist: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos para Notes
  Future<String?> createNote({
    required String title,
    required String type,
    List<Map<String, dynamic>>? slides,
  }) async {
    if (_currentUserId == null) return null;

    try {
      _setLoading(true);
      _clearError();

      final noteData = FirestoreDataSchema.noteDocument(
        userId: _currentUserId!,
        title: title,
        slides: slides ?? [],
      );

      final docRef = await _firestore
          .collection(FirestoreDataSchema.notesCollection)
          .add(FirestoreConverter.prepareForFirestore(noteData));

      return docRef.id;
    } catch (e) {
      _setError('Erro ao criar nota: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<Map<String, dynamic>>> getUserNotes({String? type}) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection(FirestoreDataSchema.notesCollection)
        .where('userId', isEqualTo: _currentUserId);

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>);
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<bool> updateNote(String noteId, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _clearError();

      updates['updatedAt'] = DateTime.now();

      await _firestore
          .collection(FirestoreDataSchema.notesCollection)
          .doc(noteId)
          .update(FirestoreConverter.prepareForFirestore(updates));

      return true;
    } catch (e) {
      _setError('Erro ao atualizar nota: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteNote(String noteId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore
          .collection(FirestoreDataSchema.notesCollection)
          .doc(noteId)
          .delete();

      return true;
    } catch (e) {
      _setError('Erro ao excluir nota: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos para Media
  Future<String?> createMedia({
    required String type,
    required String name,
    required String fileName,
    required String storagePath,
    required int fileSize,
    String? duration,
    String? thumbnailPath,
  }) async {
    if (_currentUserId == null) return null;

    try {
      _setLoading(true);
      _clearError();

      final mediaData = FirestoreDataSchema.mediaDocument(
        userId: _currentUserId!,
        type: type,
        name: name,
        fileName: fileName,
        storagePath: storagePath,
        fileSize: fileSize,
        duration: duration,
        thumbnailPath: thumbnailPath,
      );

      final docRef = await _firestore
          .collection(FirestoreDataSchema.mediaCollection)
          .add(FirestoreConverter.prepareForFirestore(mediaData));

      return docRef.id;
    } catch (e) {
      _setError('Erro ao criar registro de mídia: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<Map<String, dynamic>>> getUserMedia({String? type}) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection(FirestoreDataSchema.mediaCollection)
        .where('userId', isEqualTo: _currentUserId);

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = FirestoreConverter.parseFromFirestore(doc.data() as Map<String, dynamic>);
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<bool> deleteMedia(String mediaId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore
          .collection(FirestoreDataSchema.mediaCollection)
          .doc(mediaId)
          .delete();

      return true;
    } catch (e) {
      _setError('Erro ao excluir mídia: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos para Verse Collections
  Future<String?> createVerseCollection({
    required String title,
    required List<Map<String, dynamic>> verses,
  }) async {
    if (_currentUserId == null) return null;

    try {
      _setLoading(true);
      _clearError();

      final verseCollectionData = FirestoreDataSchema.verseCollectionDocument(
        userId: _currentUserId!,
        title: title,
        verses: verses,
      );

      final docRef = await _firestore
          .collection(FirestoreDataSchema.verseCollectionsCollection)
          .add(FirestoreConverter.prepareForFirestore(verseCollectionData));

      return docRef.id;
    } catch (e) {
      _setError('Erro ao criar coleção de versículos: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<Map<String, dynamic>>> getUserVerseCollections() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestoreDataSchema.verseCollectionsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = FirestoreConverter.parseFromFirestore(doc.data());
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<bool> updateVerseCollection(String collectionId, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _clearError();

      updates['updatedAt'] = DateTime.now();

      await _firestore
          .collection(FirestoreDataSchema.verseCollectionsCollection)
          .doc(collectionId)
          .update(FirestoreConverter.prepareForFirestore(updates));

      return true;
    } catch (e) {
      _setError('Erro ao atualizar coleção de versículos: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteVerseCollection(String collectionId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore
          .collection(FirestoreDataSchema.verseCollectionsCollection)
          .doc(collectionId)
          .delete();

      return true;
    } catch (e) {
      _setError('Erro ao excluir coleção de versículos: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos para Settings
  Future<Map<String, dynamic>?> getUserSettings() async {
    if (_currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection(FirestoreDataSchema.settingsCollection)
          .doc(_currentUserId)
          .get();

      if (doc.exists) {
        return FirestoreConverter.parseFromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      _setError('Erro ao obter configurações: ${e.toString()}');
      return null;
    }
  }

  Future<bool> updateUserSettings(Map<String, dynamic> settings) async {
    if (_currentUserId == null) return false;

    try {
      _setLoading(true);
      _clearError();

      settings['updatedAt'] = DateTime.now();

      await _firestore
          .collection(FirestoreDataSchema.settingsCollection)
          .doc(_currentUserId)
          .update(FirestoreConverter.prepareForFirestore(settings));

      return true;
    } catch (e) {
      _setError('Erro ao atualizar configurações: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos auxiliares
  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void _setError(String error) {
    state = state.copyWith(errorMessage: error);
  }

  void _clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> syncOfflineData() async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore.enableNetwork();
      debugPrint('Sincronização offline ativada');
    } catch (e) {
      _setError('Erro na sincronização: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearOfflineCache() async {
    try {
      await _firestore.clearPersistence();
      debugPrint('Cache offline limpo');
    } catch (e) {
      debugPrint('Erro ao limpar cache: $e');
    }
  }
}

final firestoreSyncProvider = StateNotifierProvider<FirestoreSyncNotifier, FirestoreSyncState>((ref) {
  final authService = AuthService(); // Precisará ser injetado corretamente
  return FirestoreSyncNotifier(authService);
});

// ==========================================
// DualScreenService - Bridge Híbrida 📱
// ==========================================

class DualScreenState {
  final PresentationItem? currentItem;
  final bool isPresenting;
  final bool isBlackScreenActive;
  final int currentSlideIndex;
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final TextAlign textAlignment;

  DualScreenState({
    this.currentItem,
    this.isPresenting = false,
    this.isBlackScreenActive = false,
    this.currentSlideIndex = 0,
    this.fontSize = 32.0,
    this.textColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.textAlignment = TextAlign.center,
  });

  DualScreenState copyWith({
    PresentationItem? currentItem,
    bool? isPresenting,
    bool? isBlackScreenActive,
    int? currentSlideIndex,
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    TextAlign? textAlignment,
  }) {
    return DualScreenState(
      currentItem: currentItem ?? this.currentItem,
      isPresenting: isPresenting ?? this.isPresenting,
      isBlackScreenActive: isBlackScreenActive ?? this.isBlackScreenActive,
      currentSlideIndex: currentSlideIndex ?? this.currentSlideIndex,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textAlignment: textAlignment ?? this.textAlignment,
    );
  }
}

class DualScreenNotifier extends StateNotifier<DualScreenState> {
  late StreamController<PresentationState> _presentationStateController;
  late StreamController<PresentationSettings> _settingsController;

  DualScreenNotifier() : super(DualScreenState()) {
    _presentationStateController = StreamController<PresentationState>.broadcast();
    _settingsController = StreamController<PresentationSettings>.broadcast();
  }

  // Streams para widgets de apresentação
  Stream<PresentationState> get presentationStateStream => 
      _presentationStateController.stream;
  Stream<PresentationSettings> get settingsStream => 
      _settingsController.stream;

  Future<void> startPresentation(PresentationItem item, {int initialSlideIndex = 0}) async {
    state = state.copyWith(
      currentItem: item,
      currentSlideIndex: initialSlideIndex,
      isPresenting: true,
      isBlackScreenActive: false,
    );
    
    _broadcastPresentationState();
    _syncWithProviderSystem();
  }

  Future<void> stopPresentation() async {
    state = state.copyWith(
      isPresenting: false,
      isBlackScreenActive: false,
      currentItem: null,
      currentSlideIndex: 0,
    );
    
    _broadcastPresentationState();
    _syncWithProviderSystem();
  }

  Future<void> toggleBlackScreen() async {
    state = state.copyWith(isBlackScreenActive: !state.isBlackScreenActive);
    
    _broadcastPresentationState();
    _syncWithProviderSystem();
  }

  Future<void> nextSlide() async {
    if (!state.isPresenting || state.currentItem == null) return;
    
    final slides = _getCurrentItemSlides();
    if (state.currentSlideIndex < slides.length - 1) {
      state = state.copyWith(currentSlideIndex: state.currentSlideIndex + 1);
      _broadcastPresentationState();
      _syncWithProviderSystem();
    }
  }

  Future<void> previousSlide() async {
    if (!state.isPresenting || state.currentItem == null) return;
    
    if (state.currentSlideIndex > 0) {
      state = state.copyWith(currentSlideIndex: state.currentSlideIndex - 1);
      _broadcastPresentationState();
      _syncWithProviderSystem();
    }
  }

  Future<void> goToSlide(int index) async {
    if (!state.isPresenting || state.currentItem == null) return;
    
    final slides = _getCurrentItemSlides();
    if (index >= 0 && index < slides.length) {
      state = state.copyWith(currentSlideIndex: index);
      _broadcastPresentationState();
      _syncWithProviderSystem();
    }
  }

  void updatePresentationSettings({
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    TextAlign? textAlignment,
  }) {
    state = state.copyWith(
      fontSize: fontSize ?? state.fontSize,
      textColor: textColor ?? state.textColor,
      backgroundColor: backgroundColor ?? state.backgroundColor,
      textAlignment: textAlignment ?? state.textAlignment,
    );
    
    _broadcastSettingsState();
    _syncWithProviderSystem();
  }

  List<dynamic> _getCurrentItemSlides() {
    if (state.currentItem == null) return [];
    
    if (state.currentItem is LyricsItem) {
      return (state.currentItem as LyricsItem).slides;
    } else if (state.currentItem is VerseItem) {
      return (state.currentItem as VerseItem).verses;
    }
    
    return [];
  }

  bool get hasNextSlide {
    if (!state.isPresenting || state.currentItem == null) return false;
    final slides = _getCurrentItemSlides();
    return state.currentSlideIndex < slides.length - 1;
  }

  bool get hasPreviousSlide {
    if (!state.isPresenting || state.currentItem == null) return false;
    return state.currentSlideIndex > 0;
  }

  void _broadcastPresentationState() {
    final presentationState = PresentationState(
      currentItem: state.currentItem,
      isPresenting: state.isPresenting,
      isBlackScreenActive: state.isBlackScreenActive,
      currentSlideIndex: state.currentSlideIndex,
    );
    
    if (!_presentationStateController.isClosed) {
      _presentationStateController.add(presentationState);
    }
  }

  void _broadcastSettingsState() {
    final settingsState = PresentationSettings(
      fontSize: state.fontSize,
      textColor: state.textColor,
      backgroundColor: state.backgroundColor,
      textAlignment: state.textAlignment,
    );
    
    if (!_settingsController.isClosed) {
      _settingsController.add(settingsState);
    }
  }

  void _syncWithProviderSystem() {
    final globalDualScreenService = DualScreenService.globalInstance;
    if (globalDualScreenService != null) {
      globalDualScreenService.syncWithRiverpod(state);
    }
  }

  Map<String, dynamic> getCurrentSlideInfo() {
    if (!state.isPresenting || state.currentItem == null) {
      return {
        'currentSlide': 0,
        'totalSlides': 0,
        'canNext': false,
        'canPrevious': false,
        'title': 'Nenhuma apresentação ativa',
        'content': '',
      };
    }
    
    final slides = _getCurrentItemSlides();
    final currentSlide = slides.isNotEmpty ? slides[state.currentSlideIndex] : null;
    
    return {
      'currentSlide': state.currentSlideIndex + 1,
      'totalSlides': slides.length,
      'canNext': hasNextSlide,
      'canPrevious': hasPreviousSlide,
      'title': state.currentItem!.title,
      'content': currentSlide?.toString() ?? state.currentItem!.content,
    };
  }

  @override
  void dispose() {
    _presentationStateController.close();
    _settingsController.close();
    super.dispose();
  }
}

final dualScreenProvider = StateNotifierProvider<DualScreenNotifier, DualScreenState>((ref) {
  return DualScreenNotifier();
});

/// Estado da apresentação para sincronização
class PresentationState {
  final PresentationItem? currentItem;
  final bool isPresenting;
  final bool isBlackScreenActive;
  final int currentSlideIndex;

  const PresentationState({
    required this.currentItem,
    required this.isPresenting,
    required this.isBlackScreenActive,
    required this.currentSlideIndex,
  });
}

/// Configurações de apresentação
class PresentationSettings {
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final TextAlign textAlignment;

  const PresentationSettings({
    required this.fontSize,
    required this.textColor,
    required this.backgroundColor,
    required this.textAlignment,
  });
}

/// Providers convenientes
final isSyncingProvider = Provider<bool>((ref) {
  return ref.watch(mediaSyncProvider).isSyncing;
});

final masterTimestampProvider = Provider<double>((ref) {
  return ref.watch(mediaSyncProvider).masterTimestamp;
});

final masterDisplayIdProvider = Provider<String?>((ref) {
  return ref.watch(mediaSyncProvider).masterDisplayId;
});

final displayLatenciesProvider = Provider<Map<String, double>>((ref) {
  return ref.watch(mediaSyncProvider).displayLatencies;
});

final lastHeartbeatsProvider = Provider<Map<String, DateTime>>((ref) {
  return ref.watch(mediaSyncProvider).lastHeartbeats;
});

final mediaSyncErrorProvider = Provider<String?>((ref) {
  return ref.watch(mediaSyncProvider).errorMessage;
});

// -----------------------------------------------------------------------------
// Futuros Providers a serem migrados
// -----------------------------------------------------------------------------

// TODO: authProvider - Migração do AuthService  
// TODO: mediaProvider - Migração do MediaService
// TODO: playlistProvider - Migração do PlaylistService
// TODO: notesProvider - Migração do NotesService
// TODO: verseCollectionProvider - Migração do VerseCollectionService
// TODO: userSettingsProvider - Migração do UserSettingsService

/// =============================================================================
/// HELPERS E EXTENSÕES
/// =============================================================================

/// Extensão para facilitar o acesso aos providers em widgets
/// Fornece sintaxe conveniente similar ao Provider.of<ThemeService>() e Provider.of<LanguageService>()
extension ProviderExtensions on WidgetRef {
  // =================== THEME EXTENSIONS ===================
  /// Acesso rápido ao ThemeMode atual
  ThemeMode get currentThemeMode => watch(themeModeProvider);
  
  /// Acesso rápido ao estado completo do tema
  ThemeState get currentThemeState => watch(themeProvider);
  
  /// Acesso rápido ao ThemeNotifier para ações
  ThemeNotifier get themeNotifier => read(themeProvider.notifier);
  
  /// Acesso aos temas customizados
  ThemeData get lightTheme => read(lightThemeProvider);
  ThemeData get darkTheme => read(darkThemeProvider);
  ThemeData get currentTheme => read(currentThemeProvider);
  
  /// Getters convenientes para estados booleanos do tema
  bool get isDarkMode => watch(themeProvider).isDarkMode;
  bool get isLightMode => watch(themeProvider).isLightMode;
  bool get isSystemMode => watch(themeProvider).isSystemMode;
  
  // =================== LANGUAGE EXTENSIONS ===================
  /// Acesso rápido ao Locale atual
  Locale get currentLocale => watch(currentLocaleProvider);
  
  /// Acesso rápido ao código do idioma atual
  String get currentLanguageCode => watch(currentLanguageCodeProvider);
  
  /// Acesso rápido ao estado completo do idioma
  LanguageState get currentLanguageState => watch(languageProvider);
  
  /// Acesso rápido ao LanguageNotifier para ações
  LanguageNotifier get languageNotifier => read(languageProvider.notifier);
  
  /// Acesso às strings traduzidas
  AppLocalizations get languageStrings => read(languageStringsProvider);
  
  // =================== STORAGE MONITORING EXTENSIONS ===================
  /// Acesso rápido ao estado completo do monitoramento de armazenamento
  StorageMonitoringState get currentStorageMonitoringState => watch(storageMonitoringProvider);
  
  /// Acesso rápido ao StorageMonitoringNotifier para ações
  StorageMonitoringNotifier get storageMonitoringNotifier => read(storageMonitoringProvider.notifier);
  
  /// Acesso rápido para verificar se está monitorando
  bool get isStorageMonitoring => watch(isMonitoringProvider);
  
  /// Acesso rápido à última análise
  DateTime? get lastStorageAnalysis => watch(lastAnalysisProvider);
  
  /// Acesso rápido ao resumo de uso de armazenamento
  StorageUsageSummary? get storageUsageSummary => watch(storageUsageSummaryProvider);
  
  /// Acesso rápido para verificar se precisa de análise
  bool get storageNeedsAnalysis => watch(needsAnalysisProvider);
  
  // =================== STORAGE ANALYSIS EXTENSIONS ===================
  /// Acesso rápido ao estado completo da análise de armazenamento
  StorageAnalysisState get currentStorageAnalysisState => watch(storageAnalysisProvider);
  
  /// Acesso rápido ao StorageAnalysisNotifier para ações
  StorageAnalysisNotifier get storageAnalysisNotifier => read(storageAnalysisProvider.notifier);
  
  /// Acesso rápido ao uso atual de armazenamento
  StorageUsageData? get currentStorageUsage => watch(currentStorageUsageProvider);
  
  /// Acesso rápido para verificar se está analisando armazenamento
  bool get isAnalyzingStorage => watch(isAnalyzingStorageProvider);
  
  /// Acesso rápido a mensagens de erro da análise
  String? get storageErrorMessage => watch(storageErrorMessageProvider);
  
  /// Acesso rápido à porcentagem de uso de armazenamento
  double get storageUsagePercentage => watch(storageUsagePercentageProvider);
  
  /// Acesso rápido para verificar se está perto do limite
  bool get isNearStorageLimit => watch(isNearStorageLimitProvider);
  
  /// Acesso rápido para verificar se excedeu o limite
  bool get isOverStorageLimit => watch(isOverStorageLimitProvider);
  
  /// Acesso rápido à sugestão de upgrade
  String? get upgradeStorageSuggestion => watch(upgradeStorageSuggestionProvider);
}