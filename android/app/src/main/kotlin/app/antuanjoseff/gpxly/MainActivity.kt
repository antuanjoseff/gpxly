package app.antuanjoseff.gpxly

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // REGISTRA EL TEU PLUGIN NATIU
        flutterEngine.plugins.add(TrackingPlugin())
    }
}
