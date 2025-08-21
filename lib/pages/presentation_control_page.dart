import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/dual_screen_service.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/providers/riverpod_providers.dart';
import 'package:versee/services/display_manager.dart';
import 'package:versee/services/media_sync_service.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/models/media_models.dart';
import 'package:versee/models/display_models.dart' hide ConnectionState;
import 'package:versee/pages/projection_display_page.dart';

/// Página de controle da apresentação para o operador
/// Esta é a interface que o operador vê e usa para controlar a apresentação
class PresentationControlPage extends StatefulWidget {
  final PresentationItem? initialItem;
  final List<PresentationItem>? playlistItems;
  final String? playlistTitle;

  const PresentationControlPage({
    super.key,
    this.initialItem,
    this.playlistItems,
    this.playlistTitle,
  });

  @override
  State<PresentationControlPage> createState() => _PresentationControlPageState();
}

class _PresentationControlPageState extends State<PresentationControlPage> {
  late DualScreenService _dualScreenService;
  late DisplayManager _displayManager;
  late MediaSyncService _mediaSyncService;
  late LanguageService _languageService;
  final FocusNode _keyboardFocusNode = FocusNode();
  
  // Dados da sessão atual
  List<PresentationItem> _currentPlaylist = [];
  int _currentIndex = 0;
  String _sessionTitle = '';
  
  // Estado dos displays
  bool _isDisplaySetupOpen = false;

  @override
  void initState() {
    super.initState();
    _dualScreenService = Provider.of<DualScreenService>(context, listen: false);
    _displayManager = Provider.of<DisplayManager>(context, listen: false);
    _mediaSyncService = Provider.of<MediaSyncService>(context, listen: false);
    _languageService = Provider.of<LanguageService>(context, listen: false);
    _setupSession();
    
    // Foco para controles de teclado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  void _setupSession() {
    if (widget.initialItem != null) {
      // Modo item único
      _currentPlaylist = [widget.initialItem!];
      _sessionTitle = widget.initialItem!.title;
    } else if (widget.playlistItems != null) {
      // Modo playlist
      _currentPlaylist = widget.playlistItems!;
      _sessionTitle = widget.playlistTitle ?? 'Apresentação';
    }
    
    if (_currentPlaylist.isNotEmpty) {
      _dualScreenService.startPresentation(_currentPlaylist[0]);
      
      // No Android/iOS, abrir segunda tela em modo fullscreen
      if (!kIsWeb) {
        _openProjectionDisplay();
      }
    }
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: _buildControlAppBar(),
      body: Consumer<DualScreenService>(
        builder: (context, service, child) {
          return KeyboardListener(
            focusNode: _keyboardFocusNode,
            autofocus: true,
            onKeyEvent: _handleKeyboardEvent,
            child: Column(
              children: [
                // Status da apresentação
                _buildPresentationStatus(service),
                
                // Prévia do slide atual
                Expanded(
                  flex: 3,
                  child: _buildSlidePreview(service),
                ),
                
                // Controles principais
                _buildMainControls(service),
                
                // Controles de mídia (se o item atual for mídia)
                if (service.isCurrentItemMedia)
                  Consumer<MediaPlaybackService>(
                    builder: (context, mediaService, child) {
                      return _buildMediaControls(service, mediaService);
                    },
                  ),
                
                // Lista de slides (se playlist)
                if (_currentPlaylist.length > 1)
                  Expanded(
                    flex: 2,
                    child: _buildPlaylistView(),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildProjectorToggle(),
    );
  }

  PreferredSizeWidget _buildControlAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2A2A2A),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VERSEE Controle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _sessionTitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: _showSettingsDialog,
          tooltip: 'Configurações de Apresentação',
        ),
        IconButton(
          icon: const Icon(Icons.launch, color: Colors.white),
          onPressed: _openDisplaySetup,
          tooltip: 'Abrir Janela de Projeção',
        ),
      ],
    );
  }

