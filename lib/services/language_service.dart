import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instância global do LanguageService para bridge híbrida com Riverpod
LanguageService? _globalLanguageService;

/// Serviço para gerenciar idiomas da aplicação
class LanguageService with ChangeNotifier {
  static const String _languageKey = 'app_language';
  
  Locale _currentLocale = const Locale('pt', 'BR');
  
  LanguageService() {
    // Registrar esta instância globalmente para bridge híbrida
    _globalLanguageService = this;
  }
  
  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;
  
  /// Idiomas suportados
  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'), // Português
    Locale('en', 'US'), // English
    Locale('es', 'ES'), // Español
    Locale('ja', 'JP'), // 日本語
  ];

  /// Mapa de idiomas para exibição
  static const Map<String, String> languageNames = {
    'pt': 'Português',
    'en': 'English',
    'es': 'Español',
    'ja': '日本語',
  };

  /// Carrega o idioma salvo das preferências
  Future<void> loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      
      if (savedLanguage != null) {
        final locale = supportedLocales.firstWhere(
          (locale) => locale.languageCode == savedLanguage,
          orElse: () => const Locale('pt', 'BR'),
        );
        _currentLocale = locale;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar idioma: $e');
    }
  }

  /// Salva o idioma nas preferências
  Future<void> _saveLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _currentLocale.languageCode);
    } catch (e) {
      debugPrint('Erro ao salvar idioma: $e');
    }
  }

  /// Altera o idioma
  Future<void> setLanguage(String languageCode) async {
    final locale = supportedLocales.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => const Locale('pt', 'BR'),
    );
    
    if (_currentLocale != locale) {
      _currentLocale = locale;
      await _saveLanguage(); // Salvar primeiro
      notifyListeners(); // Notificar depois
    }
  }

  /// Instância singleton das traduções
  AppLocalizations get strings => AppLocalizations(_currentLocale.languageCode);
  
  /// Sincroniza com Riverpod - usado para bridge híbrida
  /// Este método é chamado quando o Riverpod muda o idioma
  void syncWithRiverpod(Locale newLocale) {
    debugPrint('🔄 [PROVIDER] Sincronizando com Riverpod: ${newLocale.languageCode}');
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      notifyListeners(); // Isso fará todos os Consumer<LanguageService> reagirem
    }
  }
  
  /// Função estática para acesso global à instância (bridge híbrida)
  static LanguageService? get globalInstance => _globalLanguageService;
}

