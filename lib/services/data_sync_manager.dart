import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versee/firestore/firestore_data_schema.dart';
import 'package:versee/services/firebase_manager.dart';

/// Data synchronization manager for VERSEE
/// Handles offline data storage and sync when connection is restored
class DataSyncManager extends ChangeNotifier {
  final FirebaseManager _firebase = FirebaseManager();
  
  bool _isSyncing = false;
  String? _syncError;
  DateTime? _lastSyncTime;
  int _pendingOperations = 0;

  static const String _syncQueueKey = 'versee_sync_queue';
  static const String _lastSyncTimeKey = 'versee_last_sync_time';

  // Getters
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingOperations => _pendingOperations;
  bool get hasPendingOperations => _pendingOperations > 0;

  DataSyncManager() {
    _loadSyncState();
  }

  /// Initialize sync manager and restore pending operations
  Future<void> initialize() async {
    await _loadPendingOperations();
    
    // Listen to network changes and auto-sync when online
    _firebase.authStateChanges.listen((user) {
      if (user != null) {
        syncPendingOperations();
      }
    });
  }

  /// Load sync state from local storage
  Future<void> _loadSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncTimeKey);
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.parse(lastSyncStr);
      }
    } catch (e) {
      debugPrint('Error loading sync state: $e');
    }
  }

  /// Save sync state to local storage
  Future<void> _saveSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastSyncTime != null) {
        await prefs.setString(_lastSyncTimeKey, _lastSyncTime!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving sync state: $e');
    }
  }

  /// Load pending operations count
  Future<void> _loadPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_syncQueueKey);
      if (queueJson != null) {
        final queue = json.decode(queueJson) as List;
        _pendingOperations = queue.length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading pending operations: $e');
    }
  }

  /// Add operation to sync queue for offline execution
  Future<void> queueOperation({
    required String type, // 'create', 'update', 'delete'
    required String collection,
    String? documentId,
    Map<String, dynamic>? data,
    String? tempId, // For optimistic updates
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
      
      _pendingOperations = queue.length;
      notifyListeners();

      debugPrint('Operation queued: $type $collection');
    } catch (e) {
      debugPrint('Error queueing operation: $e');
    }
  }

  /// Sync all pending operations
  Future<void> syncPendingOperations() async {
    if (_isSyncing || !_firebase.isUserAuthenticated) return;

    try {
      _setSyncing(true);
      _clearError();

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
          
          // Increment retry count
          operation['retryCount'] = (operation['retryCount'] ?? 0) + 1;
          
          // Remove operation if it failed too many times
          if (operation['retryCount'] >= 3) {
            successfulOperations.add(i);
            debugPrint('Operation removed after 3 failed attempts');
          }
        }
      }

      // Remove successful operations from queue
      for (int i = successfulOperations.length - 1; i >= 0; i--) {
        queue.removeAt(successfulOperations[i]);
      }

      await prefs.setString(_syncQueueKey, json.encode(queue));
      _pendingOperations = queue.length;
      
      _lastSyncTime = DateTime.now();
      await _saveSyncState();

      debugPrint('Sync completed. ${successfulOperations.length} operations synced, ${queue.length} remaining');
      
    } catch (e) {
      _setError('Erro na sincronização: $e');
      debugPrint('Sync error: $e');
    } finally {
      _setSyncing(false);
    }
  }

  /// Execute a single sync operation
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

  /// Create operations with offline support
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
        // Queue for later sync
        await queueOperation(
          type: 'create',
          collection: collection,
          data: data,
          tempId: tempId,
        );
        return tempId;
      }
    } else {
      // Queue for later sync
      await queueOperation(
        type: 'create',
        collection: collection,
        data: data,
        tempId: tempId,
      );
      return tempId;
    }
  }

  /// Update operations with offline support
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
        // Queue for later sync
        await queueOperation(
          type: 'update',
          collection: collection,
          documentId: documentId,
          data: data,
        );
        return false;
      }
    } else {
      // Queue for later sync
      await queueOperation(
        type: 'update',
        collection: collection,
        documentId: documentId,
        data: data,
      );
      return false;
    }
  }

  /// Delete operations with offline support
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
        // Queue for later sync
        await queueOperation(
          type: 'delete',
          collection: collection,
          documentId: documentId,
        );
        return false;
      }
    } else {
      // Queue for later sync
      await queueOperation(
        type: 'delete',
        collection: collection,
        documentId: documentId,
      );
      return false;
    }
  }

  /// Clear all pending operations (use with caution)
  Future<void> clearPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_syncQueueKey);
      _pendingOperations = 0;
      notifyListeners();
      debugPrint('All pending operations cleared');
    } catch (e) {
      debugPrint('Error clearing pending operations: $e');
    }
  }

  /// Get details of pending operations
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

  /// Manual sync trigger
  Future<void> forcSync() async {
    await syncPendingOperations();
  }

  /// Check if device has network connectivity (simplified)
  Future<bool> hasNetworkConnectivity() async {
    try {
      // This is a simple check - in production you might want to use connectivity_plus package
      await _firebase.firestore.collection('_connectivity_test').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Auto-sync on app resume
  void onAppResumed() {
    if (hasPendingOperations) {
      syncPendingOperations();
    }
  }

  /// Auto-sync on network restored
  void onNetworkRestored() {
    if (hasPendingOperations) {
      syncPendingOperations();
    }
  }

  /// State management helpers
  void _setSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  void _setError(String error) {
    _syncError = error;
    notifyListeners();
  }

  void _clearError() {
    _syncError = null;
    notifyListeners();
  }

  /// Get sync status summary
  Map<String, dynamic> getSyncStatus() {
    return {
      'isSyncing': _isSyncing,
      'pendingOperations': _pendingOperations,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'hasError': _syncError != null,
      'error': _syncError,
    };
  }

  /// Export pending operations for debugging
  Future<String> exportPendingOperations() async {
    final operations = await getPendingOperations();
    return json.encode(operations);
  }

  @override
  void dispose() {
    // Cleanup if needed
    super.dispose();
  }
}

/// Helper class for conflict resolution
class ConflictResolver {
  /// Resolve conflicts between local and remote data
  static Map<String, dynamic> resolveConflict({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.lastWriteWins,
  }) {
    switch (strategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        return _lastWriteWins(localData, remoteData);
      case ConflictResolutionStrategy.localWins:
        return localData;
      case ConflictResolutionStrategy.remoteWins:
        return remoteData;
      case ConflictResolutionStrategy.merge:
        return _mergeData(localData, remoteData);
    }
  }

  static Map<String, dynamic> _lastWriteWins(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final localUpdate = localData['updatedAt'] as DateTime?;
    final remoteUpdate = remoteData['updatedAt'] as DateTime?;

    if (localUpdate == null && remoteUpdate == null) {
      return remoteData; // Default to remote
    }
    if (localUpdate == null) return remoteData;
    if (remoteUpdate == null) return localData;

    return localUpdate.isAfter(remoteUpdate) ? localData : remoteData;
  }

  static Map<String, dynamic> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final merged = Map<String, dynamic>.from(remoteData);
    
    // Merge non-conflicting fields from local data
    localData.forEach((key, value) {
      if (!merged.containsKey(key) || merged[key] == null) {
        merged[key] = value;
      }
    });

    return merged;
  }
}

enum ConflictResolutionStrategy {
  lastWriteWins,
  localWins,
  remoteWins,
  merge,
}