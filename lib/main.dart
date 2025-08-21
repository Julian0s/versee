import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:versee/theme.dart';
import 'package:versee/pages/presenter_page.dart';
import 'package:versee/pages/notes_page.dart';
import 'package:versee/pages/media_page.dart';
import 'package:versee/pages/bible_page.dart';
import 'package:versee/pages/settings_page.dart';
import 'package:versee/pages/auth_page.dart';
import 'package:versee/pages/login_page.dart';
import 'package:versee/pages/register_page.dart';
import 'package:versee/pages/landing/landing_page.dart';
import 'package:versee/pages/welcome/welcome_page.dart';
import 'package:versee/pages/legal/legal_page.dart';
import 'package:versee/pages/web_projection_page.dart';
// import 'package:versee/services/verse_collection_service.dart'; // MIGRADO para Riverpod
import 'package:versee/services/media_service.dart';
// import 'package:versee/services/hybrid_media_service.dart'; // MIGRADO para Riverpod
import 'package:versee/services/playlist_service.dart';
import 'package:versee/services/auth_service.dart';
import 'package:versee/services/firestore_sync_service.dart';
import 'package:versee/services/firebase_manager.dart';
import 'package:versee/services/realtime_data_service.dart';
import 'package:versee/services/data_sync_manager.dart';
import 'package:versee/services/dual_screen_service.dart';
import 'package:versee/services/media_playback_service.dart';
import 'package:versee/services/media_sync_service.dart';
import 'package:versee/services/display_factory.dart';
import 'package:versee/services/display_manager.dart';
import 'package:versee/services/notes_service.dart';
import 'package:versee/services/theme_service.dart';
import 'package:versee/services/language_service.dart';
// import 'package:versee/services/user_settings_service.dart'; // MIGRADO para Riverpod
// import 'package:versee/services/presentation_manager.dart'; // MIGRADO para Riverpod
// import 'package:versee/services/presentation_engine_service.dart'; // MIGRADO para Riverpod
import 'package:versee/services/storage_analysis_service.dart';
import 'package:versee/providers/riverpod_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar tratamento global de erros mais robusto
  FlutterError.onError = (FlutterErrorDetails details) {
    final errorString = details.exception.toString().toLowerCase();
    
    if (errorString.contains('_namespace') ||
        errorString.contains('unsupported operation') ||
        errorString.contains('firebase') ||
        errorString.contains('firestore') ||
        errorString.contains('permission') ||
        errorString.contains('platform')) {
      debugPrint('🔥 Erro capturado e tratado: ${details.exception}');
      debugPrint('🔥 Stack: ${details.stack}');
      // Log o erro sem crashar o app
      return;
    }
    // Para outros erros, usar o comportamento padrão
    FlutterError.presentError(details);
  };
  
  // Configurar tratamento de erros da plataforma
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔥 Erro da plataforma capturado: $error');
    debugPrint('🔥 Stack: $stack');
    return true; // Indica que o erro foi tratado
  };
  
  // Inicialização sequencial e robusta dos serviços
  final appServices = await initializeAppServices();
  
  // Envolver o app com ProviderScope do Riverpod
  // Isso permite que ambos Provider e Riverpod funcionem simultaneamente
  runApp(
    ProviderScope(
      child: VerseeApp(
        themeService: appServices.themeService,
        languageService: appServices.languageService,
        // userSettingsService: appServices.userSettingsService, // MIGRADO para Riverpod
        authService: appServices.authService,
        firebaseManager: appServices.firebaseManager,
        isOfflineMode: !appServices.firebaseInitialized,
      ),
    ),
  );
}

/// Container para os serviços inicializados
class AppServices {
  final ThemeService themeService;
  final LanguageService languageService;
  // final UserSettingsService userSettingsService; // MIGRADO para Riverpod
  final AuthService authService;
  final FirebaseManager firebaseManager;
  final bool firebaseInitialized;

  AppServices({
    required this.themeService,
    required this.languageService,
    // required this.userSettingsService, // MIGRADO para Riverpod
    required this.authService,
    required this.firebaseManager,
    required this.firebaseInitialized,
  });
}

