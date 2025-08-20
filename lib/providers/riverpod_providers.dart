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
      
      return usage;
    } catch (e) {
      // FALLBACK: Se tudo falhar, cria dados demo para teste
      debugPrint('📈 [RIVERPOD] Erro na análise, usando dados demo: $e');
      final demoUsage = _createDemoData();
      
      state = state.copyWith(
        currentUsage: demoUsage,
        isAnalyzing: false,
      );
      
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
}

/// Enums e classes de dados migrados do StorageAnalysisService
enum StorageCategory {
  audio,
  video,
  images,
  notes,
  verses,
  playlists,
  letters,
}

class StorageUsageData {
  final int totalUsed;
  final int totalLimit;
  final String planType;
  final List<StorageCategoryData> categories;
  final DateTime lastUpdated;

  StorageUsageData({
    required this.totalUsed,
    required this.totalLimit,
    required this.planType,
    required this.categories,
    required this.lastUpdated,
  });

  double get usagePercentage => totalLimit > 0 ? (totalUsed / totalLimit) * 100 : 0.0;
  int get remainingBytes => totalLimit - totalUsed;
  bool get isNearLimit => usagePercentage > 80.0;
  bool get isOverLimit => usagePercentage > 100.0;
}

class StorageCategoryData {
  final StorageCategory category;
  final int size;
  final int fileCount;
  final Color color;
  final IconData icon;

  StorageCategoryData({
    required this.category,
    required this.size,
    required this.fileCount,
    required this.color,
    required this.icon,
  });

  double getPercentageOf(int totalSize) {
    if (totalSize == 0) return 0.0;
    return (size / totalSize) * 100;
  }
}

/// Provider principal da análise de armazenamento - substituto completo do StorageAnalysisService
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

/// Provider conveniente para verificar se está perto do limite
final isNearStorageLimitProvider = Provider<bool>((ref) {
  final notifier = ref.read(storageAnalysisProvider.notifier);
  return notifier.isNearLimit();
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