/// Classe para gerenciar todas as traduções
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

  String get verses => _getValue({
    'pt': 'Versículos',
    'en': 'Verses',
    'es': 'Versículos',
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

  String get reference => _getValue({
    'pt': 'Referência',
    'en': 'Reference',
    'es': 'Referencia',
    'ja': '参照',
  });

  // =================== NAVIGATION STRINGS ===================
  String get home => _getValue({
    'pt': 'Início',
    'en': 'Home',
    'es': 'Inicio',
    'ja': 'ホーム',
  });

  String get playlist => _getValue({
    'pt': 'Playlist',
    'en': 'Playlist',
    'es': 'Playlist',
    'ja': 'プレイリスト',
  });

  String get notes => _getValue({
    'pt': 'Notas',
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
    'pt': 'Ajustes',
    'en': 'Settings',
    'es': 'Ajustes',
    'ja': '設定',
  });

  // =================== SETTINGS STRINGS ===================
  String get account => _getValue({
    'pt': 'Conta',
    'en': 'Account',
    'es': 'Cuenta',
    'ja': 'アカウント',
  });

  String get theme => _getValue({
    'pt': 'Tema',
    'en': 'Theme',
    'es': 'Tema',
    'ja': 'テーマ',
  });

  String get language => _getValue({
    'pt': 'Idioma',
    'en': 'Language',
    'es': 'Idioma',
    'ja': '言語',
  });

  String get appLanguage => _getValue({
    'pt': 'Idioma do aplicativo',
    'en': 'App language',
    'es': 'Idioma de la aplicación',
    'ja': 'アプリの言語',
  });

  String get lightTheme => _getValue({
    'pt': 'Tema claro',
    'en': 'Light theme',
    'es': 'Tema claro',
    'ja': 'ライトテーマ',
  });

  String get darkTheme => _getValue({
    'pt': 'Tema escuro',
    'en': 'Dark theme',
    'es': 'Tema oscuro',
    'ja': 'ダークテーマ',
  });

  String get systemTheme => _getValue({
    'pt': 'Seguir sistema',
    'en': 'System default',
    'es': 'Predeterminado del sistema',
    'ja': 'システム設定に従う',
  });

  String get selectTheme => _getValue({
    'pt': 'Selecionar tema',
    'en': 'Select theme',
    'es': 'Seleccionar tema',
    'ja': 'テーマを選択',
  });

  String get selectLanguage => _getValue({
    'pt': 'Selecionar idioma',
    'en': 'Select language',
    'es': 'Seleccionar idioma',
    'ja': '言語を選択',
  });

  String get storage => _getValue({
    'pt': 'Armazenamento',
    'en': 'Storage',
    'es': 'Almacenamiento',
    'ja': 'ストレージ',
  });

  String get storageInfo => _getValue({
    'pt': 'Informações de armazenamento',
    'en': 'Storage information',
    'es': 'Información de almacenamiento',
    'ja': 'ストレージ情報',
  });

  String get storageInformation => _getValue({
    'pt': 'Informações de armazenamento',
    'en': 'Storage information',
    'es': 'Información de almacenamiento',
    'ja': 'ストレージ情報',
  });

  String get storageStats => _getValue({
    'pt': 'Ver estatísticas de uso de espaço',
    'en': 'View storage usage statistics',
    'es': 'Ver estadísticas de uso de almacenamiento',
    'ja': 'ストレージ使用統計を表示',
  });

  String get enabledVersions => _getValue({
    'pt': 'Versões habilitadas',
    'en': 'Enabled versions',
    'es': 'Versiones habilitadas',
    'ja': '有効なバージョン',
  });

  String get manageBibleVersions => _getValue({
    'pt': 'Gerenciar versões da Bíblia',
    'en': 'Manage Bible versions',
    'es': 'Gestionar versiones de la Biblia',
    'ja': '聖書バージョンを管理',
  });

  String get cleanCache => _getValue({
    'pt': 'Limpar cache',
    'en': 'Clean cache',
    'es': 'Limpiar caché',
    'ja': 'キャッシュを削除',
  });

  String get clearCache => _getValue({
    'pt': 'Limpar cache',
    'en': 'Clear cache',
    'es': 'Limpiar caché',
    'ja': 'キャッシュをクリア',
  });

  String get removeThumbnails => _getValue({
    'pt': 'Remover thumbnails e arquivos temporários',
    'en': 'Remove thumbnails and temporary files',
    'es': 'Eliminar miniaturas y archivos temporales',
  });

  String get removeThumbnailsAndTempFiles => _getValue({
    'pt': 'Remover thumbnails e arquivos temporários',
    'en': 'Remove thumbnails and temporary files',
    'es': 'Eliminar miniaturas y archivos temporales',
  });

  String get secondScreen => _getValue({
    'pt': 'Segunda Tela',
    'en': 'Second Screen',
    'es': 'Segunda Pantalla',
  });

  String get enableSecondScreen => _getValue({
    'pt': 'Habilitar segunda tela',
    'en': 'Enable second screen',
    'es': 'Habilitar segunda pantalla',
  });

  String get enableExternalProjection => _getValue({
    'pt': 'Habilitar projeção em tela externa',
    'en': 'Enable external screen projection',
    'es': 'Habilitar proyección en pantalla externa',
  });

  String get enableExternalScreenProjection => _getValue({
    'pt': 'Habilitar projeção de tela externa',
    'en': 'Enable external screen projection',
    'es': 'Habilitar proyección de pantalla externa',
  });

  String get resolution => _getValue({
    'pt': 'Resolução',
    'en': 'Resolution',
    'es': 'Resolución',
  });

  String get projectionResolution => _getValue({
    'pt': 'Resolução da projeção',
    'en': 'Projection resolution',
    'es': 'Resolución de proyección',
  });

  String get fontSize => _getValue({
    'pt': 'Tamanho da fonte',
    'en': 'Font size',
    'es': 'Tamaño de fuente',
  });

  String get projectionTextSize => _getValue({
    'pt': 'Tamanho do texto na projeção',
    'en': 'Projection text size',
    'es': 'Tamaño del texto en proyección',
  });

  String get showLogo => _getValue({
    'pt': 'Mostrar logo',
    'en': 'Show logo',
    'es': 'Mostrar logo',
  });

  String get showChurchLogo => _getValue({
    'pt': 'Mostrar logo da igreja na projeção',
    'en': 'Show church logo in projection',
    'es': 'Mostrar logo de la iglesia en proyección',
  });

  String get showBackground => _getValue({
    'pt': 'Mostrar fundo',
    'en': 'Show background',
    'es': 'Mostrar fondo',
  });

  String get showBackgroundImage => _getValue({
    'pt': 'Mostrar imagem de fundo na projeção',
    'en': 'Show background image in projection',
    'es': 'Mostrar imagen de fondo en proyección',
  });

  // =================== CLOUD SYNC STRINGS ===================
  String get cloudSyncStorage => _getValue({
    'pt': 'Cloud Sync & Storage',
    'en': 'Cloud Sync & Storage',
    'es': 'Sincronización y Almacenamiento',
  });

  String get syncStatus => _getValue({
    'pt': 'Status da sincronização',
    'en': 'Sync status',
    'es': 'Estado de sincronización',
  });

  String get syncNow => _getValue({
    'pt': 'Sincronizar agora',
    'en': 'Sync now',
    'es': 'Sincronizar ahora',
  });

  String get forceSyncAllData => _getValue({
    'pt': 'Forçar sincronização de todos os dados',
    'en': 'Force sync all data',
    'es': 'Forzar sincronización de todos los datos',
  });

  String get backupSettings => _getValue({
    'pt': 'Configurações de backup',
    'en': 'Backup settings',
    'es': 'Configuración de respaldo',
  });

  String get manageCloudBackup => _getValue({
    'pt': 'Gerenciar backup automático na nuvem',
    'en': 'Manage automatic cloud backup',
    'es': 'Gestionar respaldo automático en la nube',
  });

  String get clearOfflineCacheTitle => _getValue({
    'pt': 'Limpar cache offline',
    'en': 'Clear offline cache',
    'es': 'Limpiar caché sin conexión',
  });

  String get removeOfflineData => _getValue({
    'pt': 'Remover dados offline salvos',
    'en': 'Remove saved offline data',
    'es': 'Eliminar datos sin conexión guardados',
  });

  String get signOut => _getValue({
    'pt': 'Sair da conta',
    'en': 'Sign out',
    'es': 'Cerrar sesión',
  });

  String get disconnectWorkOffline => _getValue({
    'pt': 'Desconectar e trabalhar offline',
    'en': 'Disconnect and work offline',
    'es': 'Desconectar y trabajar sin conexión',
  });

  String get makeLogin => _getValue({
    'pt': 'Fazer login',
    'en': 'Sign in',
    'es': 'Iniciar sesión',
  });

  String get connectToSyncCloud => _getValue({
    'pt': 'Conectar para sincronizar dados na nuvem',
    'en': 'Connect to sync data in the cloud',
    'es': 'Conectar para sincronizar datos en la nube',
  });

  String get connected => _getValue({
    'pt': 'Conectado',
    'en': 'Connected',
    'es': 'Conectado',
  });

  String get disconnected => _getValue({
    'pt': 'Desconectado',
    'en': 'Disconnected',
    'es': 'Desconectado',
  });

  String get localAs => _getValue({
    'pt': 'Local',
    'en': 'Local',
    'es': 'Local',
  });

  String get firebaseAs => _getValue({
    'pt': 'Firebase',
    'en': 'Firebase',
    'es': 'Firebase',
  });

  String get as => _getValue({
    'pt': 'como',
    'en': 'as',
    'es': 'como',
  });

  // =================== ACCOUNT/USER STRINGS ===================
  String get freePlan => _getValue({
    'pt': 'Free',
    'en': 'Free',
    'es': 'Gratuito',
  });

  String get limitedResources => _getValue({
    'pt': 'Recursos limitados',
    'en': 'Limited resources',
    'es': 'Recursos limitados',
  });

  String get unlimitedResources => _getValue({
    'pt': 'Recursos ilimitados',
    'en': 'Unlimited resources',
    'es': 'Recursos ilimitados',
  });

  String get upgrade => _getValue({
    'pt': 'Upgrade',
    'en': 'Upgrade',
    'es': 'Actualizar',
    'ja': 'アップグレード',
  });

  String get upgradeOnlineOnly => _getValue({
    'pt': 'Upgrade disponível apenas online',
    'en': 'Upgrade available online only',
    'es': 'Actualización disponible solo en línea',
  });

  String get plan => _getValue({
    'pt': 'Plano',
    'en': 'Plan',
    'es': 'Plan',
    'ja': 'プラン',
  });

  String get loadingUserData => _getValue({
    'pt': 'Carregando dados do usuário...',
    'en': 'Loading user data...',
    'es': 'Cargando datos del usuario...',
  });

  String get notConnected => _getValue({
    'pt': 'Não conectado',
    'en': 'Not connected',
    'es': 'No conectado',
  });

  String get loginToSyncData => _getValue({
    'pt': 'Faça login para sincronizar seus dados',
    'en': 'Log in to sync your data',
    'es': 'Inicie sesión para sincronizar sus datos',
  });

  String get login => _getValue({
    'pt': 'Login',
    'en': 'Login',
    'es': 'Iniciar sesión',
    'ja': 'ログイン',
  });

  String get localUser => _getValue({
    'pt': 'Usuário Local',
    'en': 'Local User',
    'es': 'Usuario Local',
  });

  String get noEmail => _getValue({
    'pt': 'Sem email',
    'en': 'No email',
    'es': 'Sin correo',
  });

  String get localModeOffline => _getValue({
    'pt': 'Modo Local (Offline)',
    'en': 'Local Mode (Offline)',
    'es': 'Modo Local (Sin conexión)',
  });

  String get firebaseModeOnline => _getValue({
    'pt': 'Modo Firebase (Online)',
    'en': 'Firebase Mode (Online)',
    'es': 'Modo Firebase (En línea)',
  });

  String get user => _getValue({
    'pt': 'Usuário',
    'en': 'User',
    'es': 'Usuario',
    'ja': 'ユーザー',
  });

  // =================== SHARE & ABOUT STRINGS ===================
  String get share => _getValue({
    'pt': 'Compartilhar',
    'en': 'Share',
    'es': 'Compartir',
    'ja': '共有',
  });

  String get shareThisApp => _getValue({
    'pt': 'Compartilhar este app',
    'en': 'Share this app',
    'es': 'Compartir esta aplicación',
  });

  String get recommendVersee => _getValue({
    'pt': 'Indicar o VERSEE para outros',
    'en': 'Recommend VERSEE to others',
    'es': 'Recomendar VERSEE a otros',
  });

  String get about => _getValue({
    'pt': 'Sobre',
    'en': 'About',
    'es': 'Acerca de',
    'ja': 'について',
  });

  String get aboutVersee => _getValue({
    'pt': 'Sobre o VERSEE',
    'en': 'About VERSEE',
    'es': 'Acerca de VERSEE',
  });

  String get versionDeveloperLicenses => _getValue({
    'pt': 'Versão, desenvolvedor e licenças',
    'en': 'Version, developer and licenses',
    'es': 'Versión, desarrollador y licencias',
  });

  // =================== DIALOG STRINGS ===================
  String get thisActionWillRemove => _getValue({
    'pt': 'Esta ação irá remover:',
    'en': 'This action will remove:',
    'es': 'Esta acción eliminará:',
  });

  String get allGeneratedThumbnails => _getValue({
    'pt': '• Todos os thumbnails gerados',
    'en': '• All generated thumbnails',
    'es': '• Todas las miniaturas generadas',
  });

  String get temporaryFiles => _getValue({
    'pt': '• Arquivos temporários',
    'en': '• Temporary files',
    'es': '• Archivos temporales',
  });

  String get metadataCache => _getValue({
    'pt': '• Cache de metadados',
    'en': '• Metadata cache',
    'es': '• Caché de metadatos',
  });

  String get thumbnailsWillBeRegenerated => _getValue({
    'pt': 'Os thumbnails serão regenerados automaticamente quando necessário.',
    'en': 'Thumbnails will be automatically regenerated when needed.',
    'es': 'Las miniaturas se regenerarán automáticamente cuando sea necesario.',
  });

  String get clear => _getValue({
    'pt': 'Limpar',
    'en': 'Clear',
    'es': 'Limpiar',
    'ja': 'クリア',
  });

  // =================== AUTH STRINGS ===================
  String get email => _getValue({
    'pt': 'Email',
    'en': 'Email',
    'es': 'Correo electrónico',
    'ja': 'メール',
  });

  String get password => _getValue({
    'pt': 'Senha',
    'en': 'Password',
    'es': 'Contraseña',
    'ja': 'パスワード',
  });

  String get signIn => _getValue({
    'pt': 'Entrar',
    'en': 'Sign In',
    'es': 'Iniciar sesión',
    'ja': 'サインイン',
  });

  String get signUp => _getValue({
    'pt': 'Criar conta',
    'en': 'Sign Up',
    'es': 'Registrarse',
    'ja': 'アカウント作成',
  });

  String get forgotPassword => _getValue({
    'pt': 'Esqueci a senha',
    'en': 'Forgot Password',
    'es': 'Olvidé la contraseña',
    'ja': 'パスワードを忘れた',
  });

  String get dontHaveAccount => _getValue({
    'pt': 'Não tem uma conta?',
    'en': "Don't have an account?",
    'es': '¿No tienes una cuenta?',
  });

  String get alreadyHaveAccount => _getValue({
    'pt': 'Já tem uma conta?',
    'en': 'Already have an account?',
    'es': '¿Ya tienes una cuenta?',
  });

  String get signInNow => _getValue({
    'pt': 'Faça login',
    'en': 'Sign in',
    'es': 'Iniciar sesión',
  });

  // =================== BIBLE SELECTION STRINGS ===================
  String get createNewSelection => _getValue({
    'pt': 'Criar Nova Seleção',
    'en': 'Create New Selection',
    'es': 'Crear Nueva Selección',
    'ja': '新しい選択を作成',
  });

  String get selectionInformation => _getValue({
    'pt': 'Informações da Seleção',
    'en': 'Selection Information',
    'es': 'Información de la Selección',
    'ja': '選択情報',
  });

  String get selectionTitle => _getValue({
    'pt': 'Título da Seleção',
    'en': 'Selection Title',
    'es': 'Título de la Selección',
    'ja': '選択タイトル',
  });

  String get selectionTitleHint => _getValue({
    'pt': 'Ex: Amor de Deus, Versículos de Fé...',
    'en': 'Ex: God\'s Love, Faith Verses...',
    'es': 'Ej: Amor de Dios, Versículos de Fe...',
  });

  String get descriptionOptional => _getValue({
    'pt': 'Descrição (opcional)',
    'en': 'Description (optional)',
    'es': 'Descripción (opcional)',
    'ja': '説明（オプション）',
  });

  String get descriptionHint => _getValue({
    'pt': 'Descreva o tema ou propósito desta seleção...',
    'en': 'Describe the theme or purpose of this selection...',
    'es': 'Describe el tema o propósito de esta selección...',
  });

  String get selectedVersesCount => _getValue({
    'pt': 'Versículos Selecionados',
    'en': 'Selected Verses',
    'es': 'Versículos Seleccionados',
    'ja': '選択された節',
  });

  String get dragToReorder => _getValue({
    'pt': 'Arraste para reordenar os versículos nos slides',
    'en': 'Drag to reorder verses in slides',
    'es': 'Arrastra para reordenar los versículos en las diapositivas',
  });

  String get presentationPreview => _getValue({
    'pt': 'Prévia da Apresentação',
    'en': 'Presentation Preview',
    'es': 'Vista Previa de la Presentación',
    'ja': 'プレゼンテーションプレビュー',
  });

  String get slidesWillBeCreated => _getValue({
    'pt': 'slides serão criados',
    'en': 'slides will be created',
    'es': 'diapositivas serán creadas',
  });

  String get eachVerseWillBeSlide => _getValue({
    'pt': 'Cada versículo será um slide separado',
    'en': 'Each verse will be a separate slide',
    'es': 'Cada versículo será una diapositiva separada',
  });

  String get canPresentInTab => _getValue({
    'pt': 'Você poderá apresentar na aba "Present"',
    'en': 'You can present in the "Present" tab',
    'es': 'Podrás presentar en la pestaña "Present"',
  });

  String get removeVerse => _getValue({
    'pt': 'Remover versículo',
    'en': 'Remove verse',
    'es': 'Eliminar versículo',
    'ja': '節を削除',
  });

  String get pleaseTitleError => _getValue({
    'pt': 'Por favor, insira um título para a seleção',
    'en': 'Please enter a title for the selection',
    'es': 'Por favor, ingresa un título para la selección',
  });

  String get atLeastOneVerseError => _getValue({
    'pt': 'A seleção deve conter pelo menos um versículo',
    'en': 'The selection must contain at least one verse',
    'es': 'La selección debe contener al menos un versículo',
  });

  String get savingSelection => _getValue({
    'pt': 'Salvando seleção...',
    'en': 'Saving selection...',
    'es': 'Guardando selección...',
  });

  String get selectionCreated => _getValue({
    'pt': 'Seleção Criada!',
    'en': 'Selection Created!',
    'es': '¡Selección Creada!',
    'ja': '選択が作成されました！',
  });

  String get savedSuccessfully => _getValue({
    'pt': 'foi salva com sucesso!',
    'en': 'was saved successfully!',
    'es': 'fue guardada exitosamente!',
  });

  String get whatWouldYouLikeToDo => _getValue({
    'pt': 'O que você gostaria de fazer agora?',
    'en': 'What would you like to do now?',
    'es': '¿Qué te gustaría hacer ahora?',
  });

  String get goBack => _getValue({
    'pt': 'Voltar',
    'en': 'Go Back',
    'es': 'Volver',
    'ja': '戻る',
  });

  String get viewInPlaylist => _getValue({
    'pt': 'Ver na Playlist',
    'en': 'View in Playlist',
    'es': 'Ver en Playlist',
    'ja': 'プレイリストで表示',
  });

  String get presentNow => _getValue({
    'pt': 'Apresentar Agora',
    'en': 'Present Now',
    'es': 'Presentar Ahora',
    'ja': '今すぐプレゼント',
  });

  String get presentTitle => _getValue({
    'pt': 'Apresentar',
    'en': 'Present',
    'es': 'Presentar',
    'ja': 'プレゼント',
  });

  String get howWouldYouLikeToPresent => _getValue({
    'pt': 'Como você gostaria de apresentar esta seleção?',
    'en': 'How would you like to present this selection?',
    'es': '¿Cómo te gustaría presentar esta selección?',
  });

  String get soloOneVerseAtTime => _getValue({
    'pt': '• Solo: Um versículo por vez',
    'en': '• Solo: One verse at a time',
    'es': '• Solo: Un versículo a la vez',
  });

  String get playlistAddToPlaylist => _getValue({
    'pt': '• Playlist: Adicionar a uma playlist',
    'en': '• Playlist: Add to a playlist',
    'es': '• Playlist: Agregar a una playlist',
  });

  String get presentationStartImmediately => _getValue({
    'pt': '• Apresentação: Iniciar imediatamente',
    'en': '• Presentation: Start immediately',
    'es': '• Presentación: Iniciar inmediatamente',
  });

  // =================== BIBLE PAGE STRINGS ===================
  String get saved => _getValue({
    'pt': 'Salvos',
    'en': 'Saved',
    'es': 'Guardados',
    'ja': '保存済み',
  });

  String get oldTestament => _getValue({
    'pt': 'Antigo Testamento',
    'en': 'Old Testament',
    'es': 'Antiguo Testamento',
    'ja': '旧約聖書',
  });

  String get newTestament => _getValue({
    'pt': 'Novo Testamento',
    'en': 'New Testament',
    'es': 'Nuevo Testamento',
    'ja': '新約聖書',
  });

  String get bibleVersions => _getValue({
    'pt': 'Versões da Bíblia',
    'en': 'Bible Versions',
    'es': 'Versiones de la Biblia',
    'ja': '聖書の版',
  });

  String get selectVersion => _getValue({
    'pt': 'Selecionar versão',
    'en': 'Select version',
    'es': 'Seleccionar versión',
    'ja': 'バージョンを選択',
  });

  String get searchVerses => _getValue({
    'pt': 'Pesquisar versículos',
    'en': 'Search verses',
    'es': 'Buscar versículos',
    'ja': '節を検索',
  });

  String get searchHint => _getValue({
    'pt': 'Digite palavras-chave...',
    'en': 'Type keywords...',
    'es': 'Escriba palabras clave...',
    'ja': 'キーワードを入力...',
  });

  String get noResults => _getValue({
    'pt': 'Nenhum resultado encontrado',
    'en': 'No results found',
    'es': 'No se encontraron resultados',
    'ja': '結果が見つかりません',
  });

  String get selectVerses => _getValue({
    'pt': 'Selecionar versículos',
    'en': 'Select verses',
    'es': 'Seleccionar versículos',
    'ja': '節を選択',
  });

  String get createSelection => _getValue({
    'pt': 'Criar seleção',
    'en': 'Create selection',
    'es': 'Crear selección',
    'ja': '選択を作成',
  });

  String get addToPlaylist => _getValue({
    'pt': 'Adicionar à playlist',
    'en': 'Add to playlist',
    'es': 'Agregar a playlist',
    'ja': 'プレイリストに追加',
  });

  // =================== LOGIN PAGE STRINGS ===================
  String get connectionIssues => _getValue({
    'pt': 'Problemas de conexão',
    'en': 'Connection issues',
    'es': 'Problemas de conexión',
  });

  String get doLogin => _getValue({
    'pt': 'Fazer login',
    'en': 'Sign in',
    'es': 'Iniciar sesión',
  });

  String get pleaseEnterEmail => _getValue({
    'pt': 'Por favor, insira seu email',
    'en': 'Please enter your email',
    'es': 'Por favor, ingresa tu correo electrónico',
  });

  String get pleaseEnterValidEmail => _getValue({
    'pt': 'Por favor, insira um email válido',
    'en': 'Please enter a valid email',
    'es': 'Por favor, ingresa un correo electrónico válido',
  });

  String get pleaseEnterPassword => _getValue({
    'pt': 'Por favor, insira sua senha',
    'en': 'Please enter your password',
    'es': 'Por favor, ingresa tu contraseña',
  });

  String get noAccount => _getValue({
    'pt': 'Não tem conta?',
    'en': 'Don\'t have an account?',
    'es': '¿No tienes cuenta?',
  });

  String get enterEmailFirst => _getValue({
    'pt': 'Digite o email primeiro',
    'en': 'Enter email first',
    'es': 'Ingresa el correo primero',
  });

  String get resetEmailSent => _getValue({
    'pt': 'Email de recuperação enviado',
    'en': 'Reset email sent',
    'es': 'Correo de recuperación enviado',
  });

  // =================== MEDIA PAGE STRINGS ===================
  String get cleanupInvalidFiles => _getValue({
    'pt': 'Limpar arquivos inválidos',
    'en': 'Clean up invalid files',
    'es': 'Limpiar archivos inválidos',
  });

  String get cleanupDescription => _getValue({
    'pt': 'Remover referências de arquivos que não existem mais',
    'en': 'Remove references to files that no longer exist',
    'es': 'Eliminar referencias de archivos que ya no existen',
  });

  String get continue_ => _getValue({
    'pt': 'Continuar',
    'en': 'Continue',
    'es': 'Continuar',
    'ja': '続ける',
  });

  String get audio => _getValue({
    'pt': 'Áudio',
    'en': 'Audio',
    'es': 'Audio',
    'ja': 'オーディオ',
  });

  String get videos => _getValue({
    'pt': 'Vídeos',
    'en': 'Videos',
    'es': 'Videos',
    'ja': 'ビデオ',
  });

  String get images => _getValue({
    'pt': 'Imagens',
    'en': 'Images',
    'es': 'Imágenes',
    'ja': '画像',
  });

  String get importingFiles => _getValue({
    'pt': 'Importando arquivos',
    'en': 'Importing files',
    'es': 'Importando archivos',
  });

  String get videoFiles => _getValue({
    'pt': 'Arquivos de vídeo',
    'en': 'Video files',
    'es': 'Archivos de video',
  });

  String get imageFiles => _getValue({
    'pt': 'Arquivos de imagem',
    'en': 'Image files',
    'es': 'Archivos de imagen',
  });

  String get addAudio => _getValue({
    'pt': 'Adicionar áudio',
    'en': 'Add audio',
    'es': 'Agregar audio',
  });

  String get addVideo => _getValue({
    'pt': 'Adicionar vídeo',
    'en': 'Add video',
    'es': 'Agregar video',
  });

  String get addImage => _getValue({
    'pt': 'Adicionar imagem',
    'en': 'Add image',
    'es': 'Agregar imagen',
  });

  String get audioImportedOn => _getValue({
    'pt': 'Áudio importado em',
    'en': 'Audio imported on',
    'es': 'Audio importado el',
  });

  String get videoImportedOn => _getValue({
    'pt': 'Vídeo importado em',
    'en': 'Video imported on',
    'es': 'Video importado el',
  });

  String get imageImportedOn => _getValue({
    'pt': 'Imagem importada em',
    'en': 'Image imported on',
    'es': 'Imagen importada el',
  });

  String get editAudio => _getValue({
    'pt': 'Editar áudio',
    'en': 'Edit audio',
    'es': 'Editar audio',
  });

  String get editVideo => _getValue({
    'pt': 'Editar vídeo',
    'en': 'Edit video',
    'es': 'Editar video',
  });

  String get editImage => _getValue({
    'pt': 'Editar imagem',
    'en': 'Edit image',
    'es': 'Editar imagen',
  });

  String get playAudio => _getValue({
    'pt': 'Reproduzir áudio',
    'en': 'Play audio',
    'es': 'Reproducir audio',
  });

  String get playVideo => _getValue({
    'pt': 'Reproduzir vídeo',
    'en': 'Play video',
    'es': 'Reproducir video',
  });

  String get viewImage => _getValue({
    'pt': 'Ver imagem',
    'en': 'View image',
    'es': 'Ver imagen',
  });

  String get selectFiles => _getValue({
    'pt': 'Selecionar arquivos',
    'en': 'Select files',
    'es': 'Seleccionar archivos',
  });

  String get deleteMedia => _getValue({
    'pt': 'Excluir mídia',
    'en': 'Delete media',
    'es': 'Eliminar medios',
  });

  String get confirmDelete => _getValue({
    'pt': 'Confirmar exclusão',
    'en': 'Confirm delete',
    'es': 'Confirmar eliminación',
  });

  String get actionCannotBeUndone => _getValue({
    'pt': 'Esta ação não pode ser desfeita',
    'en': 'This action cannot be undone',
    'es': 'Esta acción no se puede deshacer',
  });

  String get editTitle => _getValue({
    'pt': 'Editar título',
    'en': 'Edit title',
    'es': 'Editar título',
  });

  String get categoryUpdatedSuccess => _getValue({
    'pt': 'Categoria atualizada com sucesso',
    'en': 'Category updated successfully',
    'es': 'Categoría actualizada exitosamente',
  });

  String get errorUpdatingCategory => _getValue({
    'pt': 'Erro ao atualizar categoria',
    'en': 'Error updating category',
    'es': 'Error al actualizar categoría',
  });

  String get details => _getValue({
    'pt': 'Detalhes',
    'en': 'Details',
    'es': 'Detalles',
  });

  String get addToCategory => _getValue({
    'pt': 'Adicionar à categoria',
    'en': 'Add to category',
    'es': 'Agregar a categoría',
  });

  String get addToPlaylistMenu => _getValue({
    'pt': 'Adicionar à playlist',
    'en': 'Add to playlist',
    'es': 'Agregar a lista de reproducción',
  });

  String get selectCategory => _getValue({
    'pt': 'Selecionar categoria',
    'en': 'Select category',
    'es': 'Seleccionar categoría',
  });

  // =================== MEDIA VIEWER PAGE STRINGS ===================
  String get startPresentation => _getValue({
    'pt': 'Iniciar apresentação',
    'en': 'Start presentation',
    'es': 'Iniciar presentación',
  });

  String get fullscreen => _getValue({
    'pt': 'Tela cheia',
    'en': 'Fullscreen',
    'es': 'Pantalla completa',
  });

  String get previous => _getValue({
    'pt': 'Anterior',
    'en': 'Previous',
    'es': 'Anterior',
  });

  String get next => _getValue({
    'pt': 'Próximo',
    'en': 'Next',
    'es': 'Siguiente',
  });

  String get exitFullscreen => _getValue({
    'pt': 'Sair da tela cheia',
    'en': 'Exit fullscreen',
    'es': 'Salir de pantalla completa',
  });

  // =================== NOTES PAGE STRINGS ===================
  String get lyrics => _getValue({
    'pt': 'Letras',
    'en': 'Lyrics',
    'es': 'Letras',
    'ja': '歌詞',
  });

  String get notesOnly => _getValue({
    'pt': 'Apenas notas',
    'en': 'Notes only',
    'es': 'Solo notas',
    'ja': 'ノートのみ',
  });

  // =================== NOTE EDITOR STRINGS ===================
  String get title => _getValue({
    'pt': 'Título',
    'en': 'Title',
    'es': 'Título',
    'ja': 'タイトル',
  });

  String get titleHint => _getValue({
    'pt': 'Digite o título da nota...',
    'en': 'Enter note title...',
    'es': 'Ingresa el título de la nota...',
    'ja': 'ノートのタイトルを入力...',
  });

  String get titleRequired => _getValue({
    'pt': 'Título é obrigatório',
    'en': 'Title is required',
    'es': 'El título es obligatorio',
    'ja': 'タイトルは必須です',
  });


  String get preview => _getValue({
    'pt': 'Prévia',
    'en': 'Preview',
    'es': 'Vista previa',
    'ja': 'プレビュー',
  });

  String get addSlide => _getValue({
    'pt': 'Adicionar slide',
    'en': 'Add slide',
    'es': 'Añadir slide',
    'ja': 'スライドを追加',
  });

  String get addNewSlide => _getValue({
    'pt': 'Adicionar novo slide',
    'en': 'Add new slide',
    'es': 'Añadir nuevo slide',
    'ja': '新しいスライドを追加',
  });

  String get removeSlide => _getValue({
    'pt': 'Remover slide',
    'en': 'Remove slide',
    'es': 'Eliminar slide',
    'ja': 'スライドを削除',
  });

  String removeSlideConfirm(int slideNumber) => _getValue({
    'pt': 'Deseja remover o slide $slideNumber?',
    'en': 'Do you want to remove slide $slideNumber?',
    'es': '¿Deseas eliminar el slide $slideNumber?',
  });

  String get duplicateSlide => _getValue({
    'pt': 'Duplicar slide',
    'en': 'Duplicate slide',
    'es': 'Duplicar slide',
    'ja': 'スライドを複製',
  });

  String get slide => _getValue({
    'pt': 'Slide',
    'en': 'Slide',
    'es': 'Slide',
    'ja': 'スライド',
  });

  String get characters => _getValue({
    'pt': 'caracteres',
    'en': 'characters',
    'es': 'caracteres',
    'ja': '文字',
  });

  String get slideContentHint => _getValue({
    'pt': 'Digite o conteúdo do slide...',
    'en': 'Enter slide content...',
    'es': 'Ingresa el contenido del slide...',
    'ja': 'スライドのコンテンツを入力...',
  });

  String get slidePreview => _getValue({
    'pt': 'Prévia do slide',
    'en': 'Slide preview',
    'es': 'Vista previa del slide',
    'ja': 'スライドプレビュー',
  });

  String get textFormatting => _getValue({
    'pt': 'Formatação de texto',
    'en': 'Text formatting',
    'es': 'Formato de texto',
    'ja': 'テキスト書式',
  });

  String get background => _getValue({
    'pt': 'Fundo',
    'en': 'Background',
    'es': 'Fondo',
    'ja': '背景',
  });

  String get bold => _getValue({
    'pt': 'Negrito',
    'en': 'Bold',
    'es': 'Negrita',
    'ja': '太字',
  });

  String get italic => _getValue({
    'pt': 'Itálico',
    'en': 'Italic',
    'es': 'Cursiva',
    'ja': '斜体',
  });

  String get underline => _getValue({
    'pt': 'Sublinhado',
    'en': 'Underline',
    'es': 'Subrayado',
    'ja': '下線',
  });

  String get startCreating => _getValue({
    'pt': 'Comece a criar!',
    'en': 'Start creating!',
    'es': '¡Comienza a crear!',
  });

  String get tapAddSlide => _getValue({
    'pt': 'Toque em "Adicionar slide" para começar',
    'en': 'Tap "Add slide" to start',
    'es': 'Toca "Añadir slide" para empezar',
  });

  String get discardChanges => _getValue({
    'pt': 'Descartar alterações?',
    'en': 'Discard changes?',
    'es': '¿Descartar cambios?',
  });

  String get discardChangesConfirm => _getValue({
    'pt': 'Você tem alterações não salvas. Deseja descartá-las?',
    'en': 'You have unsaved changes. Do you want to discard them?',
    'es': 'Tienes cambios sin guardar. ¿Deseas descartarlos?',
  });

  String get discard => _getValue({
    'pt': 'Descartar',
    'en': 'Discard',
    'es': 'Descartar',
  });

  String editNote(String noteType) => _getValue({
    'pt': 'Editar $noteType',
    'en': 'Edit $noteType',
    'es': 'Editar $noteType',
  });

  String newNote(String noteType) => _getValue({
    'pt': 'Nova $noteType',
    'en': 'New $noteType',
    'es': 'Nueva $noteType',
  });

  String get noteSaved => _getValue({
    'pt': 'Nota salva com sucesso',
    'en': 'Note saved successfully',
    'es': 'Nota guardada exitosamente',
  });

  String get errorSaving => _getValue({
    'pt': 'Erro ao salvar',
    'en': 'Error saving',
    'es': 'Error al guardar',
  });

  String get atLeastOneSlide => _getValue({
    'pt': 'Adicione pelo menos um slide com conteúdo',
    'en': 'Add at least one slide with content',
    'es': 'Añade al menos un slide con contenido',
  });

  // =================== PLAYLIST ITEM MANAGER STRINGS ===================
  String get manage => _getValue({
    'pt': 'Gerenciar',
    'en': 'Manage',
    'es': 'Gestionar',
    'ja': '管理',
  });

  String get emptyPlaylist => _getValue({
    'pt': 'Playlist vazia',
    'en': 'Empty playlist',
    'es': 'Lista de reproducción vacía',
    'ja': '空のプレイリスト',
  });

  String get remove => _getValue({
    'pt': 'Remover',
    'en': 'Remove',
    'es': 'Eliminar',
    'ja': '削除',
  });

  String get removeItem => _getValue({
    'pt': 'Remover item',
    'en': 'Remove item',
    'es': 'Eliminar elemento',
    'ja': 'アイテムを削除',
  });

  // =================== PRESENTER PAGE STRINGS ===================
  String get presenter => _getValue({
    'pt': 'Apresentador',
    'en': 'Presenter',
    'es': 'Presentador',
    'ja': 'プレゼンター',
  });

  String get selectPlaylistMessage => _getValue({
    'pt': 'Selecione uma playlist',
    'en': 'Select a playlist',
    'es': 'Selecciona una lista de reproducción',
    'ja': 'プレイリストを選択',
  });

  String get editPlaylist => _getValue({
    'pt': 'Editar playlist',
    'en': 'Edit playlist',
    'es': 'Editar lista de reproducción',
    'ja': 'プレイリストを編集',
  });

  String get renamePlaylist => _getValue({
    'pt': 'Renomear playlist',
    'en': 'Rename playlist',
    'es': 'Renombrar lista de reproducción',
    'ja': 'プレイリスト名を変更',
  });

  String get manageItems => _getValue({
    'pt': 'Gerenciar itens',
    'en': 'Manage items',
    'es': 'Gestionar elementos',
    'ja': 'アイテムを管理',
  });

  String get deletePlaylist => _getValue({
    'pt': 'Excluir playlist',
    'en': 'Delete playlist',
    'es': 'Eliminar lista de reproducción',
    'ja': 'プレイリストを削除',
  });

  String get playlistName => _getValue({
    'pt': 'Nome da playlist',
    'en': 'Playlist name',
    'es': 'Nombre de la lista de reproducción',
    'ja': 'プレイリスト名',
  });

  // =================== EXTENSION METHODS AND FUNCTIONS ===================
  String itemsCountRecorder(int count) => _getValue({
    'pt': '$count ${count == 1 ? 'item' : 'itens'}',
    'en': '$count ${count == 1 ? 'item' : 'items'}',
    'es': '$count ${count == 1 ? 'elemento' : 'elementos'}',
  });

  String createNewPlaylistMessage(String name) => _getValue({
    'pt': 'Nova playlist "$name" criada',
    'en': 'New playlist "$name" created',
    'es': 'Nueva lista de reproducción "$name" creada',
  });

  String createNewPlaylistWithItemsMessage(int itemCount, String itemType) => _getValue({
    'pt': 'Criar nova playlist com $itemCount ${itemCount == 1 ? itemType : '${itemType}s'}',
    'en': 'Create new playlist with $itemCount ${itemCount == 1 ? itemType : '${itemType}s'}',
    'es': 'Crear nueva lista con $itemCount ${itemCount == 1 ? itemType : '${itemType}s'}',
  });

  String presentItemMessage(String title) => _getValue({
    'pt': 'Apresentando "$title"',
    'en': 'Presenting "$title"',
    'es': 'Apresentando "$title"',
  });

  String removeItemFromPlaylist(String title) => _getValue({
    'pt': 'Remover "$title" da playlist?',
    'en': 'Remove "$title" from playlist?',
    'es': '¿Eliminar "$title" de la lista de reproducción?',
  });

  String itemsCount(int count) => _getValue({
    'pt': '$count ${count == 1 ? 'item' : 'itens'}',
    'en': '$count ${count == 1 ? 'item' : 'items'}',
    'es': '$count ${count == 1 ? 'elemento' : 'elementos'}',
  });


  // Presenter Page
  String get confirmDeletePlaylist => _getValue({
    'pt': 'Confirmar exclusão da playlist',
    'en': 'Confirm delete playlist',
    'es': 'Confirmar eliminación de lista de reproducción',
  });

  String get deletePlaylistError => _getValue({
    'pt': 'Erro ao excluir playlist',
    'en': 'Error deleting playlist',
    'es': 'Error al eliminar lista de reproducción',
  });

  String get addSavedVerses => _getValue({
    'pt': 'Adicionar versículos salvos',
    'en': 'Add saved verses',
    'es': 'Agregar versículos guardados',
  });

  String get noSavedVerses => _getValue({
    'pt': 'Nenhum versículo salvo',
    'en': 'No saved verses',
    'es': 'No hay versículos guardados',
  });

  // Register Page  
  String get createAccount => _getValue({
    'pt': 'Criar conta',
    'en': 'Create account',
    'es': 'Crear cuenta',
  });

  String get fullName => _getValue({
    'pt': 'Nome completo',
    'en': 'Full name',
    'es': 'Nombre completo',
  });

  String get pleaseEnterFullName => _getValue({
    'pt': 'Por favor, insira seu nome completo',
    'en': 'Please enter your full name',
    'es': 'Por favor, ingresa tu nombre completo',
  });

  String get nameTooShort => _getValue({
    'pt': 'Nome muito curto',
    'en': 'Name too short',
    'es': 'Nombre muy corto',
  });

  String get pleaseEnterPasswordRegister => _getValue({
    'pt': 'Por favor, insira uma senha',
    'en': 'Please enter a password',
    'es': 'Por favor, ingresa una contraseña',
  });

  String get passwordTooShort => _getValue({
    'pt': 'Senha muito curta',
    'en': 'Password too short',
    'es': 'Contraseña muy corta',
  });

  String get confirmPassword => _getValue({
    'pt': 'Confirmar senha',
    'en': 'Confirm password',
    'es': 'Confirmar contraseña',
  });

  String get pleaseConfirmPassword => _getValue({
    'pt': 'Por favor, confirme sua senha',
    'en': 'Please confirm your password',
    'es': 'Por favor, confirma tu contraseña',
  });

  String get passwordsDoNotMatch => _getValue({
    'pt': 'As senhas não coincidem',
    'en': 'Passwords do not match',
    'es': 'Las contraseñas no coinciden',
  });

  // Media Folder Manager
  String get all => _getValue({
    'pt': 'Todos',
    'en': 'All',
    'es': 'Todos',
    'ja': 'すべて',
  });

  // Playlist Selection Dialog
  String get create => _getValue({
    'pt': 'Criar',
    'en': 'Create',
    'es': 'Crear',
    'ja': '作成',
  });

  String get newPlaylist => _getValue({
    'pt': 'Nova playlist',
    'en': 'New playlist',
    'es': 'Nueva lista de reproducción',
    'ja': '新しいプレイリスト',
  });

  String get playlistNameHint => _getValue({
    'pt': 'Digite o nome da playlist',
    'en': 'Enter playlist name',
    'es': 'Ingresa el nombre de la lista de reproducción',
    'ja': 'プレイリスト名を入力',
  });

  String get playlistDescription => _getValue({
    'pt': 'Descrição da playlist',
    'en': 'Playlist description',
    'es': 'Descripción de la lista de reproducción',
    'ja': 'プレイリストの説明',
  });

  String get chooseIcon => _getValue({
    'pt': 'Escolher ícone',
    'en': 'Choose icon',
    'es': 'Elegir ícono',
    'ja': 'アイコンを選択',
  });

  String get createNewPlaylist => _getValue({
    'pt': 'Criar nova playlist',
    'en': 'Create new playlist',
    'es': 'Crear nueva lista de reproducción',
    'ja': '新しいプレイリストを作成',
  });

  // =================== EXTENSION METHODS FOR MISSING FUNCTIONS ===================
  
  String itemsCountReorder(int count) => _getValue({
    'pt': '$count ${count == 1 ? 'item para reordenar' : 'itens para reordenar'}',
    'en': '$count ${count == 1 ? 'item to reorder' : 'items to reorder'}',
    'es': '$count ${count == 1 ? 'elemento para reordenar' : 'elementos para reordenar'}',
  });

  String deletePlaylistSuccess(String name) => _getValue({
    'pt': 'Playlist "$name" excluída com sucesso',
    'en': 'Playlist "$name" deleted successfully',
    'es': 'Lista de reproducción "$name" eliminada exitosamente',
  });

  String get addFirstContent => _getValue({
    'pt': 'Adicione o primeiro conteúdo à sua playlist',
    'en': 'Add the first content to your playlist',
    'es': 'Añade el primer contenido a tu lista de reproducción',
  });

  String get bibleVerse => _getValue({
    'pt': 'Versículo bíblico',
    'en': 'Bible verse',
    'es': 'Versículo bíblico',
  });

  String get noteSlashSermon => _getValue({
    'pt': 'Nota/Sermão',
    'en': 'Note/Sermon',
    'es': 'Nota/Sermón',
  });

  String get video => _getValue({
    'pt': 'Vídeo',
    'en': 'Video',
    'es': 'Vídeo',
    'ja': 'ビデオ',
  });

  String get image => _getValue({
    'pt': 'Imagem',
    'en': 'Image',
    'es': 'Imagen',
    'ja': '画像',
  });

  // =================== STORAGE PAGE STRINGS ===================
  
  String get storagePage => _getValue({
    'pt': 'Armazenamento',
    'en': 'Storage',
    'es': 'Almacenamiento',
    'ja': 'ストレージ',
  });

  String get analyzingStorage => _getValue({
    'pt': 'Analisando armazenamento...',
    'en': 'Analyzing storage...',
    'es': 'Analizando almacenamiento...',
    'ja': 'ストレージを分析中...',
  });

  String get errorLoadingStorage => _getValue({
    'pt': 'Erro ao carregar armazenamento',
    'en': 'Error loading storage',
    'es': 'Error al cargar almacenamiento',
    'ja': 'ストレージの読み込みエラー',
  });

  String get tryAgain => _getValue({
    'pt': 'Tentar novamente',
    'en': 'Try again',
    'es': 'Intentar de nuevo',
    'ja': '再試行',
  });

  String get noStorageData => _getValue({
    'pt': 'Nenhum dado de armazenamento',
    'en': 'No storage data',
    'es': 'No hay datos de almacenamiento',
    'ja': 'ストレージデータがありません',
  });

  String get storageUsage => _getValue({
    'pt': 'Uso de Armazenamento',
    'en': 'Storage Usage',
    'es': 'Uso de Almacenamiento',
    'ja': 'ストレージ使用量',
  });

  String get of => _getValue({
    'pt': 'de',
    'en': 'of',
    'es': 'de',
    'ja': 'の',
  });

  String get remaining => _getValue({
    'pt': 'Restante',
    'en': 'Remaining',
    'es': 'Restante',
    'ja': '残り',
  });

  String get storageBreakdown => _getValue({
    'pt': 'Distribuição do Armazenamento',
    'en': 'Storage Breakdown',
    'es': 'Desglose de Almacenamiento',
    'ja': 'ストレージの内訳',
  });

  String get detailedBreakdown => _getValue({
    'pt': 'Detalhamento por Categoria',
    'en': 'Detailed Breakdown',
    'es': 'Desglose Detallado',
    'ja': '詳細な内訳',
  });

  String get currentPlan => _getValue({
    'pt': 'Plano Atual',
    'en': 'Current Plan',
    'es': 'Plan Actual',
    'ja': '現在のプラン',
  });

  String get maxFiles => _getValue({
    'pt': 'Máximo de arquivos',
    'en': 'Max files',
    'es': 'Máximo de archivos',
    'ja': '最大ファイル数',
  });

  String get playlists => _getValue({
    'pt': 'Playlists',
    'en': 'Playlists',
    'es': 'Listas de reproducción',
    'ja': 'プレイリスト',
  });

  String get unlimited => _getValue({
    'pt': 'Ilimitado',
    'en': 'Unlimited',
    'es': 'Ilimitado',
    'ja': '無制限',
  });

  String get storageExceeded => _getValue({
    'pt': 'Armazenamento Excedido',
    'en': 'Storage Exceeded',
    'es': 'Almacenamiento Excedido',
    'ja': 'ストレージが超過しました',
  });

  String get storageAlmostFull => _getValue({
    'pt': 'Armazenamento Quase Cheio',
    'en': 'Storage Almost Full',
    'es': 'Almacenamiento Casi Lleno',
    'ja': 'ストレージがほぼ満容です',
  });

  String get upgradeToAccessFeatures => _getValue({
    'pt': 'Faça upgrade para continuar usando todos os recursos.',
    'en': 'Upgrade to continue using all features.',
    'es': 'Actualiza para continuar usando todas las funciones.',
  });

  String get considerUpgrading => _getValue({
    'pt': 'Considere fazer upgrade do seu plano para ter mais espaço.',
    'en': 'Consider upgrading your plan to get more space.',
    'es': 'Considera actualizar tu plan para obtener más espacio.',
  });

  String get upgradePlan => _getValue({
    'pt': 'Fazer Upgrade',
    'en': 'Upgrade Plan',
    'es': 'Actualizar Plan',
  });

  String get chooseNewPlan => _getValue({
    'pt': 'Escolha seu novo plano:',
    'en': 'Choose your new plan:',
    'es': 'Elige tu nuevo plan:',
  });

  String get cleanupFiles => _getValue({
    'pt': 'Limpar Arquivos',
    'en': 'Cleanup Files',
    'es': 'Limpiar Archivos',
  });

  String get refresh => _getValue({
    'pt': 'Atualizar',
    'en': 'Refresh',
    'es': 'Actualizar',
    'ja': '更新',
  });

  String get clean => _getValue({
    'pt': 'Limpar',
    'en': 'Clean',
    'es': 'Limpiar',
    'ja': 'クリーン',
  });

  String get letters => _getValue({
    'pt': 'Letras',
    'en': 'Letters',
    'es': 'Letras',
    'ja': '文字',
  });

  String get file => _getValue({
    'pt': 'arquivo',
    'en': 'file',
    'es': 'archivo',
    'ja': 'ファイル',
  });

  String get files => _getValue({
    'pt': 'arquivos',
    'en': 'files',
    'es': 'archivos',
    'ja': 'ファイル',
  });

  // =================== EMPTY STATES ===================
  String get noPlaylistsFound => _getValue({
    'pt': 'Nenhuma playlist encontrada',
    'en': 'No playlists found',
    'es': 'No se encontraron listas de reproducción',
    'ja': 'プレイリストが見つかりません',
  });

  String get noContentSelected => _getValue({
    'pt': 'Nenhum conteúdo selecionado',
    'en': 'No content selected',
    'es': 'Ningún contenido seleccionado',
    'ja': 'コンテンツが選択されていません',
  });

  String get noSlideSelected => _getValue({
    'pt': 'Nenhum slide selecionado',
    'en': 'No slide selected',
    'es': 'Ninguna diapositiva seleccionada',
    'ja': 'スライドが選択されていません',
  });

  String get noItemsFound => _getValue({
    'pt': 'Nenhum item encontrado',
    'en': 'No items found',
    'es': 'No se encontraron elementos',
    'ja': 'アイテムが見つかりません',
  });

  String get noSlidesFound => _getValue({
    'pt': 'Nenhum slide encontrado',
    'en': 'No slides found',
    'es': 'No se encontraron diapositivas',
    'ja': 'スライドが見つかりません',
  });

  String get noSlidesSaved => _getValue({
    'pt': 'Nenhum slide salvo',
    'en': 'No slides saved',
    'es': 'Ninguna diapositiva guardada',
    'ja': '保存されたスライドがありません',
  });

  String get noVerseFound => _getValue({
    'pt': 'Nenhum versículo encontrado',
    'en': 'No verse found',
    'es': 'No se encontró ningún versículo',
    'ja': '節が見つかりません',
  });

  String get noMediaFound => _getValue({
    'pt': 'Nenhuma mídia encontrada',
    'en': 'No media found',
    'es': 'No se encontraron medios',
    'ja': 'メディアが見つかりません',
  });

  String get noAudioFound => _getValue({
    'pt': 'Nenhum áudio encontrado',
    'en': 'No audio found',
    'es': 'No se encontró audio',
    'ja': 'オーディオが見つかりません',
  });

  String get noVideoFound => _getValue({
    'pt': 'Nenhum vídeo encontrado',
    'en': 'No video found',
    'es': 'No se encontró video',
    'ja': 'ビデオが見つかりません',
  });

  String get noImagesFound => _getValue({
    'pt': 'Nenhuma imagem encontrada',
    'en': 'No images found',
    'es': 'No se encontraron imágenes',
    'ja': '画像が見つかりません',
  });

  String get noNotesFound => _getValue({
    'pt': 'Nenhuma nota encontrada',
    'en': 'No notes found',
    'es': 'No se encontraron notas',
    'ja': 'ノートが見つかりません',
  });

  String get noLyricsFound => _getValue({
    'pt': 'Nenhuma letra encontrada',
    'en': 'No lyrics found',
    'es': 'No se encontraron letras',
    'ja': '歌詞が見つかりません',
  });

  String noResultsForQuery(String query) => _getValue({
    'pt': 'Nenhum resultado encontrado para "$query"',
    'en': 'No results found for "$query"',
    'es': 'No se encontraron resultados para "$query"',
  });

  String get createFirstPlaylist => _getValue({
    'pt': 'Crie sua primeira playlist',
    'en': 'Create your first playlist',
    'es': 'Crea tu primera lista de reproducción',
    'ja': '最初のプレイリストを作成',
  });

  String get createFirstNote => _getValue({
    'pt': 'Crie sua primeira nota',
    'en': 'Create your first note',
    'es': 'Crea tu primera nota',
    'ja': '最初のノートを作成',
  });

  String get addFirstMedia => _getValue({
    'pt': 'Adicione sua primeira mídia',
    'en': 'Add your first media',
    'es': 'Añade tu primer medio',
    'ja': '最初のメディアを追加',
  });

  String get noFileSelected => _getValue({
    'pt': 'Nenhum arquivo selecionado',
    'en': 'No file selected',
    'es': 'Ningún archivo seleccionado',
    'ja': 'ファイルが選択されていません',
  });

  String get startByCreating => _getValue({
    'pt': 'Comece criando seu primeiro item',
    'en': 'Start by creating your first item',
    'es': 'Comienza creando tu primer elemento',
    'ja': '最初のアイテムを作成して始めてください',
  });

  String get emptySlideContent => _getValue({
    'pt': 'Conteúdo do slide está vazio',
    'en': 'Slide content is empty',
    'es': 'El contenido de la diapositiva está vacío',
    'ja': 'スライドのコンテンツが空です',
  });

  // =================== DISPLAY SYSTEM STRINGS ===================
  
  /// Display Types
  String get displayMainWindow => _getValue({
    'pt': 'Janela Principal',
    'en': 'Main Window',
    'es': 'Ventana Principal',
    'ja': 'メインウィンドウ',
  });

  String get displayProjectionWindow => _getValue({
    'pt': 'Janela de Projeção',
    'en': 'Projection Window',
    'es': 'Ventana de Proyección',
    'ja': 'プロジェクションウィンドウ',
  });

  String get displaySecondaryTab => _getValue({
    'pt': 'Aba Secundária',
    'en': 'Secondary Tab',
    'es': 'Pestaña Secundaria',
    'ja': 'セカンダリタブ',
  });

  String get displayExternalMonitor => _getValue({
    'pt': 'Monitor Externo',
    'en': 'External Monitor',
    'es': 'Monitor Externo',
    'ja': '外部モニター',
  });

  String get displayChromecast => _getValue({
    'pt': 'Chromecast',
    'en': 'Chromecast',
    'es': 'Chromecast',
    'ja': 'クロームキャスト',
  });

  String get displayAirPlay => _getValue({
    'pt': 'AirPlay',
    'en': 'AirPlay',
    'es': 'AirPlay',
    'ja': 'エアプレイ',
  });

  /// Display States
  String get displayStateDetected => _getValue({
    'pt': 'Detectado',
    'en': 'Detected',
    'es': 'Detectado',
    'ja': '検出済み',
  });

  String get displayStateConnecting => _getValue({
    'pt': 'Conectando...',
    'en': 'Connecting...',
    'es': 'Conectando...',
    'ja': '接続中...',
  });

  String get displayStateConnected => _getValue({
    'pt': 'Conectado',
    'en': 'Connected',
    'es': 'Conectado',
    'ja': '接続済み',
  });

  String get displayStatePresenting => _getValue({
    'pt': 'Apresentando',
    'en': 'Presenting',
    'es': 'Presentando',
    'ja': 'プレゼンテーション中',
  });

  String get displayStateDisconnected => _getValue({
    'pt': 'Desconectado',
    'en': 'Disconnected',
    'es': 'Desconectado',
    'ja': '切断済み',
  });

  String get displayStateError => _getValue({
    'pt': 'Erro',
    'en': 'Error',
    'es': 'Error',
    'ja': 'エラー',
  });

  /// Display Actions
  String get displayConnect => _getValue({
    'pt': 'Conectar',
    'en': 'Connect',
    'es': 'Conectar',
    'ja': '接続',
  });

  String get displayDisconnect => _getValue({
    'pt': 'Desconectar',
    'en': 'Disconnect',
    'es': 'Desconectar',
    'ja': '切断',
  });

  String get displayStartPresentation => _getValue({
    'pt': 'Iniciar Apresentação',
    'en': 'Start Presentation',
    'es': 'Iniciar Presentación',
    'ja': 'プレゼンテーション開始',
  });

  String get displayStopPresentation => _getValue({
    'pt': 'Parar Apresentação',
    'en': 'Stop Presentation',
    'es': 'Detener Presentación',
    'ja': 'プレゼンテーション停止',
  });

  String get displayScanDevices => _getValue({
    'pt': 'Buscar Dispositivos',
    'en': 'Scan Devices',
    'es': 'Buscar Dispositivos',
    'ja': 'デバイスをスキャン',
  });

  String get displayRefresh => _getValue({
    'pt': 'Atualizar',
    'en': 'Refresh',
    'es': 'Actualizar',
    'ja': '更新',
  });

  String get displayTestConnection => _getValue({
    'pt': 'Testar Conexão',
    'en': 'Test Connection',
    'es': 'Probar Conexión',
    'ja': '接続テスト',
  });

  /// Display Settings
  String get displaySettings => _getValue({
    'pt': 'Configurações de Display',
    'en': 'Display Settings',
    'es': 'Configuración de Pantalla',
    'ja': 'ディスプレイ設定',
  });

  String get displayQuality => _getValue({
    'pt': 'Qualidade',
    'en': 'Quality',
    'es': 'Calidad',
    'ja': '品質',
  });

  String get displayAutoConnect => _getValue({
    'pt': 'Conectar Automaticamente',
    'en': 'Auto Connect',
    'es': 'Conectar Automáticamente',
    'ja': '自動接続',
  });

  String get displayRememberDevice => _getValue({
    'pt': 'Lembrar Dispositivo',
    'en': 'Remember Device',
    'es': 'Recordar Dispositivo',
    'ja': 'デバイスを記憶',
  });

  /// Display Messages
  String get displayWaitingPresentation => _getValue({
    'pt': 'Aguardando apresentação...',
    'en': 'Waiting for presentation...',
    'es': 'Esperando presentación...',
    'ja': 'プレゼンテーションを待機中...',
  });

  String get displayNoDevicesFound => _getValue({
    'pt': 'Nenhum dispositivo encontrado',
    'en': 'No devices found',
    'es': 'No se encontraron dispositivos',
    'ja': 'デバイスが見つかりません',
  });

  String get displayConnectionFailed => _getValue({
    'pt': 'Falha na conexão',
    'en': 'Connection failed',
    'es': 'Falló la conexión',
    'ja': '接続に失敗しました',
  });

  String get displayNoDisplayConnected => _getValue({
    'pt': 'Nenhum display conectado',
    'en': 'No display connected',
    'es': 'Ninguna pantalla conectada',
    'ja': 'ディスプレイが接続されていません',
  });

  String get displayPresentationFailed => _getValue({
    'pt': 'Falha ao iniciar apresentação',
    'en': 'Failed to start presentation',
    'es': 'Error al iniciar presentación',
    'ja': 'プレゼンテーションの開始に失敗しました',
  });

  /// Display Instructions
  String get displayInstructionOpenTab => _getValue({
    'pt': 'Abra uma nova aba e navegue para a URL de projeção',
    'en': 'Open a new tab and navigate to the projection URL',
    'es': 'Abre una nueva pestaña y navega a la URL de proyección',
    'ja': '新しいタブを開いてプロジェクションURLに移動してください',
  });

  String get displayInstructionPopupBlocked => _getValue({
    'pt': 'Pop-up bloqueado. Permita pop-ups para este site.',
    'en': 'Pop-up blocked. Please allow pop-ups for this site.',
    'es': 'Pop-up bloqueado. Permite ventanas emergentes para este sitio.',
    'ja': 'ポップアップがブロックされました。このサイトでポップアップを許可してください。',
  });

  String get displayInstructionSecondMonitor => _getValue({
    'pt': 'Arraste a janela para o monitor secundário',
    'en': 'Drag the window to the secondary monitor',
    'es': 'Arrastra la ventana al monitor secundario',
    'ja': 'ウィンドウをセカンダリモニターにドラッグしてください',
  });

  /// Display Capabilities
  String get displayCapabilityImages => _getValue({
    'pt': 'Imagens',
    'en': 'Images',
    'es': 'Imágenes',
    'ja': '画像',
  });

  String get displayCapabilityVideo => _getValue({
    'pt': 'Vídeo',
    'en': 'Video',
    'es': 'Video',
    'ja': 'ビデオ',
  });

  String get displayCapabilityAudio => _getValue({
    'pt': 'Áudio',
    'en': 'Audio',
    'es': 'Audio',
    'ja': 'オーディオ',
  });

  String get displayCapabilitySlideSync => _getValue({
    'pt': 'Sincronização de Slides',
    'en': 'Slide Sync',
    'es': 'Sincronización de Diapositivas',
    'ja': 'スライド同期',
  });

  String get displayCapabilityRemoteControl => _getValue({
    'pt': 'Controle Remoto',
    'en': 'Remote Control',
    'es': 'Control Remoto',
    'ja': 'リモートコントロール',
  });

  String get displayCapabilityHighQuality => _getValue({
    'pt': 'Alta Qualidade',
    'en': 'High Quality',
    'es': 'Alta Calidad',
    'ja': '高品質',
  });

  /// Display Setup
  String get displaySetupTitle => _getValue({
    'pt': 'Configurar Displays',
    'en': 'Setup Displays',
    'es': 'Configurar Pantallas',
    'ja': 'ディスプレイ設定',
  });

  String get displaySetupDescription => _getValue({
    'pt': 'Configure displays externos para apresentações',
    'en': 'Configure external displays for presentations',
    'es': 'Configurar pantallas externas para presentaciones',
    'ja': 'プレゼンテーション用の外部ディスプレイを設定',
  });

  String get displayAvailableDevices => _getValue({
    'pt': 'Dispositivos Disponíveis',
    'en': 'Available Devices',
    'es': 'Dispositivos Disponibles',
    'ja': '利用可能なデバイス',
  });

  String get displayConnectedDevices => _getValue({
    'pt': 'Dispositivos Conectados',
    'en': 'Connected Devices',
    'es': 'Dispositivos Conectados',
    'ja': '接続されたデバイス',
  });

  String get displaySavedDevices => _getValue({
    'pt': 'Dispositivos Salvos',
    'en': 'Saved Devices',
    'es': 'Dispositivos Guardados',
    'ja': '保存されたデバイス',
  });

  /// Presentation Controls
  String get presentationControls => _getValue({
    'pt': 'Controles de Apresentação',
    'en': 'Presentation Controls',
    'es': 'Controles de Presentación',
    'ja': 'プレゼンテーションコントロール',
  });

  String get presentationBlackScreen => _getValue({
    'pt': 'Tela Preta',
    'en': 'Black Screen',
    'es': 'Pantalla Negra',
    'ja': 'ブラックスクリーン',
  });

  String get presentationNextSlide => _getValue({
    'pt': 'Próximo Slide',
    'en': 'Next Slide',
    'es': 'Siguiente Diapositiva',
    'ja': '次のスライド',
  });

  String get presentationPreviousSlide => _getValue({
    'pt': 'Slide Anterior',
    'en': 'Previous Slide',
    'es': 'Diapositiva Anterior',
    'ja': '前のスライド',
  });

  String get presentationFullscreen => _getValue({
    'pt': 'Tela Cheia',
    'en': 'Fullscreen',
    'es': 'Pantalla Completa',
    'ja': 'フルスクリーン',
  });

  /// Troubleshooting
  String get displayTroubleshooting => _getValue({
    'pt': 'Solução de Problemas',
    'en': 'Troubleshooting',
    'es': 'Solución de Problemas',
    'ja': 'トラブルシューティング',
  });

  String get displayTroubleshootingHdmi => _getValue({
    'pt': 'Verifique se o cabo HDMI está conectado corretamente',
    'en': 'Check if HDMI cable is connected properly',
    'es': 'Verifica si el cable HDMI está conectado correctamente',
    'ja': 'HDMIケーブルが正しく接続されているか確認してください',
  });

  String get displayTroubleshootingNetwork => _getValue({
    'pt': 'Verifique se os dispositivos estão na mesma rede',
    'en': 'Check if devices are on the same network',
    'es': 'Verifica si los dispositivos están en la misma red',
    'ja': 'デバイスが同じネットワーク上にあるか確認してください',
  });

  String get displayTroubleshootingPermissions => _getValue({
    'pt': 'Verifique as permissões do aplicativo',
    'en': 'Check application permissions',
    'es': 'Verifica los permisos de la aplicación',
    'ja': 'アプリケーションの権限を確認してください',
  });

  // Additional display management strings
  String get displayManageConnection => _getValue({
    'pt': 'Gerenciar Conexão',
    'en': 'Manage Connection',
    'es': 'Gestionar Conexión',
    'ja': '接続を管理',
  });

  String get displayTestAndConfigure => _getValue({
    'pt': 'Testar e configurar display',
    'en': 'Test and configure display',
    'es': 'Probar y configurar pantalla',
    'ja': 'ディスプレイをテストして設定',
  });

  String get displaySetupDisplays => _getValue({
    'pt': 'Configurar Displays',
    'en': 'Setup Displays',
    'es': 'Configurar Pantallas',
    'ja': 'ディスプレイを設定',
  });

  String get displayConnectNewDisplay => _getValue({
    'pt': 'Conectar novo display',
    'en': 'Connect new display',
    'es': 'Conectar nueva pantalla',
    'ja': '新しいディスプレイを接続',
  });

  String get displaySyncStatus => _getValue({
    'pt': 'Status de Sincronização',
    'en': 'Sync Status',
    'es': 'Estado de Sincronización',
    'ja': '同期状態',
  });

  String get displaySyncActive => _getValue({
    'pt': 'Sincronização ativa',
    'en': 'Sync active',
    'es': 'Sincronización activa',
    'ja': '同期アクティブ',
  });

  String get displaySyncInactive => _getValue({
    'pt': 'Sincronização inativa',
    'en': 'Sync inactive',
    'es': 'Sincronización inactiva',
    'ja': '同期非アクティブ',
  });

  String get displayPresentationSettings => _getValue({
    'pt': 'Configurações de Apresentação',
    'en': 'Presentation Settings',
    'es': 'Configuraciones de Presentación',
    'ja': 'プレゼンテーション設定',
  });

  String get displayFontSizeColors => _getValue({
    'pt': 'Tamanho da fonte e cores',
    'en': 'Font size and colors',
    'es': 'Tamaño de fuente y colores',
    'ja': 'フォントサイズと色',
  });

  String get displayOpenTabNote => _getValue({
    'pt': 'Abra uma nova aba para projeção',
    'en': 'Open a new tab for projection',
    'es': 'Abrir nueva pestaña para proyección',
    'ja': '投影用の新しいタブを開く',
  });

  String get displayOpenTabInstruction => _getValue({
    'pt': 'Para usar o modo de projeção, abra uma nova aba do navegador',
    'en': 'To use projection mode, open a new browser tab',
    'es': 'Para usar el modo de proyección, abrir una nueva pestaña del navegador',
    'ja': '投影モードを使用するには、新しいブラウザタブを開いてください',
  });

  String get displayAdvancedSettings => _getValue({
    'pt': 'Configurações Avançadas',
    'en': 'Advanced Settings',
    'es': 'Configuraciones Avanzadas',
    'ja': '詳細設定',
  });

  String get displayAutoDiscoveryLatency => _getValue({
    'pt': 'Descoberta automática e latência',
    'en': 'Auto-discovery and latency',
    'es': 'Descubrimiento automático y latencia',
    'ja': '自動検出とレイテンシ',
  });

  String get displayImageLoadError => _getValue({
    'pt': 'Erro ao carregar imagem',
    'en': 'Error loading image',
    'es': 'Error al cargar imagen',
    'ja': '画像読み込みエラー',
  });

  String get displayMediaLoadError => _getValue({
    'pt': 'Erro ao carregar mídia',
    'en': 'Error loading media',
    'es': 'Error al cargar media',
    'ja': 'メディア読み込みエラー',
  });

  String get displayContentLoadError => _getValue({
    'pt': 'Erro ao carregar conteúdo',
    'en': 'Error loading content',
    'es': 'Error al cargar contenido',
    'ja': 'コンテンツ読み込みエラー',
  });

  String get displayUnknownContentType => _getValue({
    'pt': 'Tipo de conteúdo desconhecido',
    'en': 'Unknown content type',
    'es': 'Tipo de contenido desconocido',
    'ja': '不明なコンテンツタイプ',
  });

  String get displayProjectionConnected => _getValue({
    'pt': 'Projeção conectada',
    'en': 'Projection connected',
    'es': 'Proyección conectada',
    'ja': '投影接続済み',
  });

  String get displayProjectionReady => _getValue({
    'pt': 'Projeção pronta',
    'en': 'Projection ready',
    'es': 'Proyección lista',
    'ja': '投影準備完了',
  });

  String get displayLoadingContent => _getValue({
    'pt': 'Carregando conteúdo...',
    'en': 'Loading content...',
    'es': 'Cargando contenido...',
    'ja': 'コンテンツ読み込み中...',
  });

  String get displayLoadingImage => _getValue({
    'pt': 'Carregando imagem...',
    'en': 'Loading image...',
    'es': 'Cargando imagen...',
    'ja': '画像読み込み中...',
  });

  String get displayAwaitingPlayback => _getValue({
    'pt': 'Aguardando reprodução',
    'en': 'Awaiting playback',
    'es': 'Esperando reproducción',
    'ja': '再生待機中',
  });

  String get displayTabNote => _getValue({
    'pt': 'Nova aba necessária',
    'en': 'New tab required',
    'es': 'Nueva pestaña requerida',
    'ja': '新しいタブが必要',
  });

  String get displaySetupHelp => _getValue({
    'pt': 'Configure displays externos para apresentações profissionais. Conecte via HDMI, USB-C ou wireless.',
    'en': 'Configure external displays for professional presentations. Connect via HDMI, USB-C or wireless.',
    'es': 'Configure pantallas externas para presentaciones profesionales. Conecte vía HDMI, USB-C o inalámbrico.',
    'ja': 'プロフェッショナルなプレゼンテーション用に外部ディスプレイを設定します。HDMI、USB-C、またはワイヤレスで接続してください。',
  });

  String get displayFoundDisplays => _getValue({
    'pt': 'displays encontrados',
    'en': 'displays found',
    'es': 'pantallas encontradas',
    'ja': 'ディスプレイが見つかりました',
  });

  String get displayConnectExternal => _getValue({
    'pt': 'Conectar Display Externo',
    'en': 'Connect External Display',
    'es': 'Conectar Pantalla Externa',
    'ja': '外部ディスプレイを接続',
  });

  String get displaySelectDisplay => _getValue({
    'pt': 'Selecionar Display',
    'en': 'Select Display',
    'es': 'Seleccionar Pantalla',
    'ja': 'ディスプレイを選択',
  });

  String get ok => _getValue({
    'pt': 'OK',
    'en': 'OK',
    'es': 'OK',
    'ja': 'OK',
  });

  String get help => _getValue({
    'pt': 'Ajuda',
    'en': 'Help',
    'es': 'Ayuda',
    'ja': 'ヘルプ',
  });

  String get displaySetup => _getValue({
    'pt': 'Configuração de Displays',
    'en': 'Display Setup',
    'es': 'Configuración de Pantallas',
    'ja': 'ディスプレイ設定',
  });

  String get displayDiagnostics => _getValue({
    'pt': 'Diagnósticos',
    'en': 'Diagnostics',
    'es': 'Diagnósticos',
    'ja': '診断',
  });

  String get displayUnknown => _getValue({
    'pt': 'Desconhecido',
    'en': 'Unknown',
    'es': 'Desconocido',
    'ja': '不明',
  });

  String get displayNoConnectedDisplay => _getValue({
    'pt': 'Nenhum display conectado',
    'en': 'No connected display',
    'es': 'Ninguna pantalla conectada',
    'ja': '接続されたディスプレイなし',
  });

  String get displayAvailableDisplays => _getValue({
    'pt': 'displays disponíveis',
    'en': 'available displays',
    'es': 'pantallas disponibles',
    'ja': '利用可能なディスプレイ',
  });

  String get displayDisconnected => _getValue({
    'pt': 'Display desconectado',
    'en': 'Display disconnected',
    'es': 'Pantalla desconectada',
    'ja': 'ディスプレイが切断されました',
  });

  String get displayAvailable => _getValue({
    'pt': 'Disponíveis',
    'en': 'Available',
    'es': 'Disponibles',
    'ja': '利用可能',
  });

  String get displaySaved => _getValue({
    'pt': 'Salvos',
    'en': 'Saved',
    'es': 'Guardados',
    'ja': '保存済み',
  });

  String get displayAdvanced => _getValue({
    'pt': 'Avançado',
    'en': 'Advanced',
    'es': 'Avanzado',
    'ja': '詳細',
  });

  String get displayAutoDiscovery => _getValue({
    'pt': 'Descoberta Automática',
    'en': 'Auto Discovery',
    'es': 'Descubrimiento Automático',
    'ja': '自動検出',
  });

  String get displayEnableAutoDiscovery => _getValue({
    'pt': 'Habilitar descoberta automática',
    'en': 'Enable auto discovery',
    'es': 'Habilitar descubrimiento automático',
    'ja': '自動検出を有効にする',
  });

  String get displayAutoDiscoveryDesc => _getValue({
    'pt': 'Busca displays automaticamente a cada intervalo configurado',
    'en': 'Automatically searches for displays at configured intervals',
    'es': 'Busca pantallas automáticamente en intervalos configurados',
    'ja': '設定された間隔でディスプレイを自動検索します',
  });

  String get displayScanInterval => _getValue({
    'pt': 'Intervalo de Busca',
    'en': 'Scan Interval',
    'es': 'Intervalo de Búsqueda',
    'ja': 'スキャン間隔',
  });

  String get displayConnectionSettings => _getValue({
    'pt': 'Configurações de Conexão',
    'en': 'Connection Settings',
    'es': 'Configuraciones de Conexión',
    'ja': '接続設定',
  });

  String get displayRememberConnections => _getValue({
    'pt': 'Lembrar conexões',
    'en': 'Remember connections',
    'es': 'Recordar conexiones',
    'ja': '接続を記憶する',
  });

  String get displayRememberConnectionsDesc => _getValue({
    'pt': 'Salva displays conectados para reconexão automática',
    'en': 'Saves connected displays for automatic reconnection',
    'es': 'Guarda pantallas conectadas para reconexión automática',
    'ja': '自動再接続のため接続されたディスプレイを保存します',
  });

  String get displayAutoConnectDesc => _getValue({
    'pt': 'Conecta automaticamente aos displays salvos quando disponíveis',
    'en': 'Automatically connects to saved displays when available',
    'es': 'Se conecta automáticamente a pantallas guardadas cuando están disponibles',
    'ja': '利用可能時に保存されたディスプレイに自動接続します',
  });

  String get displaySystemInfo => _getValue({
    'pt': 'Informações do Sistema',
    'en': 'System Information',
    'es': 'Información del Sistema',
    'ja': 'システム情報',
  });

  String get displayPlatformCapabilities => _getValue({
    'pt': 'Capacidades da Plataforma',
    'en': 'Platform Capabilities',
    'es': 'Capacidades de la Plataforma',
    'ja': 'プラットフォーム機能',
  });

  String get displayViewDiagnostics => _getValue({
    'pt': 'Ver informações de diagnóstico detalhadas',
    'en': 'View detailed diagnostic information',
    'es': 'Ver información de diagnóstico detallada',
    'ja': '詳細な診断情報を表示',
  });

  String get displayDetected => _getValue({
    'pt': 'Detectado',
    'en': 'Detected',
    'es': 'Detectado',
    'ja': '検出済み',
  });

  String get displayNoDisplaysFoundDesc => _getValue({
    'pt': 'Certifique-se de que os displays estão conectados e ligados',
    'en': 'Make sure displays are connected and powered on',
    'es': 'Asegúrese de que las pantallas estén conectadas y encendidas',
    'ja': 'ディスプレイが接続され、電源が入っていることを確認してください',
  });

  String get displayInformation => _getValue({
    'pt': 'Informações',
    'en': 'Information',
    'es': 'Información',
    'ja': '情報',
  });

  String get displayType => _getValue({
    'pt': 'Tipo',
    'en': 'Type',
    'es': 'Tipo',
    'ja': 'タイプ',
  });

  String get displayState => _getValue({
    'pt': 'Estado',
    'en': 'State',
    'es': 'Estado',
    'ja': '状態',
  });

  String get displayCapabilities => _getValue({
    'pt': 'Recursos',
    'en': 'Capabilities',
    'es': 'Capacidades',
    'ja': '機能',
  });

  String get displayMetadata => _getValue({
    'pt': 'Metadados',
    'en': 'Metadata',
    'es': 'Metadatos',
    'ja': 'メタデータ',
  });

  String get displayConnecting => _getValue({
    'pt': 'Conectando...',
    'en': 'Connecting...',
    'es': 'Conectando...',
    'ja': '接続中...',
  });

  String get displayTest => _getValue({
    'pt': 'Testar',
    'en': 'Test',
    'es': 'Probar',
    'ja': 'テスト',
  });

  String get displayCalibrateLatency => _getValue({
    'pt': 'Calibrar Latência',
    'en': 'Calibrate Latency',
    'es': 'Calibrar Latencia',
    'ja': '遅延調整',
  });

  String get displayForget => _getValue({
    'pt': 'Esquecer',
    'en': 'Forget',
    'es': 'Olvidar',
    'ja': '削除',
  });

  String get displayScanning => _getValue({
    'pt': 'Escaneando...',
    'en': 'Scanning...',
    'es': 'Escaneando...',
    'ja': 'スキャン中...',
  });

  String get displayScanningDesc => _getValue({
    'pt': 'Procurando displays disponíveis',
    'en': 'Looking for available displays',
    'es': 'Buscando pantallas disponibles',
    'ja': '利用可能なディスプレイを探しています',
  });

  String get displayScanAgain => _getValue({
    'pt': 'Escanear Novamente',
    'en': 'Scan Again',
    'es': 'Escanear de Nuevo',
    'ja': '再スキャン',
  });

  String get displayNoSavedDisplays => _getValue({
    'pt': 'Nenhum Display Salvo',
    'en': 'No Saved Displays',
    'es': 'Sin Pantallas Guardadas',
    'ja': '保存されたディスプレイなし',
  });

  String get displayNoSavedDisplaysDesc => _getValue({
    'pt': 'Conecte-se a um display para salvá-lo',
    'en': 'Connect to a display to save it',
    'es': 'Conéctese a una pantalla para guardarla',
    'ja': 'ディスプレイに接続して保存してください',
  });

  String get displayScanForDevices => _getValue({
    'pt': 'Escanear Dispositivos',
    'en': 'Scan for Devices',
    'es': 'Escanear Dispositivos',
    'ja': 'デバイススキャン',
  });

  String get displayWebWindow => _getValue({
    'pt': 'Janela Web',
    'en': 'Web Window',
    'es': 'Ventana Web',
    'ja': 'ウェブウィンドウ',
  });

  String get displayExternal => _getValue({
    'pt': 'Display Externo',
    'en': 'External Display',
    'es': 'Pantalla Externa',
    'ja': '外部ディスプレイ',
  });

  String get displayConnected => _getValue({
    'pt': 'Conectado',
    'en': 'Connected',
    'es': 'Conectado',
    'ja': '接続済み',
  });

  String get displayPresenting => _getValue({
    'pt': 'Apresentando',
    'en': 'Presenting',
    'es': 'Presentando',
    'ja': 'プレゼンテーション中',
  });

  String get displayError => _getValue({
    'pt': 'Erro',
    'en': 'Error',
    'es': 'Error',
    'ja': 'エラー',
  });

  String get displayNoDisplaysFound => _getValue({
    'pt': 'Nenhum Display Encontrado',
    'en': 'No Displays Found',
    'es': 'No se Encontraron Pantallas',
    'ja': 'ディスプレイが見つかりません',
  });

}