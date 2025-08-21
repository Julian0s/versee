import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versee/services/display_manager.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/providers/riverpod_providers.dart';

// Instância global para bridge híbrida
MediaSyncService? _globalMediaSyncService;

/// Service responsible for synchronizing media playback across multiple displays
/// Ensures that video/audio content is perfectly synchronized between displays
class MediaSyncService extends ChangeNotifier {
  // MediaPlaybackService? _mediaPlaybackService; // MIGRADO
  DisplayManager? _displayManager;
  LanguageService? _languageService;
  
  Timer? _syncTimer;
  Timer? _heartbeatTimer;
  
  // Construtor que configura a instância global
  MediaSyncService() {
    _globalMediaSyncService = this;
  }
  
  // Sync state
  bool _isSyncing = false;
  double _masterTimestamp = 0.0;
  String? _masterDisplayId;
  Map<String, double> _displayLatencies = {};
  Map<String, DateTime> _lastHeartbeats = {};
  
  // Sync configuration
  static const Duration _syncInterval = Duration(milliseconds: 100);
  static const Duration _heartbeatInterval = Duration(seconds: 2);
  static const Duration _latencyTolerance = Duration(milliseconds: 50);
  static const String _syncChannelKey = 'versee_media_sync';
  static const String _heartbeatChannelKey = 'versee_media_heartbeat';
  
  // Getters
  bool get isSyncing => _isSyncing;
  double get masterTimestamp => _masterTimestamp;
  String? get masterDisplayId => _masterDisplayId;
  Map<String, double> get displayLatencies => Map.unmodifiable(_displayLatencies);
  Map<String, DateTime> get lastHeartbeats => Map.unmodifiable(_lastHeartbeats);
  
  // void setMediaPlaybackService(MediaPlaybackService service) {
  //   _mediaPlaybackService = service;
  // } // MIGRADO
  
  void setDisplayManager(DisplayManager manager) {
    _displayManager = manager;
  }
  
  void setLanguageService(LanguageService service) {
    _languageService = service;
  }
  
  Future<void> initialize() async {
    debugLog('🎵 Inicializando MediaSyncService');
    
    try {
      // Setup sync communication
      _setupSyncCommunication();
      
      // Start heartbeat for connected displays
      _startHeartbeat();
      
      debugLog('✅ MediaSyncService inicializado com sucesso');
    } catch (e) {
      debugLog('❌ Erro ao inicializar MediaSyncService: $e');
    }
  }
  
