/// Modelos para o sistema de dual screen e displays externos
/// IMPORTANTE: Renomeado ConnectionState para DisplayConnectionState para evitar conflito com Flutter widgets
import 'package:flutter/material.dart' hide ConnectionState;

enum DisplayType {
  /// Display físico conectado via HDMI/USB-C
  hdmi,
  /// Display físico conectado via USB-C
  usbC,
  /// Chromecast via Google Cast
  chromecast,
  /// Apple TV via AirPlay
  airplay,
  /// Smart TV com Android TV
  androidTv,
  /// Amazon Fire TV
  fireTV,
  /// Miracast (protocolo Windows)
  miracast,
  /// Browser window (para web)
  webWindow,
  /// Display nativo dual screen (folding devices)
  nativeDualScreen,
}

enum DisplayConnectionState {
  /// Dispositivo não detectado
  notDetected,
  /// Dispositivo detectado mas não conectado
  detected,
  /// Tentando conectar
  connecting,
  /// Conectado e pronto para uso
  connected,
  /// Apresentando conteúdo atualmente
  presenting,
  /// Conexão perdida/com erro
  disconnected,
  /// Erro de conexão
  error,
}

enum DisplayCapability {
  /// Suporte a áudio
  audio,
  /// Suporte a vídeo
  video,
  /// Suporte a imagens
  images,
  /// Controle remoto de reprodução
  remoteControl,
  /// Sincronização de slides
  slideSync,
  /// Streaming em tempo real
  realTimeStreaming,
  /// Qualidade alta (1080p+)
  highQuality,
  /// Qualidade 4K
  ultraHighQuality,
}

/// Representa um display externo disponível
class ExternalDisplay {
  final String id;
  final String name;
  final DisplayType type;
  final DisplayConnectionState state;
  final List<DisplayCapability> capabilities;
  final String? ipAddress;
  final String? model;
  final String? manufacturer;
  final int? width;
  final int? height;
  final double? refreshRate;
  final Map<String, dynamic>? metadata;

  const ExternalDisplay({
    required this.id,
    required this.name,
    required this.type,
    required this.state,
    required this.capabilities,
    this.ipAddress,
    this.model,
    this.manufacturer,
    this.width,
    this.height,
    this.refreshRate,
    this.metadata,
  });

  /// Cria uma cópia com campos atualizados
  ExternalDisplay copyWith({
    String? id,
    String? name,
    DisplayType? type,
    DisplayConnectionState? state,
    List<DisplayCapability>? capabilities,
    String? ipAddress,
    String? model,
    String? manufacturer,
    int? width,
    int? height,
    double? refreshRate,
    Map<String, dynamic>? metadata,
  }) {
    return ExternalDisplay(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      state: state ?? this.state,
      capabilities: capabilities ?? this.capabilities,
      ipAddress: ipAddress ?? this.ipAddress,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      width: width ?? this.width,
      height: height ?? this.height,
      refreshRate: refreshRate ?? this.refreshRate,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Verifica se o display está conectado
  bool get isConnected => state == DisplayConnectionState.connected || state == DisplayConnectionState.presenting;

  /// Verifica se o display está apresentando
  bool get isPresenting => state == DisplayConnectionState.presenting;

  /// Verifica se o display pode ser usado para apresentação
  bool get canPresent => isConnected && !isPresenting;

  /// Verifica se o display suporta uma capability específica
  bool hasCapability(DisplayCapability capability) => capabilities.contains(capability);

  /// Verifica se é um display wireless
  bool get isWireless => [
    DisplayType.chromecast,
    DisplayType.airplay,
    DisplayType.androidTv,
    DisplayType.fireTV,
    DisplayType.miracast,
    DisplayType.webWindow,
  ].contains(type);

  /// Verifica se é um display físico
  bool get isPhysical => [
    DisplayType.hdmi,
    DisplayType.usbC,
    DisplayType.nativeDualScreen,
  ].contains(type);

  /// Obter resolução como string
  String? get resolution {
    if (width != null && height != null) {
      return '${width}x${height}';
    }
    return null;
  }

  /// Obter ícone apropriado para o tipo de display
  String get iconName {
    switch (type) {
      case DisplayType.hdmi:
      case DisplayType.usbC:
        return 'hdmi';
      case DisplayType.chromecast:
        return 'cast';
      case DisplayType.airplay:
        return 'airplay';
      case DisplayType.androidTv:
        return 'tv';
      case DisplayType.fireTV:
        return 'tv';
      case DisplayType.miracast:
        return 'screen_share';
      case DisplayType.webWindow:
        return 'web';
      case DisplayType.nativeDualScreen:
        return 'devices_fold';
    }
  }

  /// Converter para Map (para serialização)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'state': state.name,
      'capabilities': capabilities.map((c) => c.name).toList(),
      'ipAddress': ipAddress,
      'model': model,
      'manufacturer': manufacturer,
      'width': width,
      'height': height,
      'refreshRate': refreshRate,
      'metadata': metadata,
    };
  }

