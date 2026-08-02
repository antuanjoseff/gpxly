package app.antuanjoseff.strack_rec

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // REGISTRA ELS TEUS PLUGINS NATIUS
        flutterEngine.plugins.add(TrackingPlugin())   // El GPS
        flutterEngine.plugins.add(BarometerPlugin())  // El Baròmetre corregit
    }
}
