import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/services/language_service.dart';

/// Página de projeção para displays externos na web
/// Esta página é aberta em janelas/tabs separadas para exibir conteúdo
class WebProjectionPage extends StatefulWidget {
  final String? displayId;
  final String? mode;
  
  const WebProjectionPage({
    super.key,
    this.displayId,
    this.mode = 'projection',
  });

  @override
  State<WebProjectionPage> createState() => _WebProjectionPageState();
}

class _WebProjectionPageState extends State<WebProjectionPage> {
  Timer? _messageListener;
  PresentationItem? _currentItem;
  bool _isPresenting = false;
  bool _isBlackScreenActive = false;
  
  // Configurações de apresentação
  double _fontSize = 32.0;
  Color _textColor = Colors.white;
  Color _backgroundColor = Colors.black;
  TextAlign _textAlignment = TextAlign.center;
  
  @override
  void initState() {
    super.initState();
    _initializeProjection();
  }

  Future<void> _initializeProjection() async {
    // Configurar listener para mensagens
    _setupMessageListener();
    
    // Notificar que a página está pronta
    await _sendReadyMessage();
    
    // Configurar tela cheia se disponível
    _setupFullscreen();
  }

  void _setupMessageListener() {
    _messageListener = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _checkForMessages();
    });
  }

  Future<void> _checkForMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messageKey = 'versee_display_message';
      final message = prefs.getString(messageKey);
      
      if (message != null && message.isNotEmpty) {
        final data = jsonDecode(message);
        final timestamp = data['timestamp'] as int?;
        final targetDisplayId = data['displayId'] as String?;
        
        // Processar apenas mensagens para este display e recentes
        if (targetDisplayId == widget.displayId &&
            timestamp != null && 
            DateTime.now().millisecondsSinceEpoch - timestamp < 2000) {
          await _handleMessage(data);
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar mensagens na projeção: $e');
    }
  }

  Future<void> _handleMessage(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'start_presentation':
        _handleStartPresentation(data);
        break;
        
      case 'stop_presentation':
        _handleStopPresentation();
        break;
        
      case 'update_presentation':
        _handleUpdatePresentation(data);
        break;
        
      case 'toggle_black_screen':
        _handleToggleBlackScreen(data);
        break;
        
      case 'update_settings':
        _handleUpdateSettings(data);
        break;
        
      case 'ping_test':
        await _sendPongMessage();
        break;
    }
  }

  void _handleStartPresentation(Map<String, dynamic> data) {
    final itemData = data['item'] as Map<String, dynamic>?;
    final settingsData = data['settings'] as Map<String, dynamic>?;
    
    if (itemData != null) {
      setState(() {
        _currentItem = _deserializePresentationItem(itemData);
        _isPresenting = true;
        _isBlackScreenActive = false;
      });
      
      if (settingsData != null) {
        _updateSettings(settingsData);
      }
      
      debugPrint('🎬 Apresentação iniciada na projeção: ${_currentItem?.title}');
    }
  }

  void _handleStopPresentation() {
    setState(() {
      _isPresenting = false;
      _currentItem = null;
      _isBlackScreenActive = false;
    });
    
    debugPrint('⏹️ Apresentação parada na projeção');
  }

  void _handleUpdatePresentation(Map<String, dynamic> data) {
    final itemData = data['item'] as Map<String, dynamic>?;
    
    if (itemData != null && _isPresenting) {
      setState(() {
        _currentItem = _deserializePresentationItem(itemData);
      });
      
      debugPrint('🔄 Apresentação atualizada na projeção: ${_currentItem?.title}');
    }
  }

  void _handleToggleBlackScreen(Map<String, dynamic> data) {
    final active = data['active'] as bool? ?? false;
    
    setState(() {
      _isBlackScreenActive = active;
    });
    
    debugPrint('🖤 Tela preta ${active ? 'ativada' : 'desativada'} na projeção');
  }

  void _handleUpdateSettings(Map<String, dynamic> data) {
    final settingsData = data['settings'] as Map<String, dynamic>?;
    if (settingsData != null) {
      _updateSettings(settingsData);
    }
  }

  void _updateSettings(Map<String, dynamic> settings) {
    setState(() {
      _fontSize = (settings['fontSize'] as num?)?.toDouble() ?? _fontSize;
      
      final textColorValue = settings['textColor'];
      if (textColorValue is int) {
        _textColor = Color(textColorValue);
      } else if (textColorValue is String && textColorValue.startsWith('#')) {
        _textColor = Color(int.parse(textColorValue.substring(1), radix: 16));
      }
      
      final backgroundColorValue = settings['backgroundColor'];
      if (backgroundColorValue is int) {
        _backgroundColor = Color(backgroundColorValue);
      } else if (backgroundColorValue is String && backgroundColorValue.startsWith('#')) {
        _backgroundColor = Color(int.parse(backgroundColorValue.substring(1), radix: 16));
      }
      
      final alignmentIndex = settings['textAlignment'] as int?;
      if (alignmentIndex != null) {
        _textAlignment = TextAlign.values[alignmentIndex];
      }
    });
    
    debugPrint('⚙️ Configurações atualizadas na projeção');
  }

  PresentationItem _deserializePresentationItem(Map<String, dynamic> data) {
    final typeString = data['type'] as String;
    ContentType type;
    
    switch (typeString) {
      case 'bible':
        type = ContentType.bible;
        break;
      case 'lyrics':
        type = ContentType.lyrics;
        break;
      case 'notes':
        type = ContentType.notes;
        break;
      case 'audio':
        type = ContentType.audio;
        break;
      case 'video':
        type = ContentType.video;
        break;
      case 'image':
        type = ContentType.image;
        break;
      default:
        type = ContentType.notes;
    }
    
    return PresentationItem(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      type: type,
      content: data['content'] ?? '',
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Future<void> _sendReadyMessage() async {
    await _sendMessage({
      'type': 'display_ready',
      'displayId': widget.displayId,
      'capabilities': [
        'images',
        'video', 
        'audio',
        'slideSync',
        'remoteControl',
      ],
    });
  }

  Future<void> _sendPongMessage() async {
    await _sendMessage({
      'type': 'ping_response',
      'displayId': widget.displayId,
      'status': 'active',
    });
  }

  Future<void> _sendMessage(Map<String, dynamic> message) async {
    try {
      message['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      message['source'] = 'projection_display';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('versee_projection_response', jsonEncode(message));
    } catch (e) {
      debugPrint('❌ Erro ao enviar mensagem da projeção: $e');
    }
  }

  void _setupFullscreen() {
    // Em uma implementação real, usaríamos APIs de fullscreen
    // Por enquanto, apenas documentamos a intenção
    debugPrint('📺 Configurando modo fullscreen para projeção');
  }

  @override
  void dispose() {
    _messageListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: null, // Sem app bar para projeção limpa
      body: _buildProjectionContent(),
      // Adicionar overlay de debug em desenvolvimento
      floatingActionButton: kDebugMode ? _buildDebugInfo() : null,
    );
  }
  
  Widget? _buildDebugInfo() {
    return FloatingActionButton.extended(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug Info'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display ID: ${widget.displayId}'),
                Text('Mode: ${widget.mode}'),
                Text('Is Presenting: $_isPresenting'),
                Text('Current Item: ${_currentItem?.title ?? 'None'}'),
                Text('Black Screen: $_isBlackScreenActive'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.bug_report),
      label: const Text('Debug'),
      backgroundColor: Colors.red.withOpacity(0.8),
    );
  }

  Widget _buildProjectionContent() {
    if (_isBlackScreenActive) {
      return _buildBlackScreen();
    }
    
    if (!_isPresenting || _currentItem == null) {
      return _buildWaitingScreen();
    }
    
    return _buildSlideContent(_currentItem!);
  }

  Widget _buildBlackScreen() {
    return Container(
      color: Colors.black,
      child: const SizedBox.expand(),
    );
  }

  Widget _buildWaitingScreen() {
    return Container(
      color: _backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tv,
              color: _textColor.withOpacity(0.4),
              size: 120,
            ),
            const SizedBox(height: 32),
            Text(
              'VERSEE',
              style: TextStyle(
                color: _textColor.withOpacity(0.6),
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tela de Projeção',
              style: TextStyle(
                color: _textColor.withOpacity(0.4),
                fontSize: 20,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            Consumer<LanguageService>(
              builder: (context, languageService, child) {
                return Text(
                  languageService.strings.displayWaitingPresentation,
                  style: TextStyle(
                    color: _textColor.withOpacity(0.3),
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
            const SizedBox(height: 32),
            // Status da conexão
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _textColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi,
                    color: _textColor.withOpacity(0.4),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Aguardando apresentação...',
                    style: TextStyle(
                      color: _textColor.withOpacity(0.4),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.displayId != null) ...[
              const SizedBox(height: 16),
              Text(
                'Display ID: ${widget.displayId}',
                style: TextStyle(
                  color: _textColor.withOpacity(0.2),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLocalizedWaitingText(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    return languageService.strings.displayWaitingPresentation;
  }

  Widget _buildSlideContent(PresentationItem item) {
    switch (item.type) {
      case ContentType.bible:
        return _buildBibleSlide(item);
      case ContentType.lyrics:
        return _buildLyricsSlide(item);
      case ContentType.notes:
        return _buildNotesSlide(item);
      case ContentType.image:
        return _buildImageSlide(item);
      case ContentType.video:
        return _buildVideoSlide(item);
      case ContentType.audio:
        return _buildAudioSlide(item);
    }
  }

  Widget _buildBibleSlide(PresentationItem item) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Texto do versículo
          Flexible(
            child: Text(
              item.content,
              style: TextStyle(
                color: _textColor,
                fontSize: _fontSize,
                fontWeight: FontWeight.w500,
                height: 1.4,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: _textAlignment,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Referência bíblica
          Text(
            item.metadata?['reference'] ?? '',
            style: TextStyle(
              color: _textColor.withOpacity(0.8),
              fontSize: _fontSize * 0.7,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsSlide(PresentationItem item) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Text(
          item.content,
          style: TextStyle(
            color: _textColor,
            fontSize: _fontSize,
            fontWeight: FontWeight.w500,
            height: 1.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: _textAlignment,
        ),
      ),
    );
  }

  Widget _buildNotesSlide(PresentationItem item) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: SingleChildScrollView(
        child: Text(
          item.content,
          style: TextStyle(
            color: _textColor,
            fontSize: _fontSize * 0.8,
            fontWeight: FontWeight.w400,
            height: 1.6,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: _textAlignment,
        ),
      ),
    );
  }

  Widget _buildImageSlide(PresentationItem item) {
    return Container(
      color: _backgroundColor,
      child: Center(
        child: Image.network(
          item.content,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  color: _textColor.withOpacity(0.5),
                  size: 120,
                ),
                const SizedBox(height: 20),
                Consumer<LanguageService>(
                  builder: (context, languageService, child) {
                    return Text(
                      languageService.strings.displayImageLoadError,
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: _fontSize * 0.6,
                      ),
                    );
                  },
                ),
              ],
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: _textColor,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
                const SizedBox(height: 20),
                Consumer<LanguageService>(
                  builder: (context, languageService, child) {
                    return Text(
                      languageService.strings.displayLoadingImage,
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: _fontSize * 0.6,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoSlide(PresentationItem item) {
    return Container(
      color: _backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_filled,
              color: _textColor,
              size: 120,
            ),
            const SizedBox(height: 20),
            Text(
              item.title,
              style: TextStyle(
                color: _textColor,
                fontSize: _fontSize,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Consumer<LanguageService>(
              builder: (context, languageService, child) {
                return Text(
                  languageService.strings.displayAwaitingPlayback,
                  style: TextStyle(
                    color: _textColor.withOpacity(0.7),
                    fontSize: _fontSize * 0.6,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSlide(PresentationItem item) {
    return Container(
      color: _backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              color: _textColor,
              size: 120,
            ),
            const SizedBox(height: 20),
            Text(
              item.title,
              style: TextStyle(
                color: _textColor,
                fontSize: _fontSize,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Consumer<LanguageService>(
              builder: (context, languageService, child) {
                return Text(
                  languageService.strings.displayAwaitingPlayback,
                  style: TextStyle(
                    color: _textColor.withOpacity(0.7),
                    fontSize: _fontSize * 0.6,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}