  /// Criar a partir de Map (para deserialização)
  factory ExternalDisplay.fromMap(Map<String, dynamic> map) {
    return ExternalDisplay(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: DisplayType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DisplayType.webWindow,
      ),
      state: DisplayConnectionState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => DisplayConnectionState.notDetected,
      ),
      capabilities: (map['capabilities'] as List<dynamic>?)
          ?.map((c) => DisplayCapability.values.firstWhere(
                (e) => e.name == c,
                orElse: () => DisplayCapability.images,
              ))
          .toList() ?? [],
      ipAddress: map['ipAddress'],
      model: map['model'],
      manufacturer: map['manufacturer'],
      width: map['width'],
      height: map['height'],
      refreshRate: map['refreshRate']?.toDouble(),
      metadata: map['metadata'],
    );
  }

  @override
  String toString() {
    return 'ExternalDisplay(id: $id, name: $name, type: $type, state: $state)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExternalDisplay && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Configurações de conexão para um display
class DisplayConnectionConfig {
  final String displayId;
  final String displayName;
  final int quality; // 1-100
  final bool autoConnect;
  final bool rememberDevice;
  final String? preferredResolution;
  final int? refreshRate;
  final DateTime? lastConnected;
  final Map<String, dynamic> customSettings;

  const DisplayConnectionConfig({
    required this.displayId,
    required this.displayName,
    this.quality = 80,
    this.autoConnect = false,
    this.rememberDevice = true,
    this.preferredResolution,
    this.refreshRate,
    this.lastConnected,
    this.customSettings = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'displayId': displayId,
      'displayName': displayName,
      'quality': quality,
      'autoConnect': autoConnect,
      'rememberDevice': rememberDevice,
      'preferredResolution': preferredResolution,
      'refreshRate': refreshRate,
      'lastConnected': lastConnected?.toIso8601String(),
      'customSettings': customSettings,
    };
  }

  factory DisplayConnectionConfig.fromMap(Map<String, dynamic> map) {
    return DisplayConnectionConfig(
      displayId: map['displayId'] ?? '',
      displayName: map['displayName'] ?? '',
      quality: map['quality'] ?? 80,
      autoConnect: map['autoConnect'] ?? false,
      rememberDevice: map['rememberDevice'] ?? true,
      preferredResolution: map['preferredResolution'],
      refreshRate: map['refreshRate'],
      lastConnected: map['lastConnected'] != null 
        ? DateTime.parse(map['lastConnected'])
        : null,
      customSettings: map['customSettings'] ?? {},
    );
  }
}

/// Evento de mudança de estado do display
class DisplayStateChangeEvent {
  final ExternalDisplay display;
  final DisplayConnectionState previousState;
  final DisplayConnectionState newState;
  final String? message;
  final DateTime timestamp;

  DisplayStateChangeEvent({
    required this.display,
    required this.previousState,
    required this.newState,
    this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'DisplayStateChange(${display.name}: $previousState -> $newState)';
  }
}