import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:versee/services/display_manager.dart';
import 'package:versee/services/language_service.dart';
import 'package:versee/services/media_sync_service.dart';
import 'package:versee/models/display_models.dart';

/// Página dedicada para configuração e descoberta de displays externos
/// Interface profissional para gerenciamento completo de displays
class DisplaySetupPage extends StatefulWidget {
  const DisplaySetupPage({super.key});

  @override
  State<DisplaySetupPage> createState() => _DisplaySetupPageState();
}

class _DisplaySetupPageState extends State<DisplaySetupPage> with TickerProviderStateMixin {
  late DisplayManager _displayManager;
  late LanguageService _languageService;
  late AnimationController _scanAnimationController;
  late AnimationController _connectionAnimationController;
  
  List<ExternalDisplay> _availableDisplays = [];
  List<ExternalDisplay> _savedDisplays = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectionError;
  ExternalDisplay? _connectingDisplay;
  Timer? _autoScanTimer;
  
  // Configurações avançadas
  bool _autoDiscoveryEnabled = true;
  Duration _scanInterval = const Duration(seconds: 30);
  bool _rememberConnections = true;
  bool _autoConnectToSaved = false;
  
  @override
  void initState() {
    super.initState();
    _displayManager = Provider.of<DisplayManager>(context, listen: false);
    _languageService = Provider.of<LanguageService>(context, listen: false);
    
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _connectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _initializeDisplaySetup();
  }
  
  @override
  void dispose() {
    _scanAnimationController.dispose();
    _connectionAnimationController.dispose();
    _autoScanTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _initializeDisplaySetup() async {
    try {
      // Carregar displays salvos
      _savedDisplays = await _displayManager.getSavedDisplays();
      
      // Executar scan inicial
      await _performDisplayScan();
      
      // Configurar auto-discovery se habilitado
      if (_autoDiscoveryEnabled) {
        _startAutoDiscovery();
      }
      
      // Auto-conectar se habilitado e há displays salvos
      if (_autoConnectToSaved && _savedDisplays.isNotEmpty) {
        await _autoConnectToPreferred();
      }
      
    } catch (e) {
      _showError('Erro na inicialização: $e');
    }
  }
  
  void _startAutoDiscovery() {
    _autoScanTimer?.cancel();
    _autoScanTimer = Timer.periodic(_scanInterval, (timer) {
      if (!_isScanning && !_isConnecting) {
        _performDisplayScan(silent: true);
      }
    });
  }
  
  Future<void> _performDisplayScan({bool silent = false}) async {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
      _connectionError = null;
    });
    
    if (!silent) {
      _scanAnimationController.repeat();
    }
    
    try {
      final displays = await _displayManager.scanForDisplays(
        timeout: const Duration(seconds: 10),
      );
      
      setState(() {
        _availableDisplays = displays;
      });
      
      if (!silent) {
        _showScanResults(displays.length);
      }
      
    } catch (e) {
      if (!silent) {
        _showError('Erro durante scan: $e');
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
      
      if (!silent) {
        _scanAnimationController.stop();
        _scanAnimationController.reset();
      }
    }
  }
  
  Future<void> _connectToDisplay(ExternalDisplay display) async {
    if (_isConnecting) return;
    
    setState(() {
      _isConnecting = true;
      _connectingDisplay = display;
      _connectionError = null;
    });
    
    _connectionAnimationController.repeat();
    
    try {
      // Configuração de conexão
      final config = DisplayConnectionConfig(
        displayId: display.id,
        displayName: display.name,
        autoConnect: _autoConnectToSaved,
        rememberDevice: _rememberConnections,
        preferredResolution: '1920x1080',
        refreshRate: 60,
        lastConnected: DateTime.now(),
      );
      
      final success = await _displayManager.connectToDisplay(
        display.id,
        config: config,
      );
      
      if (success) {
        _showSuccess('Conectado a ${display.name}');
        
        // Atualizar lista de displays salvos
        if (_rememberConnections) {
          _savedDisplays = await _displayManager.getSavedDisplays();
        }
        
        // Navegar de volta se conexão bem-sucedida
        if (mounted) {
          Navigator.pop(context, display);
        }
      } else {
        setState(() {
          _connectionError = 'Falha ao conectar a ${display.name}';
        });
      }
      
    } catch (e) {
      setState(() {
        _connectionError = 'Erro de conexão: $e';
      });
    } finally {
      setState(() {
        _isConnecting = false;
        _connectingDisplay = null;
      });
      
      _connectionAnimationController.stop();
      _connectionAnimationController.reset();
    }
  }
  
