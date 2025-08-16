import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:versee/services/playlist_service.dart';
import 'package:versee/services/presentation_engine_service.dart';

/// Cross-platform manager for external display presentations
/// Handles both Android Presentation API and iOS External Display
class PresentationManager extends ChangeNotifier {
  // Platform-specific method channels
  static const _androidChannel = MethodChannel('versee/presentation');
  static const _iosChannel = MethodChannel('versee/external_display'); // For future iOS implementation
  
  // State management
  bool _isExternalPresentationActive = false;
  bool _hasExternalDisplay = false;
  String? _activeDisplayId;
  String? _activeDisplayName;
  PresentationItem? _currentItem;
  bool _isBlackScreenActive = false;
  
  // Services
  PresentationEngineService? _presentationEngine;
  
  // Stream for state updates
  final StreamController<PresentationManagerState> _stateController = 
      StreamController<PresentationManagerState>.broadcast();

  // Getters
  bool get isExternalPresentationActive => _isExternalPresentationActive;
  bool get hasExternalDisplay => _hasExternalDisplay;
  String? get activeDisplayId => _activeDisplayId;
  String? get activeDisplayName => _activeDisplayName;
  PresentationItem? get currentItem => _currentItem;
  bool get isBlackScreenActive => _isBlackScreenActive;
  Stream<PresentationManagerState> get stateStream => _stateController.stream;

  PresentationManager() {
    _initialize();
  }

  /// Initialize the presentation manager
  Future<void> _initialize() async {
    debugPrint('🖥️ Initializing PresentationManager for platform: ${Platform.operatingSystem}');
    
    // Create presentation engine service
    _presentationEngine = PresentationEngineService();
    
    // Listen to presentation engine state changes
    _presentationEngine?.stateStream.listen((engineState) {
      _syncWithEngineState(engineState);
    });
    
    // Check for external displays
    await checkForExternalDisplays();
  }

  /// Set the presentation engine service (for dependency injection)
  void setPresentationEngine(PresentationEngineService engine) {
    _presentationEngine = engine;
    
    // Listen to engine state changes
    _presentationEngine?.stateStream.listen((engineState) {
      _syncWithEngineState(engineState);
    });
  }

  /// Sync manager state with presentation engine state
  void _syncWithEngineState(PresentationEngineState engineState) {
    _isExternalPresentationActive = engineState.isPresentationReady;
    _activeDisplayId = engineState.connectedDisplayId;
    _activeDisplayName = engineState.connectedDisplayName;
    _isBlackScreenActive = engineState.isBlackScreenActive;
    
    _broadcastState();
    notifyListeners();
  }

  /// Check for available external displays
  Future<bool> checkForExternalDisplays() async {
    try {
      if (Platform.isAndroid) {
        _hasExternalDisplay = await _androidChannel.invokeMethod('hasExternalDisplay');
      } else if (Platform.isIOS) {
        // TODO: Implement iOS external display check
        _hasExternalDisplay = await _iosChannel.invokeMethod('hasExternalDisplay');
      } else {
        // Web/Desktop - no external display support for now
        _hasExternalDisplay = false;
      }
      
      debugPrint('🖥️ External display available: $_hasExternalDisplay');
      _broadcastState();
      notifyListeners();
      
      return _hasExternalDisplay;
    } catch (e) {
      debugPrint('🖥️ Error checking external displays: $e');
      _hasExternalDisplay = false;
      _broadcastState();
      notifyListeners();
      return false;
    }
  }

  /// Start external presentation
  Future<bool> startExternalPresentation() async {
    try {
      debugPrint('🖥️ Starting external presentation...');
      
      if (Platform.isAndroid) {
        final result = await _androidChannel.invokeMethod('startExternalPresentation');
        
        if (result is Map) {
          _isExternalPresentationActive = result['success'] == true;
          _activeDisplayId = result['displayId']?.toString();
          _activeDisplayName = result['displayName']?.toString();
        } else {
          _isExternalPresentationActive = result == true;
        }
        
      } else if (Platform.isIOS) {
        // TODO: Implement iOS external presentation
        final result = await _iosChannel.invokeMethod('startExternalPresentation');
        _isExternalPresentationActive = result == true;
        
      } else {
        // Web/Desktop fallback - open new window
        _isExternalPresentationActive = await _startWebPresentation();
      }
      
      debugPrint('🖥️ External presentation active: $_isExternalPresentationActive');
      _broadcastState();
      notifyListeners();
      
      return _isExternalPresentationActive;
      
    } catch (e) {
      debugPrint('🖥️ Error starting external presentation: $e');
      _isExternalPresentationActive = false;
      _broadcastState();
      notifyListeners();
      return false;
    }
  }

  /// Stop external presentation
  Future<void> stopExternalPresentation() async {
    try {
      debugPrint('🖥️ Stopping external presentation...');
      
      if (Platform.isAndroid) {
        await _androidChannel.invokeMethod('stopExternalPresentation');
      } else if (Platform.isIOS) {
        await _iosChannel.invokeMethod('stopExternalPresentation');
      } else {
        await _stopWebPresentation();
      }
      
      _isExternalPresentationActive = false;
      _activeDisplayId = null;
      _activeDisplayName = null;
      _currentItem = null;
      _isBlackScreenActive = false;
      
      debugPrint('🖥️ External presentation stopped');
      _broadcastState();
      notifyListeners();
      
    } catch (e) {
      debugPrint('🖥️ Error stopping external presentation: $e');
    }
  }

