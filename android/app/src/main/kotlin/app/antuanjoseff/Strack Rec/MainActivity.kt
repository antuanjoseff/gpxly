package app.antuanjoseff.strack_rec

import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // REGISTRA ELS TEUS PLUGINS NATIUS
        flutterEngine.plugins.add(TrackingPlugin())   // El GPS
        flutterEngine.plugins.add(BarometerPlugin())  // El Baròmetre corregit

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "strack_rec/gpx_uri_reader"
        ).setMethodCallHandler { call, result ->
            if (call.method != "readTextFromUri") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val rawUri = call.argument<String>("uri")
            if (rawUri.isNullOrBlank()) {
                result.error("invalid_uri", "Missing uri argument", null)
                return@setMethodCallHandler
            }

            try {
                val uri = Uri.parse(rawUri)
                contentResolver.openInputStream(uri).use { input ->
                    if (input == null) {
                        result.error("open_failed", "Cannot open URI", null)
                        return@setMethodCallHandler
                    }
                    val text = input.bufferedReader(Charsets.UTF_8).readText()
                    result.success(text)
                }
            } catch (e: Exception) {
                result.error("read_failed", e.message, null)
            }
        }
    }
}
