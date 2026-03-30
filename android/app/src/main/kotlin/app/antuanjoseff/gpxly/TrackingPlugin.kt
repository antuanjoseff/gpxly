package app.antuanjoseff.gpxly

import android.Manifest
import android.util.Log
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.app.Activity

import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import androidx.core.app.ActivityCompat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class TrackingPlugin :
    FlutterPlugin,
    EventChannel.StreamHandler,
    ActivityAware {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private var activity: Activity? = null
    private var applicationContext: Context? = null

    companion object {
        private var eventSink: EventChannel.EventSink? = null

        fun sendEvent(data: Map<String, Any>) {
            eventSink?.success(data)
        }
    }

    // 🔥 Comprovar permís REAL d’Android
    private fun hasBackgroundPermission(context: Context): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        )

        val bg = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_BACKGROUND_LOCATION
        )

        return fine == PackageManager.PERMISSION_GRANTED &&
               bg == PackageManager.PERMISSION_GRANTED
    }

    // 🔥 Demanar explícitament BACKGROUND LOCATION (Samsung ho exigeix)
    private fun requestBackgroundPermission(result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity is null", null)
            return
        }

        ActivityCompat.requestPermissions(
            act,
            arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
            2001
        )

        result.success(true)
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "tracking/methods")
        eventChannel = EventChannel(binding.binaryMessenger, "tracking/events")

        methodChannel.setMethodCallHandler { call, result ->
            Log.d("GPXLY", "Method call: ${call.method}")

            when (call.method) {

                "start" -> {
                    val intent = Intent(applicationContext, TrackingService::class.java)
                    applicationContext?.startForegroundService(intent)
                    result.success(null)
                }

                "stop" -> {
                    val intent = Intent(applicationContext, TrackingService::class.java)
                    applicationContext?.stopService(intent)
                    result.success(null)
                }

                "openAppLocationPermissions" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", applicationContext!!.packageName, null)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    applicationContext!!.startActivity(intent)
                    result.success(true)
                }

                // 🔥 Comprovar permís ALWAYS real
                "hasBackgroundPermission" -> {
                    val granted = hasBackgroundPermission(applicationContext!!)
                    result.success(granted)
                }

                // 🔥 Demanar BACKGROUND LOCATION explícitament
                "requestBackgroundPermission" -> {
                    requestBackgroundPermission(result)
                }

                else -> result.notImplemented()
            }
        }

        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = null
    }

    // ActivityAware
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    // EventChannel
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
