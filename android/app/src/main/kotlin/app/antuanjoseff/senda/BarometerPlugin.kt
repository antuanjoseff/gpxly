package app.antuanjoseff.senda

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class BarometerPlugin :
    FlutterPlugin,
    EventChannel.StreamHandler,
    SensorEventListener {

    private lateinit var sensorManager: SensorManager
    private var pressureSensor: Sensor? = null
    private var events: EventChannel.EventSink? = null
    private lateinit var methodChannel: MethodChannel

    private var currentSamplingPeriod: Int = SensorManager.SENSOR_DELAY_NORMAL
    private var isRunning: Boolean = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        pressureSensor = sensorManager.getDefaultSensor(Sensor.TYPE_PRESSURE)

        EventChannel(binding.binaryMessenger, "barometer_stream").setStreamHandler(this)

        methodChannel = MethodChannel(binding.binaryMessenger, "barometer_methods")
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasBarometer" -> result.success(pressureSensor != null)

                "start" -> {
                    startTracking()
                    result.success(null)
                }

                "stop" -> {
                    stopTracking()
                    result.success(null)
                }

                "setSamplingPeriod" -> {
                    val newPeriod = call.arguments as? Int
                    if (newPeriod != null) {
                        updateSamplingPeriod(newPeriod)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Period is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startTracking() {
        if (!isRunning) {
            pressureSensor?.also {
                sensorManager.registerListener(this, it, currentSamplingPeriod)
                isRunning = true
            }
        }
    }

    private fun stopTracking() {
        sensorManager.unregisterListener(this)
        isRunning = false
    }

    fun updateSamplingPeriod(newPeriodMicroseconds: Int) {
        currentSamplingPeriod = newPeriodMicroseconds
        if (isRunning) {
            stopTracking()
            startTracking()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.events = events
    }

    override fun onCancel(arguments: Any?) {
        stopTracking()
        events = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        // 🛡️ COMPROVACIÓ DE SEGURETAT: Si la variable 'events' s'ha posat a null des d'un altre fil 
        // o si el sensor ja s'està aturant, guardem la referència en una variable local abans d'emetre.
        val currentSink = events
        if (currentSink != null && isRunning) {
            val pressure = event.values[0]
            try {
                currentSink.success(pressure)
            } catch (e: Exception) {
                // Captura qualsevol intent d'escriptura en un canal tancat per si de cas
                events = null
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // 🛡️ NETEJA COMPLETA: Aturem el sensor i forcem immediatament que el canal sigui nul.
        // D'aquesta manera cap esdeveniment residual d'onSensorChanged podrà intentar parlar amb Flutter.
        stopTracking()
        events = null
        methodChannel.setMethodCallHandler(null)
    }
}
