import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    // Platform channel para informações gerais da plataforma
    let platformChannel = FlutterMethodChannel(name: "versee/platform", binaryMessenger: controller.binaryMessenger)
    platformChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "getScreenDimensions":
        let screen = UIScreen.main
        let bounds = screen.bounds
        let scale = screen.scale
        
        let dimensions = [
          "width": Int(bounds.width * scale),
          "height": Int(bounds.height * scale),
          "density": scale,
          "scaledDensity": scale
        ]
        result(dimensions)
        
      case "getDiagnosticInfo":
        let info = [
          "platform": "ios",
          "version": UIDevice.current.systemVersion,
          "model": UIDevice.current.model,
          "name": UIDevice.current.name,
          "systemName": UIDevice.current.systemName
        ]
        result(info)
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    // Display channel para funcionalidades de display externo
    let displayChannel = FlutterMethodChannel(name: "versee/display_manager", binaryMessenger: controller.binaryMessenger)
    displayChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "getPhysicalDisplays":
        self.getPhysicalDisplays(result: result)
        
      case "scanAirPlayDevices":
        self.scanAirPlayDevices(result: result)
        
      case "connectToAirPlay":
        if let args = call.arguments as? [String: Any],
           let identifier = args["identifier"] as? String {
          self.connectToAirPlay(identifier: identifier, result: result)
        } else {
          result(false)
        }
        
      case "disconnectAirPlay":
        self.disconnectAirPlay(result: result)
        
      case "testDisplayConnection":
        if let args = call.arguments as? [String: Any],
           let displayId = args["displayId"] as? String {
          self.testDisplayConnection(displayId: displayId, result: result)
        } else {
          result(false)
        }
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func getPhysicalDisplays(result: @escaping FlutterResult) {
    // iOS suporta displays externos via AirPlay ou cabo
    var displays: [[String: Any]] = []
    
    for screen in UIScreen.screens {
      if screen != UIScreen.main {
        let bounds = screen.bounds
        let scale = screen.scale
        
        let display = [
          "id": "external_\(screen.hash)",
          "name": "Display Externo",
          "width": Int(bounds.width * scale),
          "height": Int(bounds.height * scale),
          "scale": scale,
          "isMain": false
        ] as [String: Any]
        
        displays.append(display)
      }
    }
    
    result(displays)
  }
  
  private func scanAirPlayDevices(result: @escaping FlutterResult) {
    // Implementação básica - seria necessário AirPlay SDK ou APIs específicas
    // Por enquanto, retornar lista vazia para compilação
    let devices: [[String: Any]] = []
    result(devices)
  }
  
  private func connectToAirPlay(identifier: String, result: @escaping FlutterResult) {
    // Implementação básica - seria necessário AirPlay SDK
    // Por enquanto, simular falha para indicar que não está implementado
    result(false)
  }
  
  private func disconnectAirPlay(result: @escaping FlutterResult) {
    // Implementação básica - seria necessário AirPlay SDK
    result(true)
  }
  
  private func testDisplayConnection(displayId: String, result: @escaping FlutterResult) {
    for screen in UIScreen.screens {
      if "external_\(screen.hash)" == displayId {
        result(true)
        return
      }
    }
    result(false)
  }
}
