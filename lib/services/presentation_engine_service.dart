import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:versee/services/playlist_service.dart';

/// Service to manage the separate Flutter engine for external display presentations
/// This service coordinates the presentation display shown on external monitors/projectors
class PresentationEngineService extends ChangeNotifier {
  static const platform = MethodChannel('versee/presentation_display');
  
  // Current presentation state
  PresentationItem? _currentItem;
  bool _isBlackScreenActive = false;
  bool _isPresentationReady = false;
  String? _connectedDisplayId;
  String? _connectedDisplayName;
  
  // Stream controllers for real-time updates
  final StreamController<PresentationEngineState> _stateController = 
      StreamController<PresentationEngineState>.broadcast();
  
  // Getters
  PresentationItem? get currentItem => _currentItem;
  bool get isBlackScreenActive => _isBlackScreenActive;
  bool get isPresentationReady => _isPresentationReady;
  String? get connectedDisplayId => _connectedDisplayId;
  String? get connectedDisplayName => _connectedDisplayName;
  Stream<PresentationEngineState> get stateStream => _stateController.stream;

  PresentationEngineService() {
    _setupMethodCallHandler();
  }

  /// Setup method call handler for communication from native presentation
  void _setupMethodCallHandler() {
    platform.setMethodCallHandler((call) async {
      debugPrint('🖥️ PresentationEngine received: ${call.method}');
      
      switch (call.method) {
        case 'onPresentationReady':
          final args = call.arguments as Map<String, dynamic>;
          _handlePresentationReady(args);
          break;
          
        case 'onPresentationStarted':
          _handlePresentationStarted();
          break;
          
        case 'onPresentationStopped':
          _handlePresentationStopped();
          break;
          
        case 'onDisplayChanged':
          final args = call.arguments as Map<String, dynamic>;
          _handleDisplayChanged(args);
          break;
          
        case 'updatePresentationContent':
          final args = call.arguments as Map<String, dynamic>;
          _handleContentUpdate(args);
          break;
          
        case 'setBlackScreen':
          final active = call.arguments as bool;
          _handleBlackScreen(active);
          break;
      }
    });
  }

  /// Handle presentation ready notification from native
  void _handlePresentationReady(Map<String, dynamic> args) {
    _isPresentationReady = true;
    _connectedDisplayId = args['displayId']?.toString();
    _connectedDisplayName = args['displayName']?.toString();
    
    debugPrint('🖥️ Presentation ready on display: $_connectedDisplayName');
    _broadcastState();
    notifyListeners();
  }

  /// Handle presentation started notification
  void _handlePresentationStarted() {
    debugPrint('🖥️ Presentation started');
    _broadcastState();
    notifyListeners();
  }

  /// Handle presentation stopped notification
  void _handlePresentationStopped() {
    _isPresentationReady = false;
    _connectedDisplayId = null;
    _connectedDisplayName = null;
    _currentItem = null;
    _isBlackScreenActive = false;
    
    debugPrint('🖥️ Presentation stopped');
    _broadcastState();
    notifyListeners();
  }

  /// Handle display changed notification
  void _handleDisplayChanged(Map<String, dynamic> args) {
    _connectedDisplayId = args['displayId']?.toString();
    _connectedDisplayName = args['displayName']?.toString();
    
    debugPrint('🖥️ Display changed: $_connectedDisplayName');
    _broadcastState();
    notifyListeners();
  }

  /// Handle content update from main app
  void _handleContentUpdate(Map<String, dynamic> args) {
    // This would be called when the main app wants to update presentation content
    // The actual rendering would happen in the presentation display widget
    debugPrint('🖥️ Content update received: ${args.keys}');
    _broadcastState();
  }

  /// Handle black screen toggle
  void _handleBlackScreen(bool active) {
    _isBlackScreenActive = active;
    debugPrint('🖥️ Black screen: $active');
    _broadcastState();
    notifyListeners();
  }

  /// Update the current presentation item
  /// This method is called from the main app to sync content
  Future<void> updateCurrentItem(PresentationItem? item) async {
    _currentItem = item;
    
    if (_isPresentationReady && item != null) {
      try {
        // Send content update to native presentation
        await _sendContentUpdate(item);
      } catch (e) {
        debugPrint('🖥️ Error updating presentation content: $e');
      }
    }
    
    _broadcastState();
    notifyListeners();
  }

  /// Set black screen state
  Future<void> setBlackScreen(bool active) async {
    _isBlackScreenActive = active;
    
    if (_isPresentationReady) {
      try {
        await platform.invokeMethod('setBlackScreen', active);
      } catch (e) {
        debugPrint('🖥️ Error setting black screen: $e');
      }
    }
    
    _broadcastState();
    notifyListeners();
  }

  /// Send content update to native presentation
  Future<void> _sendContentUpdate(PresentationItem item) async {
    final content = {
      'type': item.type.toString(),
      'title': item.title,
      'content': item.content,
      'metadata': item.metadata ?? {},
    };
    
    await platform.invokeMethod('updateContent', content);
  }

  /// Broadcast current state to listeners
  void _broadcastState() {
    final state = PresentationEngineState(
      currentItem: _currentItem,
      isBlackScreenActive: _isBlackScreenActive,
      isPresentationReady: _isPresentationReady,
      connectedDisplayId: _connectedDisplayId,
      connectedDisplayName: _connectedDisplayName,
    );
    
    _stateController.add(state);
  }

  /// Get current presentation state
  PresentationEngineState getCurrentState() {
    return PresentationEngineState(
      currentItem: _currentItem,
      isBlackScreenActive: _isBlackScreenActive,
      isPresentationReady: _isPresentationReady,
      connectedDisplayId: _connectedDisplayId,
      connectedDisplayName: _connectedDisplayName,
    );
  }

  @override
  void dispose() {
    _stateController.close();
    super.dispose();
  }
}

/// State class for presentation engine
class PresentationEngineState {
  final PresentationItem? currentItem;
  final bool isBlackScreenActive;
  final bool isPresentationReady;
  final String? connectedDisplayId;
  final String? connectedDisplayName;

  const PresentationEngineState({
    required this.currentItem,
    required this.isBlackScreenActive,
    required this.isPresentationReady,
    required this.connectedDisplayId,
    required this.connectedDisplayName,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PresentationEngineState &&
        other.currentItem == currentItem &&
        other.isBlackScreenActive == isBlackScreenActive &&
        other.isPresentationReady == isPresentationReady &&
        other.connectedDisplayId == connectedDisplayId &&
        other.connectedDisplayName == connectedDisplayName;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentItem,
      isBlackScreenActive,
      isPresentationReady,
      connectedDisplayId,
      connectedDisplayName,
    );
  }

  @override
  String toString() {
    return 'PresentationEngineState('
        'currentItem: $currentItem, '
        'isBlackScreenActive: $isBlackScreenActive, '
        'isPresentationReady: $isPresentationReady, '
        'connectedDisplayId: $connectedDisplayId, '
        'connectedDisplayName: $connectedDisplayName)';
  }
}