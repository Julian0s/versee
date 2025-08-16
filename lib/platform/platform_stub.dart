import 'platform_interface.dart';

/// Stub implementation - should not be used directly
/// Will be replaced by conditional imports

class WebPlatform implements PlatformInterface {
  @override
  String getCurrentUrl() => throw UnimplementedError();
  
  @override
  bool openWindow(String url, {Map<String, dynamic>? options}) => throw UnimplementedError();
  
  @override
  bool get supportsMultipleWindows => throw UnimplementedError();
  
  @override
  bool get supportsFullscreen => throw UnimplementedError();
  
  @override
  bool get supportsBroadcastChannel => throw UnimplementedError();
  
  @override
  String get userAgent => throw UnimplementedError();
  
  @override
  bool get supportsPhysicalDisplays => throw UnimplementedError();
  
  @override
  bool get supportsWirelessCasting => throw UnimplementedError();
  
  @override
  Map<String, int> get screenDimensions => throw UnimplementedError();
  
  @override
  Future<dynamic> executeNativeCode(String code, {Map<String, dynamic>? params}) => throw UnimplementedError();
  
  @override
  void setupDisplayListeners(Function(Map<String, dynamic>) onDisplayEvent) => throw UnimplementedError();
  
  @override
  void removeDisplayListeners() => throw UnimplementedError();
  
  @override
  Future<bool> checkNetworkConnectivity() => throw UnimplementedError();
  
  @override
  Future<void> saveLocalData(String key, String value) => throw UnimplementedError();
  
  @override
  Future<String?> loadLocalData(String key) => throw UnimplementedError();
  
  @override
  Future<void> removeLocalData(String key) => throw UnimplementedError();
}

class MobilePlatform implements PlatformInterface {
  @override
  String getCurrentUrl() => throw UnimplementedError();
  
  @override
  bool openWindow(String url, {Map<String, dynamic>? options}) => throw UnimplementedError();
  
  @override
  bool get supportsMultipleWindows => throw UnimplementedError();
  
  @override
  bool get supportsFullscreen => throw UnimplementedError();
  
  @override
  bool get supportsBroadcastChannel => throw UnimplementedError();
  
  @override
  String get userAgent => throw UnimplementedError();
  
  @override
  bool get supportsPhysicalDisplays => throw UnimplementedError();
  
  @override
  bool get supportsWirelessCasting => throw UnimplementedError();
  
  @override
  Map<String, int> get screenDimensions => throw UnimplementedError();
  
  @override
  Future<dynamic> executeNativeCode(String code, {Map<String, dynamic>? params}) => throw UnimplementedError();
  
  @override
  void setupDisplayListeners(Function(Map<String, dynamic>) onDisplayEvent) => throw UnimplementedError();
  
  @override
  void removeDisplayListeners() => throw UnimplementedError();
  
  @override
  Future<bool> checkNetworkConnectivity() => throw UnimplementedError();
  
  @override
  Future<void> saveLocalData(String key, String value) => throw UnimplementedError();
  
  @override
  Future<String?> loadLocalData(String key) => throw UnimplementedError();
  
  @override
  Future<void> removeLocalData(String key) => throw UnimplementedError();
  
  Future<void> initialize() => throw UnimplementedError();
  
  void dispose() => throw UnimplementedError();
  
  Future<List<Map<String, dynamic>>> scanChromecastDevices() => throw UnimplementedError();
  
  Future<List<Map<String, dynamic>>> scanAirPlayDevices() => throw UnimplementedError();
  
  Future<bool> connectToChromecast(String deviceId, {String? appId}) => throw UnimplementedError();
  
  Future<bool> connectToAirPlay(String identifier) => throw UnimplementedError();
  
  Future<bool> disconnectFromCasting() => throw UnimplementedError();
  
  Future<List<Map<String, dynamic>>> getPhysicalDisplays() => throw UnimplementedError();
  
  Future<bool> testDisplayConnection(String displayId) => throw UnimplementedError();
  
  Future<Map<String, dynamic>> getPlatformDiagnosticInfo() => throw UnimplementedError();
  
  Map<String, bool> getMobileCapabilities() => throw UnimplementedError();
}