  Future<void> _autoConnectToPreferred() async {
    if (_savedDisplays.isEmpty) return;
    
    // Procurar display preferido nos disponíveis
    for (final saved in _savedDisplays) {
      final available = _availableDisplays.where((d) => d.id == saved.id).firstOrNull;
      if (available != null && available.state == DisplayConnectionState.detected) {
        await _connectToDisplay(available);
        break;
      }
    }
  }
  
  Future<void> _testDisplayConnection(ExternalDisplay display) async {
    try {
      final result = await _displayManager.testConnection(display.id);
      
      if (result) {
        _showSuccess('Teste de conexão bem-sucedido');
      } else {
        _showError('Teste de conexão falhou');
      }
    } catch (e) {
      _showError('Erro no teste: $e');
    }
  }
  
  Future<void> _calibrateDisplayLatency(ExternalDisplay display) async {
    try {
      _showInfo('Calibrando latência...');
      
      // Assumindo que temos MediaSyncService disponível
      final mediaSyncService = Provider.of<MediaSyncService>(context, listen: false);
      final latency = await mediaSyncService.calibrateDisplayLatency(display.id);
      
      _showSuccess('Latência calibrada: ${latency.toStringAsFixed(1)}ms');
    } catch (e) {
      _showError('Erro na calibração: $e');
    }
  }
  
