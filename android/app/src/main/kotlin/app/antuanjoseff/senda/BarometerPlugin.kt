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

        override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
            val context = binding.applicationContext

            sensorManager =
                context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

            pressureSensor =
                sensorManager.getDefaultSensor(Sensor.TYPE_PRESSURE)

            // EventChannel per enviar dades
            EventChannel(binding.binaryMessenger, "barometer_stream")
                .setStreamHandler(this)

            // MethodChannel per start/stop
            methodChannel = MethodChannel(binding.binaryMessenger, "barometer_methods")
            methodChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        pressureSensor?.also {
                            sensorManager.registerListener(
                                this,
                                it,
                                SensorManager.SENSOR_DELAY_NORMAL
                            )
                        }
                        result.success(null)
                    }

                    "stop" -> {
                        sensorManager.unregisterListener(this)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
        }

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            // Només guardem el sink. No activem el sensor aquí.
            this.events = events
        }

        override fun onCancel(arguments: Any?) {
            sensorManager.unregisterListener(this)
            events = null
        }

        override fun onSensorChanged(event: SensorEvent) {
            val pressure = event.values[0] // hPa
            events?.success(pressure)
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

        override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
            sensorManager.unregisterListener(this)
        }
    }