  Widget _buildPresentationStatus(DualScreenService service) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: service.isPresenting ? Colors.red.shade900 : Colors.green.shade900,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            service.isPresenting ? Icons.play_circle_filled : Icons.pause_circle_filled,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.isPresenting ? 'APRESENTANDO' : 'PAUSADO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (_currentPlaylist.length > 1)
                  Text(
                    'Slide ${_currentIndex + 1} de ${_currentPlaylist.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (service.isBlackScreenActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'TELA PRETA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlidePreview(DualScreenService service) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Conteúdo do slide
            if (service.currentItem != null)
              _buildSlideContent(service.currentItem!, preview: true),
            
            // Overlay de tela preta
            if (service.isBlackScreenActive)
              Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(
                    Icons.visibility_off,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            
            // Indicador de prévia
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRÉVIA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideContent(PresentationItem item, {bool preview = false}) {
    final fontSize = preview ? 16.0 : 32.0;
    
    switch (item.type) {
      case ContentType.bible:
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.content,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                item.metadata?['reference'] ?? '',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: fontSize * 0.75,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      
      case ContentType.lyrics:
      case ContentType.notes:
        return Container(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              item.content,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      
      default:
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getContentTypeIcon(item.type),
                color: Colors.white,
                size: preview ? 32 : 64,
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildMainControls(DualScreenService service) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Slide anterior
          _buildControlButton(
            icon: Icons.skip_previous,
            label: 'Anterior (A)',
            onPressed: _canGoPrevious() ? _previousSlide : null,
          ),
          
          // Tela preta
          _buildControlButton(
            icon: service.isBlackScreenActive ? Icons.visibility : Icons.visibility_off,
            label: 'Tela Preta (B)',
            onPressed: () => service.toggleBlackScreen(),
            isActive: service.isBlackScreenActive,
          ),
          
          // Play/Pause
          _buildControlButton(
            icon: service.isPresenting ? Icons.pause : Icons.play_arrow,
            label: service.isPresenting ? 'Pausar (Space)' : 'Apresentar (Space)',
            onPressed: _togglePresentation,
            isPrimary: true,
          ),
          
          // Parar
          _buildControlButton(
            icon: Icons.stop,
            label: 'Parar (ESC)',
            onPressed: () => _stopPresentation(),
            color: Colors.red,
          ),
          
          // Próximo slide
          _buildControlButton(
            icon: Icons.skip_next,
            label: 'Próximo (D)',
            onPressed: _canGoNext() ? _nextSlide : null,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isActive = false,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: isPrimary ? 40 : 32,
          style: IconButton.styleFrom(
            backgroundColor: isActive 
              ? Colors.orange
              : (color ?? (isPrimary ? Colors.blue : Colors.grey.shade700)),
            foregroundColor: Colors.white,
            padding: EdgeInsets.all(isPrimary ? 20 : 16),
            disabledBackgroundColor: Colors.grey.shade800,
            disabledForegroundColor: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: onPressed != null ? Colors.white : Colors.grey.shade600,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlaylistView() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Slides da Apresentação',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _currentPlaylist.length,
              itemBuilder: (context, index) {
                final item = _currentPlaylist[index];
                final isActive = index == _currentIndex;
                
                return ListTile(
                  leading: Icon(
                    _getContentTypeIcon(item.type),
                    color: isActive ? Colors.blue : Colors.white70,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: isActive ? Colors.blue : Colors.white,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    _getContentTypeLabel(item.type),
                    style: TextStyle(
                      color: isActive ? Colors.blue.shade300 : Colors.white54,
                    ),
                  ),
                  selected: isActive,
                  selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                  onTap: () => _goToSlide(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectorToggle() {
    return Consumer<DisplayManager>(
      builder: (context, displayManager, child) {
        final hasConnectedDisplay = displayManager.hasConnectedDisplay;
        final isConnecting = displayManager.connectedDisplay?.state == DisplayConnectionState.connecting;
        
        return FloatingActionButton(
          onPressed: hasConnectedDisplay ? _showDisplayControls : _openDisplaySetup,
          backgroundColor: hasConnectedDisplay 
            ? Colors.green 
            : (isConnecting ? Colors.orange : Colors.grey),
          child: isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                hasConnectedDisplay ? Icons.cast_connected : Icons.cast,
                color: Colors.white,
              ),
          tooltip: hasConnectedDisplay 
            ? _languageService.strings.displayConnected
            : _languageService.strings.displayConnectExternal,
        );
      },
    );
  }

  // Métodos de controle
  void _togglePresentation() {
    if (_dualScreenService.isPresenting) {
      _dualScreenService.stopPresentation();
    } else if (_currentPlaylist.isNotEmpty) {
      _dualScreenService.startPresentation(_currentPlaylist[_currentIndex]);
    }
  }

  void _stopPresentation() {
    _dualScreenService.stopPresentation();
    Navigator.pop(context);
  }

  void _previousSlide() {
    if (_canGoPrevious()) {
      setState(() {
        _currentIndex--;
      });
      _dualScreenService.startPresentation(_currentPlaylist[_currentIndex]);
    }
  }

  void _nextSlide() {
    if (_canGoNext()) {
      setState(() {
        _currentIndex++;
      });
      _dualScreenService.startPresentation(_currentPlaylist[_currentIndex]);
    }
  }

  void _goToSlide(int index) {
    setState(() {
      _currentIndex = index;
    });
    _dualScreenService.startPresentation(_currentPlaylist[_currentIndex]);
  }

  bool _canGoPrevious() => _currentIndex > 0;
  bool _canGoNext() => _currentIndex < _currentPlaylist.length - 1;

  /// Abre a tela de projeção em fullscreen para Android/iOS
  void _openProjectionDisplay() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProjectionDisplayPage(),
        fullscreenDialog: true,
      ),
    );
  }

  void _handleKeyboardEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.keyD:
        if (_canGoNext()) _nextSlide();
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        if (_canGoPrevious()) _previousSlide();
        break;
      case LogicalKeyboardKey.keyB:
        _dualScreenService.toggleBlackScreen();
        break;
      case LogicalKeyboardKey.keyP:
        _togglePresentation();
        break;
      case LogicalKeyboardKey.escape:
        _stopPresentation();
        break;
    }
  }

  Future<void> _openDisplaySetup() async {
    if (_isDisplaySetupOpen) return;
    
    setState(() {
      _isDisplaySetupOpen = true;
    });
    
    try {
      // Scan for available displays
      final displays = await _displayManager.scanForDisplays();
      
      if (displays.isEmpty) {
        _showNoDisplaysFound();
        return;
      }
      
      // Show display selection dialog
      final selectedDisplay = await _showDisplaySelectionDialog(displays);
      
      if (selectedDisplay != null) {
        await _connectToDisplay(selectedDisplay);
      }
      
    } catch (e) {
      _showDisplayError('Erro ao escanear displays: $e');
    } finally {
      setState(() {
        _isDisplaySetupOpen = false;
      });
    }
  }
  
  Future<void> _connectToDisplay(ExternalDisplay display) async {
    try {
      final success = await _displayManager.connectToDisplay(display.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Conectado ao ${display.name}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Start presentation on connected display if we have content
        if (_currentPlaylist.isNotEmpty && _dualScreenService.isPresenting) {
          await _displayManager.startPresentation(_currentPlaylist[_currentIndex]);
        }
      } else {
        _showDisplayError('Falha ao conectar ao ${display.name}');
      }
    } catch (e) {
      _showDisplayError('Erro ao conectar: $e');
    }
  }
  
  void _showDisplayControls() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDisplayControlPanel(),
    );
  }
  
  Widget _buildDisplayControlPanel() {
    return Consumer2<DisplayManager, MediaSyncService>(
      builder: (context, displayManager, syncService, child) {
        final display = displayManager.connectedDisplay;
        if (display == null) return const SizedBox();
        
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.cast_connected,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          display.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getDisplayStatusText(display.state),
                          style: TextStyle(
                            color: _getDisplayStatusColor(display.state),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              
              const Divider(color: Colors.white24),
              
              // Sync status
              if (syncService.isSyncing) ...[
                Row(
                  children: [
                    const Icon(Icons.sync, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sincronização ativa',
                      style: const TextStyle(color: Colors.green, fontSize: 14),
                    ),
                    const Spacer(),
                    if (syncService.displayLatencies.isNotEmpty)
                      Text(
                        '${syncService.displayLatencies.values.first.toStringAsFixed(0)}ms',
                        style: const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _displayManager.testConnection(display.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Teste de conexão enviado')),
                        );
                      },
                      icon: const Icon(Icons.wifi_tethering),
                      label: const Text('Testar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _displayManager.disconnect();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Display desconectado')),
                        );
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Desconectar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<ExternalDisplay?> _showDisplaySelectionDialog(List<ExternalDisplay> displays) async {
    return showDialog<ExternalDisplay>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_languageService.strings.displaySelectDisplay),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: displays.length,
            itemBuilder: (context, index) {
              final display = displays[index];
              return ListTile(
                leading: Icon(_getDisplayTypeIcon(display.type)),
                title: Text(display.name),
                subtitle: Text(_getDisplayTypeLabel(display.type)),
                trailing: Icon(
                  _getDisplayStateIcon(display.state),
                  color: _getDisplayStatusColor(display.state),
                ),
                onTap: () => Navigator.pop(context, display),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_languageService.strings.cancel),
          ),
        ],
      ),
    );
  }
  
  void _showNoDisplaysFound() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_languageService.strings.displayNoDisplaysFound),
        content: Text(_languageService.strings.displayNoDisplaysFoundDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_languageService.strings.ok),
          ),
        ],
      ),
    );
  }
  
  void _showDisplayError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  IconData _getDisplayTypeIcon(DisplayType type) {
    switch (type) {
      case DisplayType.hdmi:
        return Icons.cable;
      case DisplayType.usbC:
        return Icons.usb;
      case DisplayType.chromecast:
        return Icons.cast;
      case DisplayType.airplay:
        return Icons.airplay;
      case DisplayType.webWindow:
        return Icons.web;
      default:
        return Icons.monitor;
    }
  }
  
  String _getDisplayTypeLabel(DisplayType type) {
    switch (type) {
      case DisplayType.hdmi:
        return 'HDMI';
      case DisplayType.usbC:
        return 'USB-C';
      case DisplayType.chromecast:
        return 'Chromecast';
      case DisplayType.airplay:
        return 'AirPlay';
      case DisplayType.webWindow:
        return 'Janela Web';
      default:
        return 'Display Externo';
    }
  }
  
  IconData _getDisplayStateIcon(DisplayConnectionState state) {
    switch (state) {
      case DisplayConnectionState.connected:
        return Icons.check_circle;
      case DisplayConnectionState.connecting:
        return Icons.sync;
      case DisplayConnectionState.detected:
        return Icons.visibility;
      case DisplayConnectionState.error:
        return Icons.error;
      default:
        return Icons.help;
    }
  }
  
  String _getDisplayStatusText(DisplayConnectionState state) {
    switch (state) {
      case DisplayConnectionState.connected:
        return 'Conectado';
      case DisplayConnectionState.connecting:
        return 'Conectando...';
      case DisplayConnectionState.presenting:
        return 'Apresentando';
      case DisplayConnectionState.detected:
        return 'Detectado';
      case DisplayConnectionState.error:
        return 'Erro';
      default:
        return 'Desconhecido';
    }
  }
  
  Color _getDisplayStatusColor(DisplayConnectionState state) {
    switch (state) {
      case DisplayConnectionState.connected:
      case DisplayConnectionState.presenting:
        return Colors.green;
      case DisplayConnectionState.connecting:
        return Colors.orange;
      case DisplayConnectionState.detected:
        return Colors.blue;
      case DisplayConnectionState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações de Apresentação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.format_size),
              title: const Text('Tamanho da Fonte'),
              subtitle: Slider(
                value: _dualScreenService.fontSize,
                min: 16,
                max: 64,
                divisions: 12,
                label: '${_dualScreenService.fontSize.round()}',
                onChanged: (value) {
                  _dualScreenService.updatePresentationSettings(fontSize: value);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Cor do Texto'),
              trailing: CircleAvatar(
                backgroundColor: _dualScreenService.textColor,
              ),
              onTap: () {
                // Implementar seletor de cor
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // Widget _buildMediaControls(DualScreenService dualScreenService, MediaPlaybackService mediaService) { // MIGRADO
  Widget _buildMediaControls(DualScreenService dualScreenService, dynamic mediaService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          // Informações da mídia
          Row(
            children: [
              Icon(
                _getMediaIcon(mediaService.currentMedia?.type),
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mediaService.currentMediaInfo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mediaService.playbackStatus,
                      style: TextStyle(
                        color: _getStatusColor(mediaService.playbackStatus),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Barra de progresso (para áudio/vídeo)
          if (mediaService.currentMedia?.type != MediaContentType.image && mediaService.duration > Duration.zero)
            Column(
              children: [
                Slider(
                  value: mediaService.progress.clamp(0.0, 1.0),
                  onChanged: (value) async {
                    await dualScreenService.mediaPlaybackService?.seekToPercentage(value);
                  },
                  activeColor: Colors.blue,
                  inactiveColor: Colors.grey,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mediaService.formatDuration(mediaService.position),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      mediaService.formatDuration(mediaService.duration),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          
          // Controles de reprodução
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Voltar 10s
              if (mediaService.currentMedia?.type != MediaContentType.image)
                IconButton(
                  onPressed: () async {
                    await dualScreenService.mediaPlaybackService?.rewind(10);
                  },
                  icon: const Icon(Icons.replay_10),
                  color: Colors.white,
                  tooltip: 'Voltar 10s',
                ),
              
              // Play/Pause
              if (mediaService.currentMedia?.type != MediaContentType.image)
                IconButton(
                  onPressed: () async {
                    await dualScreenService.toggleMediaPlayPause();
                  },
                  icon: Icon(mediaService.isPlaying ? Icons.pause : Icons.play_arrow),
                  color: Colors.white,
                  iconSize: 32,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.all(12),
                  ),
                  tooltip: mediaService.isPlaying ? 'Pausar' : 'Reproduzir',
                ),
              
              // Stop
              if (mediaService.currentMedia?.type != MediaContentType.image)
                IconButton(
                  onPressed: () async {
                    await dualScreenService.stopMedia();
                  },
                  icon: const Icon(Icons.stop),
                  color: Colors.white,
                  tooltip: 'Parar',
                ),
              
              // Avançar 10s
              if (mediaService.currentMedia?.type != MediaContentType.image)
                IconButton(
                  onPressed: () async {
                    await dualScreenService.mediaPlaybackService?.forward(10);
                  },
                  icon: const Icon(Icons.forward_10),
                  color: Colors.white,
                  tooltip: 'Avançar 10s',
                ),
              
              // Volume/Mute
              IconButton(
                onPressed: () async {
                  await dualScreenService.mediaPlaybackService?.toggleMute();
                },
                icon: Icon(mediaService.isMuted ? Icons.volume_off : Icons.volume_up),
                color: Colors.white,
                tooltip: mediaService.isMuted ? 'Reativar som' : 'Silenciar',
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getMediaIcon(MediaContentType? type) {
    if (type == null) return Icons.help_outline;
    switch (type) {
      case MediaContentType.audio:
        return Icons.music_note;
      case MediaContentType.video:
        return Icons.play_circle_outline;
      case MediaContentType.image:
        return Icons.image;
    }
    return Icons.help_outline; // fallback
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reproduzindo':
        return Colors.green;
      case 'pausado':
        return Colors.orange;
      case 'parado':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.bible: return Icons.menu_book;
      case ContentType.lyrics: return Icons.music_note;
      case ContentType.notes: return Icons.note;
      case ContentType.audio: return Icons.audiotrack;
      case ContentType.video: return Icons.videocam;
      case ContentType.image: return Icons.image;
    }
  }

  String _getContentTypeLabel(ContentType type) {
    switch (type) {
      case ContentType.bible: return 'Versículo Bíblico';
      case ContentType.lyrics: return 'Letra de Música';
      case ContentType.notes: return 'Nota/Sermão';
      case ContentType.audio: return 'Áudio';
      case ContentType.video: return 'Vídeo';
      case ContentType.image: return 'Imagem';
    }
  }
}