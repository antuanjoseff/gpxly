package app.antuanjoseff.senda

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
        // Volatile garanteix que els canvis d'estat es propaguin immediatament entre fils (Servei <-> Plugin)
        @Volatile
        private var eventSink: EventChannel.EventSink? = null

        fun sendEvent(data: Map<String, Any>) {
            // 🛡️ COMPROVACIÓ MAESTRA: Guardem referència en local i comprovem si el canal segueix obert
            val currentSink = eventSink
            if (currentSink != null) {
                try {
                    currentSink.success(data)
                } catch (e: Exception) {
                    // Si el motor ja no hi és i falla, invalidem el sink immediatament
                    eventSink = null
                }
            }
        }
    }

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
            Log.d("SENDA", "Method call: ${call.method}")

            when (call.method) {
                "start" -> {
                    val useTime = call.argument<Boolean>("useTime") ?: true
                    val seconds = call.argument<Int>("seconds") ?: 5
                    val meters = (call.argument<Double>("meters") ?: 10.0).toFloat()
                    val accuracy = (call.argument<Double>("accuracy") ?: 30.0).toFloat()
                    val debug = call.argument<Boolean>("debug") ?: false

                    val intent = Intent(applicationContext, TrackingService::class.java).apply {
                        putExtra("useTime", useTime)
                        putExtra("seconds", seconds)
                        putExtra("meters", meters)
                        putExtra("accuracy", accuracy)
                        putExtra("debug", debug)
                    }

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

                "hasBackgroundPermission" -> {
                    val granted = hasBackgroundPermission(applicationContext!!)
                    result.success(granted)
                }

                "requestBackgroundPermission" -> {
                    requestBackgroundPermission(result)
                }

                else -> result.notImplemented()
            }
        }

        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // 🛡️ NETEJA CRUCIAL: El motor de Flutter marxa, desconnectem canals per evitar fugues
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
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
