package com.schoolevm.school_evm

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.ToneGenerator
import android.media.AudioManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.schoolevm/buzzer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "playBeep") {
                try {
                    // TONE_CDMA_PIP plays a continuous beep tone
                    val toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
                    toneGenerator.startTone(ToneGenerator.TONE_CDMA_PIP, 1000) // 1 second beep
                    result.success(true)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Could not play beep", e.localizedMessage)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