  /// Update presentation content
  Future<void> updatePresentationContent(PresentationItem item) async {
    _currentItem = item;
    
    try {
      if (_isExternalPresentationActive) {
        // Update presentation engine
        await _presentationEngine?.updateCurrentItem(item);
        
        // Update native presentation if needed
        if (Platform.isAndroid) {
          final content = {
            'type': item.type.toString(),
            'title': item.title,
            'content': item.content,
            'metadata': item.metadata ?? {},
          };
          await _androidChannel.invokeMethod('updatePresentationContent', content);
          
        } else if (Platform.isIOS) {
          // TODO: Update iOS presentation content
          final content = {
            'type': item.type.toString(),
            'title': item.title,
            'content': item.content,
            'metadata': item.metadata ?? {},
          };
          await _iosChannel.invokeMethod('updatePresentationContent', content);
        }
      }
      
      _broadcastState();
      notifyListeners();
      
    } catch (e) {
      debugPrint('🖥️ Error updating presentation content: $e');
    }
  }

  /// Set black screen mode
  Future<void> setBlackScreen(bool active) async {
    _isBlackScreenActive = active;
    
    try {
      if (_isExternalPresentationActive) {
        // Update presentation engine
        await _presentationEngine?.setBlackScreen(active);
        
        // Update native presentation
        if (Platform.isAndroid) {
          await _androidChannel.invokeMethod('setPresentationBlackScreen', {'active': active});
        } else if (Platform.isIOS) {
          await _iosChannel.invokeMethod('setPresentationBlackScreen', {'active': active});
        }
      }
      
      _broadcastState();
      notifyListeners();
      
    } catch (e) {
      debugPrint('🖥️ Error setting black screen: $e');
    }
  }

  /// Start web presentation (fallback for web/desktop)
  Future<bool> _startWebPresentation() async {
    try {
      // For web, this would open a new window
      // For now, return false to indicate not supported
      debugPrint('🖥️ Web presentation not implemented yet');
      return false;
    } catch (e) {
      debugPrint('🖥️ Error starting web presentation: $e');
      return false;
    }
  }

  /// Stop web presentation
  Future<void> _stopWebPresentation() async {
    try {
      // Close web presentation window
      debugPrint('🖥️ Stopping web presentation');
    } catch (e) {
      debugPrint('🖥️ Error stopping web presentation: $e');
    }
  }

  /// Broadcast current state
  void _broadcastState() {
    final state = PresentationManagerState(
      isExternalPresentationActive: _isExternalPresentationActive,
      hasExternalDisplay: _hasExternalDisplay,
      activeDisplayId: _activeDisplayId,
      activeDisplayName: _activeDisplayName,
      currentItem: _currentItem,
      isBlackScreenActive: _isBlackScreenActive,
    );
    
    _stateController.add(state);
  }

  /// Get current state
  PresentationManagerState getCurrentState() {
    return PresentationManagerState(
      isExternalPresentationActive: _isExternalPresentationActive,
      hasExternalDisplay: _hasExternalDisplay,
      activeDisplayId: _activeDisplayId,
      activeDisplayName: _activeDisplayName,
      currentItem: _currentItem,
      isBlackScreenActive: _isBlackScreenActive,
    );
  }

  @override
  void dispose() {
    _stateController.close();
    super.dispose();
  }
}

/// State class for presentation manager
class PresentationManagerState {
  final bool isExternalPresentationActive;
  final bool hasExternalDisplay;
  final String? activeDisplayId;
  final String? activeDisplayName;
  final PresentationItem? currentItem;
  final bool isBlackScreenActive;

  const PresentationManagerState({
    required this.isExternalPresentationActive,
    required this.hasExternalDisplay,
    required this.activeDisplayId,
    required this.activeDisplayName,
    required this.currentItem,
    required this.isBlackScreenActive,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PresentationManagerState &&
        other.isExternalPresentationActive == isExternalPresentationActive &&
        other.hasExternalDisplay == hasExternalDisplay &&
        other.activeDisplayId == activeDisplayId &&
        other.activeDisplayName == activeDisplayName &&
        other.currentItem == currentItem &&
        other.isBlackScreenActive == isBlackScreenActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      isExternalPresentationActive,
      hasExternalDisplay,
      activeDisplayId,
      activeDisplayName,
      currentItem,
      isBlackScreenActive,
    );
  }

  @override
  String toString() {
    return 'PresentationManagerState('
        'isExternalPresentationActive: $isExternalPresentationActive, '
        'hasExternalDisplay: $hasExternalDisplay, '
        'activeDisplayId: $activeDisplayId, '
        'activeDisplayName: $activeDisplayName, '
        'currentItem: $currentItem, '
        'isBlackScreenActive: $isBlackScreenActive)';
  }
}