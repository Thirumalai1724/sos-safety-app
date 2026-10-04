package com.example.sos_app

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.sos_app/volume_button"
    private var methodChannel: MethodChannel? = null
    private var lastPressTime: Long = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastPressTime < 1000) {
                methodChannel?.invokeMethod("sosTriggered", null)
                lastPressTime = 0
            } else {
                lastPressTime = currentTime
            }
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
}