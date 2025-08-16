import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/storage_analysis_service.dart';
import 'package:versee/services/auth_service.dart';
import 'package:versee/pages/storage_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to monitor storage usage in real-time and provide notifications
/// when approaching limits
class StorageMonitoringService with ChangeNotifier {
  static const String _lastAnalysisKey = 'last_storage_analysis';
  static const String _notificationShownKey = 'storage_notification_shown';
  static const Duration _analysisInterval = Duration(minutes: 30);
  
  Timer? _monitoringTimer;
  BuildContext? _context;
  StorageAnalysisService? _storageAnalysisService;
  
  bool _isMonitoring = false;
  DateTime? _lastAnalysis;
  bool _hasShownWarning = false;
  
  bool get isMonitoring => _isMonitoring;
  DateTime? get lastAnalysis => _lastAnalysis;

  /// Initialize the monitoring service
  void initialize(BuildContext context) {
    _context = context;
    _storageAnalysisService = Provider.of<StorageAnalysisService>(context, listen: false);
    _loadLastAnalysisTime();
  }

  /// Start monitoring storage usage
  void startMonitoring() {
    if (_isMonitoring || _context == null) return;
    
    _isMonitoring = true;
    
    // Perform initial analysis
    _performAnalysis();
    
    // Set up periodic monitoring
    _monitoringTimer = Timer.periodic(_analysisInterval, (timer) {
      _performAnalysis();
    });
    
    debugPrint('Storage monitoring started');
    notifyListeners();
  }

  /// Stop monitoring storage usage
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;
    
    debugPrint('Storage monitoring stopped');
    notifyListeners();
  }

  /// Perform a manual storage analysis
  Future<void> forceAnalysis() async {
    if (_context == null || _storageAnalysisService == null) return;
    
    try {
      await _storageAnalysisService!.analyzeStorageUsage(_context!);
      _lastAnalysis = DateTime.now();
      _saveLastAnalysisTime();
      
      await _checkStorageStatus();
      notifyListeners();
    } catch (e) {
      debugPrint('Error in forced storage analysis: $e');
    }
  }

  /// Internal method to perform periodic analysis
  Future<void> _performAnalysis() async {
    if (_context == null || _storageAnalysisService == null) return;
    
    try {
      await _storageAnalysisService!.analyzeStorageUsage(_context!);
      _lastAnalysis = DateTime.now();
      _saveLastAnalysisTime();
      
      await _checkStorageStatus();
      notifyListeners();
    } catch (e) {
      debugPrint('Error in storage analysis: $e');
    }
  }

  /// Check storage status and show warnings if needed
  Future<void> _checkStorageStatus() async {
    final usage = _storageAnalysisService?.currentUsage;
    if (usage == null) return;

    // Check if we should show a storage warning
    if (usage.isOverLimit) {
      await _showStorageExceededNotification(usage);
    } else if (usage.isNearLimit && !_hasShownWarning) {
      await _showStorageWarningNotification(usage);
      _hasShownWarning = true;
    } else if (!usage.isNearLimit && _hasShownWarning) {
      // Reset warning flag if storage usage drops below warning threshold
      _hasShownWarning = false;
      await _clearNotificationShown();
    }
  }

  /// Show storage exceeded notification
  Future<void> _showStorageExceededNotification(StorageUsageData usage) async {
    if (_context == null) return;

    // Check if we should show notification today
    final shouldShow = await _shouldShowNotificationToday('exceeded');
    if (!shouldShow) return;

    if (!_context!.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(_context!);
    
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
  Future<void> _showStorageWarningNotification(StorageUsageData usage) async {
    if (_context == null) return;

    // Check if we should show notification today
    final shouldShow = await _shouldShowNotificationToday('warning');
    if (!shouldShow) return;

    if (!_context!.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(_context!);
    
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
  void _navigateToStoragePage() {
    if (_context == null || !_context!.mounted) return;
    
    Navigator.of(_context!).push(
      MaterialPageRoute(
        builder: (context) => const StoragePage(), // We'll need to import this
      ),
    );
  }

  /// Check if we should show notification today
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
      debugPrint('Error checking notification status: $e');
      return true;
    }
  }

  /// Mark notification as shown today
  Future<void> _markNotificationShown(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_notificationShownKey}_${type}';
      await prefs.setString(key, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error marking notification as shown: $e');
    }
  }

  /// Clear notification shown flag
  Future<void> _clearNotificationShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_notificationShownKey}_warning');
      await prefs.remove('${_notificationShownKey}_exceeded');
    } catch (e) {
      debugPrint('Error clearing notification flags: $e');
    }
  }

  /// Load last analysis time from preferences
  Future<void> _loadLastAnalysisTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAnalysisString = prefs.getString(_lastAnalysisKey);
      if (lastAnalysisString != null) {
        _lastAnalysis = DateTime.tryParse(lastAnalysisString);
      }
    } catch (e) {
      debugPrint('Error loading last analysis time: $e');
    }
  }

  /// Save last analysis time to preferences
  Future<void> _saveLastAnalysisTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastAnalysis != null) {
        await prefs.setString(_lastAnalysisKey, _lastAnalysis!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving last analysis time: $e');
    }
  }

  /// Get storage usage summary for quick display
  StorageUsageSummary? getUsageSummary() {
    final usage = _storageAnalysisService?.currentUsage;
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
  bool needsAnalysis() {
    if (_lastAnalysis == null) return true;
    
    final timeSinceAnalysis = DateTime.now().difference(_lastAnalysis!);
    return timeSinceAnalysis > _analysisInterval;
  }

  /// Monitor file operations and trigger analysis if needed
  void onFileOperationCompleted() {
    if (!_isMonitoring) return;
    
    // Debounce analysis calls - only analyze if it's been a while
    if (needsAnalysis()) {
      Future.delayed(const Duration(seconds: 5), () {
        if (_isMonitoring) {
          _performAnalysis();
        }
      });
    }
  }

  /// Pause monitoring (useful for battery saving)
  void pauseMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    debugPrint('Storage monitoring paused');
  }

  /// Resume monitoring
  void resumeMonitoring() {
    if (!_isMonitoring || _monitoringTimer != null) return;
    
    _monitoringTimer = Timer.periodic(_analysisInterval, (timer) {
      _performAnalysis();
    });
    debugPrint('Storage monitoring resumed');
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}

/// Lightweight summary of storage usage
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
    '${StorageAnalysisService.formatFileSize(usedBytes)} / ${StorageAnalysisService.formatFileSize(totalBytes)}';

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