/// Inicializa todos os serviços de forma sequencial e robusta
Future<AppServices> initializeAppServices() async {
  debugPrint('🚀 Iniciando inicialização dos serviços...');
  
  // ETAPA 1: Inicializar Firebase Manager com timeout
  final firebaseManager = FirebaseManager();
  bool firebaseInitialized = false;
  
  try {
    debugPrint('🔥 Inicializando Firebase...');
    await firebaseManager.initialize().timeout(
      const Duration(seconds: 15), // Mais tempo para Android
      onTimeout: () {
        debugPrint('⚠️ Firebase initialization timeout - continuando em modo offline');
        return;
      },
    );
    firebaseInitialized = true;
    debugPrint('✅ Firebase inicializado com sucesso');
  } catch (e) {
    debugPrint('❌ Erro na inicialização do Firebase: $e');
    debugPrint('📱 Aplicativo continuará em modo offline');
    firebaseInitialized = false;
  }
  
  // ETAPA 2: Inicializar serviços básicos (não dependem de Firebase)
  debugPrint('🎨 Inicializando serviços básicos...');
  final themeService = ThemeService();
  final languageService = LanguageService();
  // final userSettingsService = UserSettingsService(); // MIGRADO para Riverpod
  
  try {
    await Future.wait([
      themeService.loadTheme(),
      languageService.loadLanguage(),
      // userSettingsService.loadSettings(), // MIGRADO para Riverpod
    ], eagerError: false);
    debugPrint('✅ Serviços básicos inicializados');
  } catch (e) {
    debugPrint('⚠️ Erro ao carregar alguns serviços básicos: $e');
    // Continuar mesmo com erro - serviços básicos têm fallbacks
  }
  
  // ETAPA 3: Inicializar AuthService de forma segura
  debugPrint('🔐 Inicializando AuthService...');
  final authService = AuthService();
  
  try {
    if (firebaseInitialized) {
      await authService.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('⚠️ AuthService initialization timeout, continuando...');
          return false;
        },
      );
    } else {
      // Inicializar apenas em modo offline
      authService.initializeOfflineMode();
    }
    debugPrint('✅ AuthService inicializado');
  } catch (e) {
    debugPrint('⚠️ Erro na inicialização do AuthService: $e');
    // Continuar - AuthService tem fallback para modo local
  }
  
  debugPrint('🎉 Inicialização dos serviços concluída!');
  
  return AppServices(
    themeService: themeService,
    languageService: languageService,
    // userSettingsService: userSettingsService, // MIGRADO para Riverpod
    authService: authService,
    firebaseManager: firebaseManager,
    firebaseInitialized: firebaseInitialized,
  );
}


class VerseeApp extends StatelessWidget {
  final ThemeService themeService;
  final LanguageService languageService;
  // final UserSettingsService userSettingsService; // MIGRADO para Riverpod
  final AuthService authService;
  final FirebaseManager firebaseManager;
  final bool isOfflineMode;

  const VerseeApp({
    super.key,
    required this.themeService,
    required this.languageService,
    // required this.userSettingsService, // MIGRADO para Riverpod
    required this.authService,
    required this.firebaseManager,
    required this.isOfflineMode,
  });

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        // Serviços básicos sempre disponíveis
        provider.ChangeNotifierProvider.value(value: themeService),
        provider.ChangeNotifierProvider.value(value: languageService),
        provider.ChangeNotifierProvider.value(value: authService),
        provider.Provider.value(value: firebaseManager),
        provider.Provider.value(value: isOfflineMode),
        
        // UserSettingsService MIGRADO para Riverpod
        // provider.ChangeNotifierProvider.value(value: userSettingsService),
        
        // Serviços de mídia (sem dependências complexas)
        provider.ChangeNotifierProvider(create: (_) => MediaService()),
        // HybridMediaService MIGRADO para Riverpod
        // provider.ChangeNotifierProvider(create: (_) => HybridMediaService()),
        provider.ChangeNotifierProvider(create: (_) => MediaPlaybackService()),
        provider.ChangeNotifierProvider(create: (_) => PlaylistService()),
        provider.ChangeNotifierProvider(create: (_) => MediaSyncService()),
        
        // Serviços de conteúdo
        // VerseCollectionService MIGRADO para Riverpod
        // provider.ChangeNotifierProvider(create: (_) => VerseCollectionService()),
        provider.ChangeNotifierProvider(create: (_) => NotesService()),
        
        // Serviços de sincronização (inicializados depois)
        provider.ChangeNotifierProvider(
          create: (_) => isOfflineMode ? DataSyncManager() : DataSyncManager(),
        ),
        provider.ChangeNotifierProvider(
          create: (_) => isOfflineMode ? RealtimeDataService() : RealtimeDataService(),
        ),
        
        // Serviços Firebase (só se disponível)
        if (!isOfflineMode) ...[
          provider.ChangeNotifierProvider(
            create: (context) => FirestoreSyncService(
              provider.Provider.of<AuthService>(context, listen: false),
            ),
          ),
        ],
        
        // Display services (inicialização tardia e segura)
        provider.ChangeNotifierProvider<DisplayManager>(
          create: (_) => _createDisplayManagerSafely(),
        ),
        
        // Dual screen service (simples)
        provider.ChangeNotifierProvider(
          create: (context) => _createDualScreenServiceSafely(context),
        ),
        
        // Presentation services MIGRADOS para Riverpod
        // provider.ChangeNotifierProvider(create: (_) => PresentationEngineService()),
        // provider.ChangeNotifierProvider(create: (_) => PresentationManager()),
        