  void _setupSyncCommunication() {
    // Listen for sync messages from other displays
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _checkSyncMessages();
    });
  }
  
  Future<void> _checkSyncMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check sync messages
      final syncMessage = prefs.getString(_syncChannelKey);
      if (syncMessage != null && syncMessage.isNotEmpty) {
        final data = jsonDecode(syncMessage);
        await _handleSyncMessage(data);
        await prefs.remove(_syncChannelKey);
      }
      
      // Check heartbeat messages
      final heartbeatMessage = prefs.getString(_heartbeatChannelKey);
      if (heartbeatMessage != null && heartbeatMessage.isNotEmpty) {
        final data = jsonDecode(heartbeatMessage);
        await _handleHeartbeatMessage(data);
        await prefs.remove(_heartbeatChannelKey);
      }
      
    } catch (e) {
      // Silent - normal for no messages
    }
  }
  
  Future<void> _handleSyncMessage(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    final timestamp = data['timestamp'] as int?;
    final displayId = data['displayId'] as String?;
    
    // Ignore old messages (>1 second)
    if (timestamp == null || 
        DateTime.now().millisecondsSinceEpoch - timestamp > 1000) {
      return;
    }
    
    switch (type) {
      case 'sync_request':
        await _handleSyncRequest(data);
        break;
        
      case 'sync_response':
        await _handleSyncResponse(data);
        break;
        
      case 'playback_command':
        await _handlePlaybackCommand(data);
        break;
        
      case 'seek_command':
        await _handleSeekCommand(data);
        break;
        
      case 'volume_command':
        await _handleVolumeCommand(data);
        break;
    }
  }
  
  Future<void> _handleHeartbeatMessage(Map<String, dynamic> data) async {
    final displayId = data['displayId'] as String?;
    final latency = data['latency'] as double?;
    
    if (displayId != null) {
      _lastHeartbeats[displayId] = DateTime.now();
      
      if (latency != null) {
        _displayLatencies[displayId] = latency;
      }
      
      debugLog('💓 Heartbeat recebido de $displayId (latência: ${latency}ms)');
    }
  }
  
  Future<void> _handleSyncRequest(Map<String, dynamic> data) async {
    if (_mediaPlaybackService == null) return;
    
    final requestingDisplayId = data['displayId'] as String?;
    if (requestingDisplayId == null) return;
    
    // Send current playback state
    await _sendSyncMessage({
      'type': 'sync_response',
      'displayId': _getCurrentDisplayId(),
      'position': _mediaPlaybackService!.currentPosition.inMilliseconds.toDouble(),
      'isPlaying': _mediaPlaybackService!.isPlaying,
      'volume': _mediaPlaybackService!.volume,
      'currentMediaId': _mediaPlaybackService!.currentMediaId,
      'targetDisplayId': requestingDisplayId,
    });
  }
  
  Future<void> _handleSyncResponse(Map<String, dynamic> data) async {
    final targetDisplayId = data['targetDisplayId'] as String?;
    if (targetDisplayId != _getCurrentDisplayId()) return;
    
    final position = data['position'] as double?;
    final isPlaying = data['isPlaying'] as bool?;
    final volume = data['volume'] as double?;
    final mediaId = data['currentMediaId'] as String?;
    
    if (_mediaPlaybackService != null && position != null) {
      // Sync to received state
      await _syncToPosition(position, isPlaying ?? false);
      
      if (volume != null) {
        await _mediaPlaybackService!.setVolume(volume);
      }
      
      debugLog('🔄 Sincronizado com posição ${position}ms');
    }
  }
  
  Future<void> _handlePlaybackCommand(Map<String, dynamic> data) async {
    if (_mediaPlaybackService == null) return;
    
    final command = data['command'] as String?;
    final mediaId = data['mediaId'] as String?;
    final syncPosition = data['position'] as double?;
    
    switch (command) {
      case 'play':
        if (mediaId != null && syncPosition != null) {
          await _mediaPlaybackService!.playMedia(mediaId);
          await _syncToPosition(syncPosition, true);
        } else {
          await _mediaPlaybackService!.resume();
        }
        break;
        
      case 'pause':
        await _mediaPlaybackService!.pause();
        break;
        
      case 'stop':
        await _mediaPlaybackService!.stop();
        break;
    }
  }
  
  Future<void> _handleSeekCommand(Map<String, dynamic> data) async {
    if (_mediaPlaybackService == null) return;
    
    final position = data['position'] as double?;
    if (position != null) {
      await _syncToPosition(position, _mediaPlaybackService!.isPlaying);
    }
  }
  
  Future<void> _handleVolumeCommand(Map<String, dynamic> data) async {
    if (_mediaPlaybackService == null) return;
    
    final volume = data['volume'] as double?;
    if (volume != null) {
      await _mediaPlaybackService!.setVolume(volume);
    }
  }
  
  Future<void> _syncToPosition(double position, bool shouldPlay) async {
    if (_mediaPlaybackService == null) return;
    
    try {
      // Calculate latency compensation
      final currentDisplayId = _getCurrentDisplayId();
      final latency = _displayLatencies[currentDisplayId] ?? 0.0;
      final compensatedPosition = position + latency;
      
      // Seek to compensated position
      final duration = Duration(milliseconds: compensatedPosition.round());
      await _mediaPlaybackService!.seekTo(duration);
      
      // Resume/pause as needed
      if (shouldPlay && !_mediaPlaybackService!.isPlaying) {
        await _mediaPlaybackService!.resume();
      } else if (!shouldPlay && _mediaPlaybackService!.isPlaying) {
        await _mediaPlaybackService!.pause();
      }
      
    } catch (e) {
      debugLog('❌ Erro ao sincronizar posição: $e');
    }
  }
  
  /// Start synchronized playback across all connected displays
  Future<void> startSyncedPlayback(String mediaId, {double startPosition = 0.0}) async {
    debugLog('🎬 Iniciando reprodução sincronizada: $mediaId');
    
    try {
      _isSyncing = true;
      _masterDisplayId = _getCurrentDisplayId();
      _masterTimestamp = startPosition;
      
      // Send play command to all displays
      await _sendSyncMessage({
        'type': 'playback_command',
        'command': 'play',
        'mediaId': mediaId,
        'position': startPosition,
        'masterDisplayId': _masterDisplayId,
      });
      
      // Start local playback
      if (_mediaPlaybackService != null) {
        await _mediaPlaybackService!.playMedia(mediaId);
        if (startPosition > 0) {
          await _syncToPosition(startPosition, true);
        }
      }
      
      // Start sync monitoring
      _startSyncMonitoring();
      
      notifyListeners();
      debugLog('✅ Reprodução sincronizada iniciada');
      
    } catch (e) {
      debugLog('❌ Erro ao iniciar reprodução sincronizada: $e');
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  /// Pause synchronized playback across all displays
  Future<void> pauseSyncedPlayback() async {
    debugLog('⏸️ Pausando reprodução sincronizada');
    
    await _sendSyncMessage({
      'type': 'playback_command',
      'command': 'pause',
      'masterDisplayId': _masterDisplayId,
    });
    
    if (_mediaPlaybackService != null) {
      await _mediaPlaybackService!.pause();
    }
  }
  
  /// Resume synchronized playback across all displays
  Future<void> resumeSyncedPlayback() async {
    debugLog('▶️ Retomando reprodução sincronizada');
    
    final currentPosition = _mediaPlaybackService?.currentPosition.inMilliseconds.toDouble() ?? 0.0;
    
    await _sendSyncMessage({
      'type': 'playback_command',
      'command': 'play',
      'position': currentPosition,
      'masterDisplayId': _masterDisplayId,
    });
    
    if (_mediaPlaybackService != null) {
      await _mediaPlaybackService!.resume();
    }
  }
  
  /// Stop synchronized playback across all displays
  Future<void> stopSyncedPlayback() async {
    debugLog('⏹️ Parando reprodução sincronizada');
    
    await _sendSyncMessage({
      'type': 'playback_command',
      'command': 'stop',
      'masterDisplayId': _masterDisplayId,
    });
    
    if (_mediaPlaybackService != null) {
      await _mediaPlaybackService!.stop();
    }
    
    _stopSyncMonitoring();
    _isSyncing = false;
    _masterDisplayId = null;
    _masterTimestamp = 0.0;
    
    notifyListeners();
  }
  
  /// Seek to position on all synchronized displays
  Future<void> seekSyncedPlayback(double position) async {
    debugLog('⏭️ Buscando posição sincronizada: ${position}ms');
    
    _masterTimestamp = position;
    
    await _sendSyncMessage({
      'type': 'seek_command',
      'position': position,
      'masterDisplayId': _masterDisplayId,
    });
    
    if (_mediaPlaybackService != null) {
      await _syncToPosition(position, _mediaPlaybackService!.isPlaying);
    }
  }
  
  /// Set volume on all synchronized displays
  Future<void> setSyncedVolume(double volume) async {
    debugLog('🔊 Configurando volume sincronizado: $volume');
    
    await _sendSyncMessage({
      'type': 'volume_command',
      'volume': volume,
      'masterDisplayId': _masterDisplayId,
    });
    
    if (_mediaPlaybackService != null) {
      await _mediaPlaybackService!.setVolume(volume);
    }
  }
  
  void _startSyncMonitoring() {
    _stopSyncMonitoring();
    
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _performSyncCheck();
    });
  }
  
  void _stopSyncMonitoring() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  void _performSyncCheck() {
    if (!_isSyncing || _mediaPlaybackService == null) return;
    
    final currentPosition = _mediaPlaybackService!.currentPosition.inMilliseconds.toDouble();
    final timeDiff = (currentPosition - _masterTimestamp).abs();
    
    // If drift is too large, request sync from master
    if (timeDiff > _latencyTolerance.inMilliseconds) {
      _requestSync();
    }
    
    _masterTimestamp = currentPosition;
  }
  
  Future<void> _requestSync() async {
    await _sendSyncMessage({
      'type': 'sync_request',
      'displayId': _getCurrentDisplayId(),
    });
  }
  
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      _sendHeartbeat();
    });
  }
  
  Future<void> _sendHeartbeat() async {
    final displayId = _getCurrentDisplayId();
    final latency = await _measureLatency();
    
    await _sendMessage(_heartbeatChannelKey, {
      'displayId': displayId,
      'latency': latency,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  Future<double> _measureLatency() async {
    // Simple latency measurement
    // In production, would use more sophisticated methods
    final start = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 1));
    final end = DateTime.now();
    
    return end.difference(start).inMicroseconds / 1000.0;
  }
  
  Future<void> _sendSyncMessage(Map<String, dynamic> message) async {
    await _sendMessage(_syncChannelKey, message);
  }
  
  Future<void> _sendMessage(String channel, Map<String, dynamic> message) async {
    try {
      message['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(channel, jsonEncode(message));
    } catch (e) {
      debugLog('❌ Erro ao enviar mensagem de sync: $e');
    }
  }
  
  String _getCurrentDisplayId() {
    return _displayManager?.connectedDisplay?.id ?? 'main_display';
  }
  
  /// Get sync status information
  Map<String, dynamic> getSyncStatus() {
    return {
      'isSyncing': _isSyncing,
      'masterDisplayId': _masterDisplayId,
      'masterTimestamp': _masterTimestamp,
      'connectedDisplays': _lastHeartbeats.keys.toList(),
      'displayLatencies': _displayLatencies,
      'lastHeartbeats': _lastHeartbeats.map(
        (key, value) => MapEntry(key, value.toIso8601String())
      ),
    };
  }
  
  /// Calibrate latency for a specific display
  Future<double> calibrateDisplayLatency(String displayId) async {
    debugLog('🎯 Calibrando latência para display: $displayId');
    
    const int iterations = 10;
    final List<double> measurements = [];
    
    for (int i = 0; i < iterations; i++) {
      final start = DateTime.now();
      
      // Send ping message
      await _sendSyncMessage({
        'type': 'latency_ping',
        'displayId': displayId,
        'pingId': i,
      });
      
      // Wait for response (simplified - in production would be async)
      await Future.delayed(const Duration(milliseconds: 10));
      
      final end = DateTime.now();
      measurements.add(end.difference(start).inMicroseconds / 1000.0);
    }
    
    // Calculate average latency
    final averageLatency = measurements.reduce((a, b) => a + b) / measurements.length;
    _displayLatencies[displayId] = averageLatency;
    
    debugLog('📊 Latência calibrada para $displayId: ${averageLatency}ms');
    return averageLatency;
  }
  
  void debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
  
  // Getter estático para acesso global
  static MediaSyncService? get globalInstance => _globalMediaSyncService;
  
  // Método de sincronização com Riverpod
  void syncWithRiverpod(MediaSyncState state) {
    if (_isSyncing != state.isSyncing ||
        _masterTimestamp != state.masterTimestamp ||
        _masterDisplayId != state.masterDisplayId ||
        !mapEquals(_displayLatencies, state.displayLatencies) ||
        !mapEquals(_lastHeartbeats, state.lastHeartbeats)) {
      
      _isSyncing = state.isSyncing;
      _masterTimestamp = state.masterTimestamp;
      _masterDisplayId = state.masterDisplayId;
      _displayLatencies = Map<String, double>.from(state.displayLatencies);
      _lastHeartbeats = Map<String, DateTime>.from(state.lastHeartbeats);
      
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    debugLog('🧹 Disposing MediaSyncService');
    
    _stopSyncMonitoring();
    _heartbeatTimer?.cancel();
    
    if (_globalMediaSyncService == this) {
      _globalMediaSyncService = null;
    }
    
    super.dispose();
  }
}