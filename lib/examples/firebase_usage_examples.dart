import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/auth_service.dart';
import 'package:versee/services/firestore_sync_service.dart';
import 'package:versee/services/realtime_data_service.dart';
import 'package:versee/services/data_sync_manager.dart';
import 'package:versee/services/typed_firebase_service.dart';
import 'package:versee/services/firebase_error_service.dart';
import 'package:versee/repositories/firebase_repository.dart';
import 'package:versee/utils/firebase_client.dart';
import 'package:versee/models/user_models.dart';
import 'package:versee/models/playlist_models.dart';
import 'package:versee/models/bible_models.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Exemplos de uso do Firebase no VERSEE
/// Este arquivo demonstra como usar os serviços Firebase implementados

class FirebaseUsageExamples extends StatelessWidget {
  const FirebaseUsageExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplos Firebase'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthExampleWidget(),
            SizedBox(height: 20),
            PlaylistExampleWidget(),
            SizedBox(height: 20),
            NotesExampleWidget(),
            SizedBox(height: 20),
            SyncStatusWidget(),
            SizedBox(height: 20),
            FirebaseClientExampleWidget(),
            SizedBox(height: 20),
            TypedFirebaseExampleWidget(),
          ],
        ),
      ),
    );
  }
}

/// Exemplo de autenticação
class AuthExampleWidget extends StatelessWidget {
  const AuthExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado de Autenticação',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Usuário: ${authService.user?.email ?? 'Não autenticado'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Status: ${authService.isAuthenticated ? 'Conectado' : 'Desconectado'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (authService.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: LinearProgressIndicator(),
                  ),
                if (authService.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Erro: ${authService.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Exemplo de operações com playlists
class PlaylistExampleWidget extends StatefulWidget {
  const PlaylistExampleWidget({super.key});

  @override
  State<PlaylistExampleWidget> createState() => _PlaylistExampleWidgetState();
}

class _PlaylistExampleWidgetState extends State<PlaylistExampleWidget> {
  final FirebaseRepository _repository = FirebaseRepository();

  Future<void> _createSamplePlaylist() async {
    try {
      final playlistId = await _repository.createPlaylist({
        'title': 'Playlist de Exemplo',
        'description': 'Criada automaticamente para demonstração',
        'items': [],
        'itemCount': 0,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playlist criada: $playlistId')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Playlists',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _createSamplePlaylist,
              child: const Text('Criar Playlist de Exemplo'),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _repository.getUserPlaylists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }
                
                final playlists = snapshot.data ?? [];
                return Text(
                  'Total de playlists: ${playlists.length}',
                  style: const TextStyle(color: Colors.white70),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Exemplo de operações com notas
class NotesExampleWidget extends StatefulWidget {
  const NotesExampleWidget({super.key});

  @override
  State<NotesExampleWidget> createState() => _NotesExampleWidgetState();
}

class _NotesExampleWidgetState extends State<NotesExampleWidget> {
  Future<void> _createSampleNote() async {
    final syncService = Provider.of<FirestoreSyncService>(context, listen: false);
    
    try {
      final noteId = await syncService.createNote(
        title: 'Nota de Exemplo',
        type: 'notes',
        slides: [
          {
            'order': 1,
            'content': 'Este é um slide de exemplo',
            'backgroundColor': '#000000',
            'textColor': '#FFFFFF',
            'fontSize': 'medium',
          }
        ],
      );
      
      if (mounted && noteId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nota criada: $noteId')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirestoreSyncService>(
      builder: (context, syncService, child) {
        return Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _createSampleNote,
                  child: const Text('Criar Nota de Exemplo'),
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: syncService.getUserNotes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    
                    if (snapshot.hasError) {
                      return Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                    }
                    
                    final notes = snapshot.data ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total de notas: ${notes.length}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            'Tipos: ${notes.map((n) => n['type']).toSet().join(', ')}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget para mostrar status de sincronização
class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FirestoreSyncService>(
      builder: (context, syncService, child) {
        return Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status de Sincronização',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      syncService.isLoading ? Icons.sync : Icons.sync_disabled,
                      color: syncService.isLoading ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      syncService.isLoading ? 'Sincronizando...' : 'Sincronização inativa',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                if (syncService.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Erro: ${syncService.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    await syncService.syncOfflineData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sincronização forçada executada')),
                      );
                    }
                  },
                  child: const Text('Forçar Sincronização'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Funções utilitárias para demonstrar uso do Repository
class FirebaseUsageUtils {
  static final FirebaseRepository _repository = FirebaseRepository();

  /// Exemplo de criação de dados completos
  static Future<void> createSampleData() async {
    try {
      // Criar uma playlist
      final playlistId = await _repository.createPlaylist({
        'title': 'Culto Dominical',
        'description': 'Playlist para o culto de domingo',
        'items': [],
        'itemCount': 0,
      });
      
      // Criar uma nota
      final noteId = await _repository.createNote({
        'title': 'Boas Vindas',
        'type': 'notes',
        'slides': [
          {
            'order': 1,
            'content': 'Sejam bem-vindos ao nosso culto!',
            'backgroundColor': '#000000',
            'textColor': '#FFFFFF',
            'fontSize': 'large',
          }
        ],
        'slideCount': 1,
      });
      
      // Criar uma coleção de versículos
      final verseCollectionId = await _repository.createVerseCollection({
        'title': 'Versículos sobre Amor',
        'verses': [
          {
            'book': 'João',
            'chapter': 3,
            'verse': 16,
            'text': 'Porque Deus amou o mundo de tal maneira que deu o seu Filho unigênito...',
            'version': 'NVI',
            'reference': 'João 3:16',
          }
        ],
        'verseCount': 1,
      });
      
      print('Dados criados com sucesso:');
      print('Playlist ID: $playlistId');
      print('Note ID: $noteId');
      print('Verse Collection ID: $verseCollectionId');
      
    } catch (e) {
      print('Erro ao criar dados: $e');
    }
  }

  /// Exemplo de sincronização offline
  static Future<void> demonstrateOfflineSync() async {
    try {
      // Habilitar persistência offline
      await _repository.enableOfflinePersistence();
      
      // Criar dados que serão sincronizados quando voltar online
      await createSampleData();
      
      // Simular desconexão
      await _repository.disableOfflinePersistence();
      print('Modo offline ativado');
      
      // Tentar criar mais dados (ficará em cache)
      await _repository.createNote({
        'title': 'Nota Offline',
        'type': 'notes',
        'slides': [],
        'slideCount': 0,
      });
      
      // Reconectar
      await _repository.enableOfflinePersistence();
      print('Sincronização reativada - dados serão enviados automaticamente');
      
    } catch (e) {
      print('Erro na demonstração offline: $e');
    }
  }

  /// Exemplo de operações em lote
  static Future<void> demonstrateBatchOperations() async {
    try {
      final batch = _repository.createBatch();
      
      // Adicionar múltiplas operações ao batch
      // Nota: Este é um exemplo conceitual - as operações reais precisariam ser implementadas
      
      await _repository.commitBatch(batch);
      print('Operações em lote executadas com sucesso');
      
    } catch (e) {
      print('Erro nas operações em lote: $e');
    }
  }

  /// Exemplo usando o novo Firebase Client
  static Future<void> demonstrateFirebaseClient() async {
    final client = FirebaseClient();
    
    try {
      // Criar uma playlist usando o client
      final playlistId = await client.playlists.create(
        title: 'Playlist via Client',
        description: 'Criada usando o Firebase Client unificado',
        items: [],
      );
      
      // Criar uma nota
      final noteId = await client.notes.create(
        title: 'Nota via Client',
        slides: [
          {
            'order': 1,
            'content': 'Exemplo de slide criado via client',
            'backgroundColor': '#000000',
            'textColor': '#FFFFFF',
          }
        ],
      );
      
      print('Dados criados via Firebase Client:');
      print('Playlist ID: $playlistId');
      print('Note ID: $noteId');
      
    } catch (e) {
      print('Erro no Firebase Client: $e');
    }
  }

  /// Exemplo usando o novo TypedFirebaseService
  static Future<void> demonstrateTypedFirebaseService() async {
    final typedService = TypedFirebaseService();
    
    try {
      // Criar usuário a partir do Firebase Auth
      final authUser = typedService.currentUser;
      if (authUser != null) {
        final userModel = UserModel.fromAuthUser(authUser);
        final created = await typedService.createUserDocument(userModel);
        print('Documento de usuário criado: $created');
      }
      
      // Criar playlist com modelo tipado
      final playlist = PlaylistModel(
        id: '', // Será gerado automaticamente
        userId: typedService.currentUserId ?? '',
        title: 'Playlist Tipada',
        description: 'Criada usando modelos tipados',
        iconCodePoint: 0xe5c3, // Icons.queue_music
        items: [
          PlaylistItemModel(
            order: 0,
            type: 'note',
            itemId: 'sample-note-id',
            title: 'Nota de Exemplo',
            metadata: {'duration': 30000}, // 30 segundos
          ),
        ],
        itemCount: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final playlistId = await typedService.createPlaylist(playlist);
      print('Playlist tipada criada: $playlistId');
      
      // Criar coleção de versículos
      final verseCollection = VerseCollection(
        id: '',
        title: 'Versículos sobre Fé',
        verses: [
          BibleVerse(
            reference: 'Hebreus 11:1',
            text: 'A fé é a certeza daquilo que esperamos...',
            version: 'NVI',
            book: 'Hebreus',
            chapter: 11,
            verse: 1,
          ),
        ],
        createdDate: DateTime.now(),
      );
      
      final verseCollectionId = await typedService.createVerseCollection(verseCollection);
      print('Coleção de versículos criada: $verseCollectionId');
      
    } catch (e) {
      final errorMessage = FirebaseErrorService.getErrorMessage(e);
      print('Erro tipado: $errorMessage');
    }
  }
}

/// Novo widget demonstrando o Firebase Client
class FirebaseClientExampleWidget extends StatefulWidget {
  const FirebaseClientExampleWidget({super.key});

  @override
  State<FirebaseClientExampleWidget> createState() => _FirebaseClientExampleWidgetState();
}

class _FirebaseClientExampleWidgetState extends State<FirebaseClientExampleWidget> {
  final FirebaseClient _client = FirebaseClient();
  bool _isLoading = false;

  Future<void> _testFirebaseClient() async {
    setState(() => _isLoading = true);
    
    try {
      await FirebaseUsageUtils.demonstrateFirebaseClient();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase Client testado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no teste: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<RealtimeDataService, DataSyncManager>(
      builder: (context, realtimeService, syncManager, child) {
        return Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Firebase Client Unificado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Status: ${_client.isInitialized ? "Inicializado" : "Não inicializado"}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 5),
                Text(
                  'Operações pendentes: ${syncManager.pendingOperations}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 5),
                Text(
                  'Última sincronização: ${syncManager.lastSyncTime?.toString() ?? "Nunca"}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testFirebaseClient,
                      child: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Testar Client'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => syncManager.forcSync(),
                      child: const Text('Forçar Sync'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (syncManager.syncError != null)
                  Text(
                    'Erro de sincronização: ${syncManager.syncError}',
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget demonstrando o TypedFirebaseService
class TypedFirebaseExampleWidget extends StatefulWidget {
  const TypedFirebaseExampleWidget({super.key});

  @override
  State<TypedFirebaseExampleWidget> createState() => _TypedFirebaseExampleWidgetState();
}

class _TypedFirebaseExampleWidgetState extends State<TypedFirebaseExampleWidget> {
  final TypedFirebaseService _typedService = TypedFirebaseService();
  bool _isLoading = false;
  String? _lastOperation;

  Future<void> _testTypedService() async {
    setState(() {
      _isLoading = true;
      _lastOperation = null;
    });
    
    try {
      await FirebaseUsageUtils.demonstrateTypedFirebaseService();
      setState(() => _lastOperation = 'Teste de serviço tipado executado com sucesso!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TypedFirebaseService testado com sucesso!')),
        );
      }
    } catch (e) {
      final errorMessage = FirebaseErrorService.getErrorMessage(e);
      setState(() => _lastOperation = 'Erro: $errorMessage');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $errorMessage')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testErrorHandling() async {
    setState(() {
      _isLoading = true;
      _lastOperation = null;
    });
    
    try {
      // Simular uma operação que pode gerar diferentes tipos de erro
      if (!_typedService.isAuthenticated) {
        throw FirebaseAuthException(code: 'unauthenticated', message: 'Usuário não autenticado');
      }
      
      // Tentar criar um documento com dados inválidos
      final playlist = PlaylistModel(
        id: '',
        userId: '', // UserId vazio deve causar erro
        title: '',
        description: '',
        iconCodePoint: 0xe5c3, // Icons.queue_music
        items: [],
        itemCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _typedService.createPlaylist(playlist);
      setState(() => _lastOperation = 'Teste de erro concluído (sem erro detectado)');
      
    } catch (e) {
      final errorMessage = FirebaseErrorService.getErrorMessage(e);
      final isNetwork = FirebaseErrorService.isNetworkError(e);
      final isPermission = FirebaseErrorService.isPermissionError(e);
      final isRecoverable = FirebaseErrorService.isRecoverableError(e);
      
      setState(() => _lastOperation = 'Erro capturado: $errorMessage\n'
          'Network: $isNetwork, Permission: $isPermission, Recoverable: $isRecoverable');
      
      // Log estruturado do erro
      FirebaseErrorService.logError('TypedFirebaseExampleWidget', e);
      
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Typed Firebase Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'Usuário: ${_typedService.currentUser?.email ?? 'Não autenticado'}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Autenticado: ${_typedService.isAuthenticated ? 'Sim' : 'Não'}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            
            // Streaming de playlists tipadas
            StreamBuilder<List<PlaylistModel>>(
              stream: _typedService.getUserPlaylists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Carregando playlists...', style: TextStyle(color: Colors.white70));
                }
                
                if (snapshot.hasError) {
                  final errorMessage = FirebaseErrorService.getErrorMessage(snapshot.error);
                  return Text('Erro: $errorMessage', style: const TextStyle(color: Colors.red));
                }
                
                final playlists = snapshot.data ?? [];
                return Text(
                  'Playlists tipadas: ${playlists.length}',
                  style: const TextStyle(color: Colors.white70),
                );
              },
            ),
            
            // Streaming de coleções de versículos
            StreamBuilder<List<VerseCollection>>(
              stream: _typedService.getUserVerseCollections(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Carregando versículos...', style: TextStyle(color: Colors.white70));
                }
                
                if (snapshot.hasError) {
                  final errorMessage = FirebaseErrorService.getErrorMessage(snapshot.error);
                  return Text('Erro: $errorMessage', style: const TextStyle(color: Colors.red));
                }
                
                final collections = snapshot.data ?? [];
                return Text(
                  'Coleções de versículos: ${collections.length}',
                  style: const TextStyle(color: Colors.white70),
                );
              },
            ),
            
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testTypedService,
                  child: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Testar Tipado'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testErrorHandling,
                  child: const Text('Testar Erros'),
                ),
              ],
            ),
            
            if (_lastOperation != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _lastOperation!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}