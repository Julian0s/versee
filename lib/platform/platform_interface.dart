/// Interface para abstrair funcionalidades específicas de plataforma
/// Permite usar a mesma API em web, Android e iOS com implementações diferentes
abstract class PlatformInterface {
  /// Obtém a URL atual da aplicação
  String getCurrentUrl();
  
  /// Abre uma nova janela/tab (web) ou tela (mobile)
  bool openWindow(String url, {Map<String, dynamic>? options});
  
  /// Verifica se múltiplas janelas são suportadas
  bool get supportsMultipleWindows;
  
  /// Verifica se a API de fullscreen está disponível
  bool get supportsFullscreen;
  
  /// Verifica se BroadcastChannel está disponível
  bool get supportsBroadcastChannel;
  
  /// Obtém informações do user agent/dispositivo
  String get userAgent;
  
  /// Verifica se o device suporta displays externos físicos
  bool get supportsPhysicalDisplays;
  
  /// Verifica se o device suporta casting wireless
  bool get supportsWirelessCasting;
  
  /// Obtém dimensões da tela principal
  Map<String, int> get screenDimensions;
  
  /// Executa JavaScript (web) ou método nativo (mobile)
  Future<dynamic> executeNativeCode(String code, {Map<String, dynamic>? params});
  
  /// Configura listeners para eventos de display
  void setupDisplayListeners(Function(Map<String, dynamic>) onDisplayEvent);
  
  /// Remove listeners de display
  void removeDisplayListeners();
  
  /// Verifica conectividade de rede
  Future<bool> checkNetworkConnectivity();
  
  /// Salva dados localmente (localStorage web / SharedPreferences mobile)
  Future<void> saveLocalData(String key, String value);
  
  /// Carrega dados locais
  Future<String?> loadLocalData(String key);
  
  /// Remove dados locais
  Future<void> removeLocalData(String key);
}