  Future<void> _forgetDisplay(ExternalDisplay display) async {
    try {
      await _displayManager.removeDisplayConfig(display.id);
      _savedDisplays = await _displayManager.getSavedDisplays();
      setState(() {});
      _showInfo('Display removido da lista');
    } catch (e) {
      _showError('Erro ao remover: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Status e controles principais
          _buildStatusHeader(),
          
          // Tabs para diferentes seções
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildAvailableDisplaysTab(),
                        _buildSavedDisplaysTab(),
                        _buildAdvancedSettingsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildScanButton(),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2A2A2A),
      title: Text(
        _languageService.strings.displaySetup,
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: _showDiagnostics,
          icon: const Icon(Icons.info_outline, color: Colors.white),
          tooltip: _languageService.strings.displayDiagnostics,
        ),
        IconButton(
          onPressed: _showHelp,
          icon: const Icon(Icons.help_outline, color: Colors.white),
          tooltip: _languageService.strings.help,
        ),
      ],
    );
  }
  
  Widget _buildStatusHeader() {
    return Consumer<DisplayManager>(
      builder: (context, displayManager, child) {
        final hasConnectedDisplay = displayManager.hasConnectedDisplay;
        final connectedDisplay = displayManager.connectedDisplay;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasConnectedDisplay ? Colors.green.shade900 : const Color(0xFF2A2A2A),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasConnectedDisplay ? Icons.cast_connected : Icons.cast,
                color: hasConnectedDisplay ? Colors.green : Colors.white70,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasConnectedDisplay 
                        ? connectedDisplay!.name
                        : _languageService.strings.displayNoConnectedDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      hasConnectedDisplay
                        ? _getDisplayStatusText(connectedDisplay!.state)
                        : '${_availableDisplays.length} ${_languageService.strings.displayAvailableDisplays}',
                      style: TextStyle(
                        color: hasConnectedDisplay 
                          ? Colors.green.shade300
                          : Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasConnectedDisplay) ...[
                IconButton(
                  onPressed: () => _testDisplayConnection(connectedDisplay!),
                  icon: const Icon(Icons.wifi_tethering, color: Colors.white),
                  tooltip: _languageService.strings.displayTestConnection,
                ),
                IconButton(
                  onPressed: () async {
                    await displayManager.disconnect();
                    _showInfo(_languageService.strings.displayDisconnected);
                  },
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  tooltip: _languageService.strings.displayDisconnect,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTabBar() {
    return TabBar(
      indicatorColor: Colors.blue,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      tabs: [
        Tab(
          icon: const Icon(Icons.search),
          text: _languageService.strings.displayAvailable,
        ),
        Tab(
          icon: const Icon(Icons.bookmark),
          text: _languageService.strings.displaySaved,
        ),
        Tab(
          icon: const Icon(Icons.settings),
          text: _languageService.strings.displayAdvanced,
        ),
      ],
    );
  }
  
  Widget _buildAvailableDisplaysTab() {
    if (_isScanning) {
      return _buildScanningIndicator();
    }
    
    if (_availableDisplays.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableDisplays.length,
      itemBuilder: (context, index) {
        final display = _availableDisplays[index];
        return _buildDisplayCard(display, isAvailable: true);
      },
    );
  }
  
  Widget _buildSavedDisplaysTab() {
    if (_savedDisplays.isEmpty) {
      return _buildEmptySavedState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedDisplays.length,
      itemBuilder: (context, index) {
        final display = _savedDisplays[index];
        return _buildDisplayCard(display, isSaved: true);
      },
    );
  }
  
  Widget _buildAdvancedSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsSection(
          title: _languageService.strings.displayAutoDiscovery,
          children: [
            SwitchListTile(
              title: Text(_languageService.strings.displayEnableAutoDiscovery),
              subtitle: Text(_languageService.strings.displayAutoDiscoveryDesc),
              value: _autoDiscoveryEnabled,
              onChanged: (value) {
                setState(() {
                  _autoDiscoveryEnabled = value;
                });
                if (value) {
                  _startAutoDiscovery();
                } else {
                  _autoScanTimer?.cancel();
                }
              },
            ),
            if (_autoDiscoveryEnabled) ...[
              ListTile(
                title: Text(_languageService.strings.displayScanInterval),
                subtitle: Text('${_scanInterval.inSeconds}s'),
                trailing: DropdownButton<Duration>(
                  value: _scanInterval,
                  items: [
                    DropdownMenuItem(value: const Duration(seconds: 15), child: Text('15s')),
                    DropdownMenuItem(value: const Duration(seconds: 30), child: Text('30s')),
                    DropdownMenuItem(value: const Duration(minutes: 1), child: Text('1min')),
                    DropdownMenuItem(value: const Duration(minutes: 2), child: Text('2min')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _scanInterval = value;
                      });
                      _startAutoDiscovery();
                    }
                  },
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 20),
        
        _buildSettingsSection(
          title: _languageService.strings.displayConnectionSettings,
          children: [
            SwitchListTile(
              title: Text(_languageService.strings.displayRememberConnections),
              subtitle: Text(_languageService.strings.displayRememberConnectionsDesc),
              value: _rememberConnections,
              onChanged: (value) {
                setState(() {
                  _rememberConnections = value;
                });
              },
            ),
            SwitchListTile(
              title: Text(_languageService.strings.displayAutoConnect),
              subtitle: Text(_languageService.strings.displayAutoConnectDesc),
              value: _autoConnectToSaved,
              onChanged: (value) {
                setState(() {
                  _autoConnectToSaved = value;
                });
              },
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        _buildSettingsSection(
          title: _languageService.strings.displaySystemInfo,
          children: [
            ListTile(
              title: Text(_languageService.strings.displayPlatformCapabilities),
              subtitle: Text(_getPlatformCapabilitiesText()),
              trailing: const Icon(Icons.info),
              onTap: _showPlatformCapabilities,
            ),
            ListTile(
              title: Text(_languageService.strings.displayDiagnostics),
              subtitle: Text(_languageService.strings.displayViewDiagnostics),
              trailing: const Icon(Icons.assessment),
              onTap: _showDiagnostics,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          color: const Color(0xFF2A2A2A),
          child: Column(children: children),
        ),
      ],
    );
  }
  
  Widget _buildDisplayCard(ExternalDisplay display, {bool isAvailable = false, bool isSaved = false}) {
    final isConnecting = _isConnecting && _connectingDisplay?.id == display.id;
    
    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Stack(
          children: [
            Icon(
              _getDisplayTypeIcon(display.type),
              color: _getDisplayStatusColor(display.state),
              size: 32,
            ),
            if (isConnecting)
              Positioned.fill(
                child: RotationTransition(
                  turns: _connectionAnimationController,
                  child: const Icon(
                    Icons.sync,
                    color: Colors.orange,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          display.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getDisplayTypeLabel(display.type),
              style: const TextStyle(color: Colors.white70),
            ),
            Row(
              children: [
                Icon(
                  _getDisplayStateIcon(display.state),
                  color: _getDisplayStatusColor(display.state),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _getDisplayStatusText(display.state),
                  style: TextStyle(
                    color: _getDisplayStatusColor(display.state),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informações do display
                _buildDisplayInfo(display),
                
                const SizedBox(height: 16),
                
                // Ações disponíveis
                _buildDisplayActions(display, isAvailable: isAvailable, isSaved: isSaved),
                
                // Erro de conexão se houver
                if (_connectionError != null && _connectingDisplay?.id == display.id) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _connectionError!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDisplayInfo(ExternalDisplay display) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _languageService.strings.displayInformation,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('ID', display.id),
        _buildInfoRow(_languageService.strings.displayType, _getDisplayTypeLabel(display.type)),
        _buildInfoRow(_languageService.strings.displayState, _getDisplayStatusText(display.state)),
        if (display.capabilities.isNotEmpty)
          _buildInfoRow(
            _languageService.strings.displayCapabilities,
            display.capabilities.map((c) => c.toString().split('.').last).join(', '),
          ),
        if (display.metadata?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(
            _languageService.strings.displayMetadata,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          ...display.metadata!.entries.map((e) => _buildInfoRow(e.key, e.value.toString())),
        ],
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDisplayActions(ExternalDisplay display, {bool isAvailable = false, bool isSaved = false}) {
    final isConnecting = _isConnecting && _connectingDisplay?.id == display.id;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (isAvailable && display.state == DisplayConnectionState.detected) ...[
          ElevatedButton.icon(
            onPressed: isConnecting ? null : () => _connectToDisplay(display),
            icon: Icon(isConnecting ? Icons.sync : Icons.link),
            label: Text(isConnecting ? _languageService.strings.displayConnecting : _languageService.strings.displayConnect),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        
        if (display.state == DisplayConnectionState.connected) ...[
          ElevatedButton.icon(
            onPressed: () => _testDisplayConnection(display),
            icon: const Icon(Icons.wifi_tethering),
            label: Text(_languageService.strings.displayTest),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        
        ElevatedButton.icon(
          onPressed: () => _calibrateDisplayLatency(display),
          icon: const Icon(Icons.speed),
          label: Text(_languageService.strings.displayCalibrateLatency),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
        
        if (isSaved) ...[
          ElevatedButton.icon(
            onPressed: () => _forgetDisplay(display),
            icon: const Icon(Icons.delete),
            label: Text(_languageService.strings.displayForget),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildScanningIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _scanAnimationController,
            child: const Icon(
              Icons.radar,
              color: Colors.blue,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _languageService.strings.displayScanning,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _languageService.strings.displayScanningDesc,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            _languageService.strings.displayNoDisplaysFound,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _languageService.strings.displayNoDisplaysFoundDesc,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _performDisplayScan,
            icon: const Icon(Icons.refresh),
            label: Text(_languageService.strings.displayScanAgain),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptySavedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bookmark_border,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            _languageService.strings.displayNoSavedDisplays,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _languageService.strings.displayNoSavedDisplaysDesc,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildScanButton() {
    return FloatingActionButton.extended(
      onPressed: _isScanning ? null : _performDisplayScan,
      backgroundColor: _isScanning ? Colors.grey : Colors.blue,
      icon: _isScanning
        ? RotationTransition(
            turns: _scanAnimationController,
            child: const Icon(Icons.refresh),
          )
        : const Icon(Icons.search),
      label: Text(_isScanning ? _languageService.strings.displayScanning : _languageService.strings.displayScanForDevices),
    );
  }
  
  // Métodos auxiliares
  IconData _getDisplayTypeIcon(DisplayType type) {
    switch (type) {
      case DisplayType.hdmi: return Icons.cable;
      case DisplayType.usbC: return Icons.usb;
      case DisplayType.chromecast: return Icons.cast;
      case DisplayType.airplay: return Icons.airplay;
      case DisplayType.webWindow: return Icons.web;
      default: return Icons.monitor;
    }
  }
  
  String _getDisplayTypeLabel(DisplayType type) {
    switch (type) {
      case DisplayType.hdmi: return 'HDMI';
      case DisplayType.usbC: return 'USB-C';
      case DisplayType.chromecast: return 'Chromecast';
      case DisplayType.airplay: return 'AirPlay';
      case DisplayType.webWindow: return _languageService.strings.displayWebWindow;
      default: return _languageService.strings.displayExternal;
    }
  }
  
  IconData _getDisplayStateIcon(DisplayConnectionState state) {
    switch (state) {
      case DisplayConnectionState.connected: return Icons.check_circle;
      case DisplayConnectionState.connecting: return Icons.sync;
      case DisplayConnectionState.detected: return Icons.visibility;
      case DisplayConnectionState.error: return Icons.error;
      default: return Icons.help;
    }
  }
  
  String _getDisplayStatusText(DisplayConnectionState state) {
    switch (state) {
      case DisplayConnectionState.connected: return _languageService.strings.displayConnected;
      case DisplayConnectionState.connecting: return _languageService.strings.displayConnecting;
      case DisplayConnectionState.presenting: return _languageService.strings.displayPresenting;
      case DisplayConnectionState.detected: return _languageService.strings.displayDetected;
      case DisplayConnectionState.error: return _languageService.strings.displayError;
      default: return _languageService.strings.displayUnknown;
    }
  }
  
  Color _getDisplayStatusColor(DisplayConnectionState state) {
    switch (state) {
      case DisplayConnectionState.connected:
      case DisplayConnectionState.presenting: return Colors.green;
      case DisplayConnectionState.connecting: return Colors.orange;
      case DisplayConnectionState.detected: return Colors.blue;
      case DisplayConnectionState.error: return Colors.red;
      default: return Colors.grey;
    }
  }
  
  String _getPlatformCapabilitiesText() {
    // TODO: Integrar com DisplayFactory.platformCapabilities
    return 'Web: Múltiplas janelas, Mobile: Displays nativos';
  }
  
  void _showPlatformCapabilities() {
    // TODO: Mostrar diálogo com capabilities detalhadas
    _showInfo('Funcionalidade em desenvolvimento');
  }
  
  Future<void> _showDiagnostics() async {
    try {
      final diagnostics = await _displayManager.getDiagnosticInfo();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_languageService.strings.displayDiagnostics),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: diagnostics.entries.map((e) {
                return ListTile(
                  title: Text(e.key),
                  subtitle: Text(e.value.toString()),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_languageService.strings.close),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Erro ao obter diagnósticos: $e');
    }
  }
  
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_languageService.strings.help),
        content: Text(_languageService.strings.displaySetupHelp),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_languageService.strings.close),
          ),
        ],
      ),
    );
  }
  
  void _showScanResults(int count) {
    _showInfo('$count ${_languageService.strings.displayFoundDisplays}');
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
}