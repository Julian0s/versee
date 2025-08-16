package com.versee.app

import android.content.Context
import android.hardware.display.DisplayManager
import android.view.Display
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val PLATFORM_CHANNEL = "versee/platform"
    private val DISPLAY_CHANNEL = "versee/display_manager"
    private val PRESENTATION_CHANNEL = "versee/presentation"
    
    // Presentation management
    private var currentPresentation: VerseePresentation? = null
    private var presentationFlutterEngine: FlutterEngine? = null
    private val displayManager by lazy { getSystemService(Context.DISPLAY_SERVICE) as DisplayManager }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Platform channel para informações gerais da plataforma
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLATFORM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getScreenDimensions" -> {
                    val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
                    val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY)
                    val metrics = android.util.DisplayMetrics()
                    display.getRealMetrics(metrics)
                    
                    val dimensions = mapOf(
                        "width" to metrics.widthPixels,
                        "height" to metrics.heightPixels,
                        "density" to metrics.density,
                        "scaledDensity" to metrics.scaledDensity
                    )
                    result.success(dimensions)
                }
                "getDiagnosticInfo" -> {
                    val info = mapOf(
                        "platform" to "android",
                        "version" to android.os.Build.VERSION.RELEASE,
                        "sdk" to android.os.Build.VERSION.SDK_INT,
                        "model" to android.os.Build.MODEL,
                        "manufacturer" to android.os.Build.MANUFACTURER
                    )
                    result.success(info)
                }
                else -> result.notImplemented()
            }
        }

        // Display channel para funcionalidades de display externo
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DISPLAY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPhysicalDisplays" -> {
                    getPhysicalDisplays(result)
                }
                "scanChromecastDevices" -> {
                    scanChromecastDevices(result)
                }
                "connectToChromecast" -> {
                    val deviceId = call.argument<String>("deviceId")
                    val appId = call.argument<String>("appId")
                    connectToChromecast(deviceId, appId, result)
                }
                "disconnectChromecast" -> {
                    disconnectChromecast(result)
                }
                "testDisplayConnection" -> {
                    val displayId = call.argument<String>("displayId")
                    testDisplayConnection(displayId, result)
                }
                else -> result.notImplemented()
            }
        }

        // Presentation channel for external display projection
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRESENTATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startExternalPresentation" -> {
                    startExternalPresentation(result)
                }
                "stopExternalPresentation" -> {
                    stopExternalPresentation(result)
                }
                "updatePresentationContent" -> {
                    val content = call.arguments as? Map<String, Any>
                    updatePresentationContent(content, result)
                }
                "setPresentationBlackScreen" -> {
                    val active = call.argument<Boolean>("active") ?: false
                    setPresentationBlackScreen(active, result)
                }
                "hasExternalDisplay" -> {
                    hasExternalDisplay(result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getPhysicalDisplays(result: MethodChannel.Result) {
        try {
            val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
            val displays = displayManager.displays
            
            val displayList = displays.mapNotNull { display ->
                if (display.displayId != Display.DEFAULT_DISPLAY) {
                    val metrics = android.util.DisplayMetrics()
                    display.getRealMetrics(metrics)
                    
                    mapOf(
                        "id" to "physical_${display.displayId}",
                        "name" to (display.name ?: "Display Externo ${display.displayId}"),
                        "width" to metrics.widthPixels,
                        "height" to metrics.heightPixels,
                        "refreshRate" to display.refreshRate,
                        "isSecure" to (display.flags and Display.FLAG_SECURE != 0),
                        "state" to display.state
                    )
                } else null
            }
            
            result.success(displayList)
        } catch (e: Exception) {
            result.error("DISPLAY_ERROR", "Erro ao obter displays físicos: ${e.message}", null)
        }
    }

    private fun scanChromecastDevices(result: MethodChannel.Result) {
        // Implementação básica - seria necessário Google Cast SDK
        // Por enquanto, retornar lista vazia para compilação
        try {
            val devices = listOf<Map<String, Any>>() // Lista vazia até implementar Cast SDK
            result.success(devices)
        } catch (e: Exception) {
            result.error("CAST_ERROR", "Erro ao escanear Chromecast: ${e.message}", null)
        }
    }

    private fun connectToChromecast(deviceId: String?, appId: String?, result: MethodChannel.Result) {
        // Implementação básica - seria necessário Google Cast SDK
        try {
            // Por enquanto, simular falha para indicar que não está implementado
            result.success(false)
        } catch (e: Exception) {
            result.error("CAST_ERROR", "Erro ao conectar Chromecast: ${e.message}", null)
        }
    }

    private fun disconnectChromecast(result: MethodChannel.Result) {
        // Implementação básica - seria necessário Google Cast SDK
        try {
            result.success(true)
        } catch (e: Exception) {
            result.error("CAST_ERROR", "Erro ao desconectar Chromecast: ${e.message}", null)
        }
    }

    private fun testDisplayConnection(displayId: String?, result: MethodChannel.Result) {
        try {
            if (displayId == null) {
                result.success(false)
                return
            }

            val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
            val displays = displayManager.displays
            
            val found = displays.any { display -> 
                "physical_${display.displayId}" == displayId
            }
            
            result.success(found)
        } catch (e: Exception) {
            result.error("DISPLAY_ERROR", "Erro ao testar conexão: ${e.message}", null)
        }
    }

    // PRESENTATION API METHODS

    private fun createPresentationEngine(): FlutterEngine? {
        return try {
            val engine = FlutterEngine(this)
            engine.dartExecutor.executeDartEntrypoint(
                io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint.createDefault()
            )
            engine
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error creating presentation engine: ${e.message}")
            null
        }
    }

    private fun startExternalPresentation(result: MethodChannel.Result) {
        try {
            val displays = displayManager.displays
            val externalDisplay = displays.find { it.displayId != Display.DEFAULT_DISPLAY }

            if (externalDisplay != null) {
                // Create separate Flutter engine for presentation if needed
                if (presentationFlutterEngine == null) {
                    presentationFlutterEngine = createPresentationEngine()
                }

                presentationFlutterEngine?.let { engine ->
                    currentPresentation = VerseePresentation(this, externalDisplay, engine)
                    currentPresentation?.show()
                    
                    android.util.Log.d("MainActivity", "Started external presentation on: ${externalDisplay.name}")
                    result.success(mapOf(
                        "success" to true,
                        "displayId" to externalDisplay.displayId,
                        "displayName" to externalDisplay.name
                    ))
                } ?: run {
                    result.error("ENGINE_ERROR", "Failed to create Flutter engine for presentation", null)
                }
            } else {
                result.error("NO_DISPLAY", "No external display found", null)
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error starting external presentation: ${e.message}")
            result.error("PRESENTATION_ERROR", "Error starting external presentation: ${e.message}", null)
        }
    }

    private fun stopExternalPresentation(result: MethodChannel.Result) {
        try {
            currentPresentation?.dismiss()
            currentPresentation = null
            
            // Keep the engine for future use, don't destroy it
            // presentationFlutterEngine?.destroy()
            // presentationFlutterEngine = null
            
            android.util.Log.d("MainActivity", "Stopped external presentation")
            result.success(true)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error stopping external presentation: ${e.message}")
            result.error("PRESENTATION_ERROR", "Error stopping external presentation: ${e.message}", null)
        }
    }

    private fun updatePresentationContent(content: Map<String, Any>?, result: MethodChannel.Result) {
        try {
            if (currentPresentation != null && content != null) {
                currentPresentation?.updateContent(content)
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error updating presentation content: ${e.message}")
            result.error("PRESENTATION_ERROR", "Error updating presentation content: ${e.message}", null)
        }
    }

    private fun setPresentationBlackScreen(active: Boolean, result: MethodChannel.Result) {
        try {
            currentPresentation?.setBlackScreen(active)
            result.success(true)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error setting black screen: ${e.message}")
            result.error("PRESENTATION_ERROR", "Error setting black screen: ${e.message}", null)
        }
    }

    private fun hasExternalDisplay(result: MethodChannel.Result) {
        try {
            val displays = displayManager.displays
            val hasExternal = displays.any { it.displayId != Display.DEFAULT_DISPLAY }
            result.success(hasExternal)
        } catch (e: Exception) {
            result.error("DISPLAY_ERROR", "Error checking external display: ${e.message}", null)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        
        // Clean up presentation
        currentPresentation?.dismiss()
        currentPresentation = null
        
        // Clean up presentation engine
        presentationFlutterEngine?.destroy()
        presentationFlutterEngine = null
    }
}
