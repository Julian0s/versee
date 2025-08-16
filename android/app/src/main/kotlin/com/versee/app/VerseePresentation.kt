package com.versee.app

import android.app.Presentation
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Bundle
import android.view.Display
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Presentation class for displaying content on external displays
 * Uses Android's Presentation API for real external display projection
 */
class VerseePresentation(
    context: Context,
    display: Display,
    private val flutterEngine: FlutterEngine
) : Presentation(context, display) {

    private lateinit var flutterView: FlutterView
    private lateinit var methodChannel: MethodChannel

    companion object {
        private const val CHANNEL = "versee/presentation_display"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        try {
            // Create FlutterView for external display
            flutterView = FlutterView(context)
            flutterView.attachToFlutterEngine(flutterEngine)

            // Setup method channel for communication
            methodChannel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )

            setContentView(flutterView)

            // Configure fullscreen presentation
            configureFullscreen()

            // Notify Flutter that presentation is ready
            methodChannel.invokeMethod("onPresentationReady", mapOf(
                "displayId" to display.displayId,
                "displayName" to display.name
            ))

        } catch (e: Exception) {
            android.util.Log.e("VerseePresentation", "Error creating presentation: ${e.message}")
        }
    }

    private fun configureFullscreen() {
        window?.let { window ->
            // Hide system UI for fullscreen experience
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            )

            // Keep screen on during presentation
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

            // Ensure content fits the display
            window.addFlags(WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN)
        }
    }

    override fun onStart() {
        super.onStart()
        android.util.Log.d("VerseePresentation", "Presentation started on display: ${display.name}")
        
        // Notify Flutter that presentation started
        methodChannel.invokeMethod("onPresentationStarted", null)
    }

    override fun onStop() {
        super.onStop()
        android.util.Log.d("VerseePresentation", "Presentation stopped")
        
        // Notify Flutter that presentation stopped
        methodChannel.invokeMethod("onPresentationStopped", null)
        
        // Detach from Flutter engine
        try {
            flutterView.detachFromFlutterEngine()
        } catch (e: Exception) {
            android.util.Log.e("VerseePresentation", "Error detaching FlutterView: ${e.message}")
        }
    }

    override fun onDisplayChanged() {
        super.onDisplayChanged()
        android.util.Log.d("VerseePresentation", "Display changed: ${display.name}")
        
        // Notify Flutter about display changes
        methodChannel.invokeMethod("onDisplayChanged", mapOf(
            "displayId" to display.displayId,
            "displayName" to display.name
        ))
    }

    override fun onDisplayRemoved() {
        super.onDisplayRemoved()
        android.util.Log.d("VerseePresentation", "Display removed: ${display.name}")
        
        // Auto-dismiss when display is removed
        dismiss()
    }

    /**
     * Update presentation content from Flutter
     */
    fun updateContent(content: Map<String, Any>) {
        methodChannel.invokeMethod("updatePresentationContent", content)
    }

    /**
     * Set black screen mode
     */
    fun setBlackScreen(active: Boolean) {
        methodChannel.invokeMethod("setBlackScreen", active)
    }
}