        // Serviços de análise
        provider.ChangeNotifierProvider(create: (_) => StorageAnalysisService()),
      ],
      child: _AppWithTheme(),
    );
  }
  
  /// Cria DisplayManager de forma segura
  DisplayManager _createDisplayManagerSafely() {
    try {
      final displayManager = DisplayFactory.instance;
      // Inicialização posterior, não no construtor
      Future.microtask(() {
        try {
          displayManager.initialize();
        } catch (e) {
          debugPrint('⚠️ Erro ao inicializar DisplayManager: $e');
        }
      });
      return displayManager;
    } catch (e) {
      debugPrint('⚠️ Erro ao criar DisplayManager: $e');
      // Retornar uma implementação dummy se falhar
      return DisplayFactory.instance;
    }
  }
  
  /// Cria DualScreenService de forma segura
  DualScreenService _createDualScreenServiceSafely(BuildContext context) {
    try {
      final dualScreenService = DualScreenService();
      // Configuração posterior, não no construtor
      Future.microtask(() {
        try {
          final mediaPlaybackService = provider.Provider.of<MediaPlaybackService>(context, listen: false);
          // final presentationManager = provider.Provider.of<PresentationManager>(context, listen: false); // MIGRADO para Riverpod
          // final presentationEngine = provider.Provider.of<PresentationEngineService>(context, listen: false); // MIGRADO para Riverpod
          
          dualScreenService.setMediaPlaybackService(mediaPlaybackService);
          // dualScreenService.setPresentationManager(presentationManager); // MIGRADO para Riverpod
          // dualScreenService.setPresentationEngine(presentationEngine); // MIGRADO para Riverpod
          dualScreenService.initialize();
        } catch (e) {
          debugPrint('⚠️ Erro ao configurar DualScreenService: $e');
        }
      });
      return dualScreenService;
    } catch (e) {
      debugPrint('⚠️ Erro ao criar DualScreenService: $e');
      return DualScreenService();
    }
  }
}

class _AppWithTheme extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // Usando Riverpod para tema
        final themeMode = ref.watch(themeModeProvider);
        final lightTheme = ref.watch(lightThemeProvider);
        final darkTheme = ref.watch(darkThemeProvider);
        
        // Usando Riverpod para idioma
        final currentLocale = ref.watch(currentLocaleProvider);
        
        return MaterialApp(
          title: 'VERSEE',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,          // ← Riverpod theme
          darkTheme: darkTheme,       // ← Riverpod theme
          themeMode: themeMode,       // ← Riverpod theme mode
          locale: currentLocale,                        // ← Riverpod locale
          supportedLocales: ref.read(supportedLocalesProvider), // ← Riverpod supportedLocales
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: kIsWeb ? const LandingPage() : const WelcomePage(),
          routes: {
            '/main': (context) => const MainNavigation(),
            '/auth': (context) => const AuthWrapper(),
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/landing': (context) => const LandingPage(),
            '/welcome': (context) => const WelcomePage(),
            '/legal': (context) => const LegalPage(),
            '/projection': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              final displayId = args?['display'] as String?;
              return WebProjectionPage(
                displayId: displayId ?? 'projection_window',
                mode: 'projection',
              );
            },
          },
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PresenterPage(),
    const NotesPage(),
    const MediaPage(),
    const BiblePage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return provider.Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          body: _pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            items: [
              BottomNavigationBarItem(
                  icon: const Icon(Icons.play_arrow), 
                  label: languageService.strings.playlist),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.library_books), 
                  label: languageService.strings.notes),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.video_library), 
                  label: languageService.strings.media),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.menu_book_outlined), 
                  label: languageService.strings.bible),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.settings), 
                  label: languageService.strings.settings)
            ],
          ),
        );
      },
    );
  }
}

/// Wrapper para verificar estado de autenticação
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return provider.Consumer<AuthService>(
      builder: (context, authService, child) {
        debugPrint('🔄 [AuthWrapper] Build - isLoading: ${authService.isLoading}, isAuthenticated: ${authService.isAuthenticated}');
        
        // Se está carregando, mostrar tela de loading
        if (authService.isLoading) {
          debugPrint('🔄 [AuthWrapper] Mostrando tela de loading');
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Se está autenticado, mostrar app principal
        if (authService.isAuthenticated) {
          debugPrint('🔄 [AuthWrapper] Usuário autenticado, mostrando app principal');
          return Column(
            children: [
              // Indicador de status do Firebase
              if (authService.isUsingLocalAuth)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  color: Colors.orange.withValues(alpha: 0.2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, color: Colors.orange, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: provider.Consumer<LanguageService>(
                          builder: (context, languageService, child) {
                            final offlineText = languageService.currentLanguageCode == 'pt' 
                                ? 'Modo Offline - Dados serão sincronizados quando a conexão for restaurada'
                                : languageService.currentLanguageCode == 'en'
                                ? 'Offline Mode - Data will be synced when connection is restored'
                                : 'Modo Sin Conexión - Los datos se sincronizarán cuando se restaure la conexión';
                            return Text(
                              offlineText,
                              style: TextStyle(color: Colors.orange, fontSize: 11),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              const Expanded(child: MainNavigation()),
            ],
          );
        }

        // Se não está autenticado, mostrar tela de login
        debugPrint('🔄 [AuthWrapper] Usuário não autenticado, mostrando tela de login');
        return const LoginPage();
      },
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: provider.Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final devText = languageService.currentLanguageCode == 'pt' 
                ? '(Em desenvolvimento)'
                : languageService.currentLanguageCode == 'en'
                ? '(Under development)'
                : '(En desarrollo)';
            return Text(
              '$title\n$devText',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            );
          },
        ),
      ),
    );
  }
}
