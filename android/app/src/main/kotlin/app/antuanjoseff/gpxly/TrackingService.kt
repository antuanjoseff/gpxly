package app.antuanjoseff.gpxly
import android.util.Log
import android.app.*
import android.content.Intent
import android.os.IBinder
import android.os.Build
import android.location.Location
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*

class TrackingService : Service() {

    private lateinit var fused: FusedLocationProviderClient
    private lateinit var callback: LocationCallback
    private var lastLocation: Location? = null
    private var lastTime: Long = 0

    private var useTime: Boolean = true
    private var seconds: Int = 5
    private var metersThreshold: Float = 10f
    private var accuracyThreshold: Float = 30f

    override fun onCreate() {
        super.onCreate()

        fused = LocationServices.getFusedLocationProviderClient(this)

        callback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                for (loc: Location in result.locations) {
                    sendLocationToFlutter(loc)
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        lastLocation = null
        lastTime = 0

        // 🔹 Evitem NPE, però si és null, parem
        if (intent == null) return START_NOT_STICKY

        // 🔹 Llegim la configuració que ve de Flutter
        useTime = intent.getBooleanExtra("useTime", true)
        seconds = intent.getIntExtra("seconds", 5)
        metersThreshold = intent.getDoubleExtra("meters", 10.0).toFloat()
        accuracyThreshold = intent.getDoubleExtra("accuracy", 30.0).toFloat()

        // 🔹 Print debug
        Log.d("GPXLY", "TrackingService config: useTime=$useTime, seconds=$seconds, meters=$metersThreshold, accuracy=$accuracyThreshold")


        startForegroundServiceNotification()
        startLocationUpdates(useTime, seconds, metersThreshold)

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        fused.removeLocationUpdates(callback)
        super.onDestroy()
    }

    private fun startForegroundServiceNotification() {
        val channelId = "tracking_channel"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "GPS Tracking",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Gravant track")
            .setContentText("El GPS està actiu")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()

        startForeground(1, notification)
    }

    private fun startLocationUpdates(
        useTime: Boolean,
        seconds: Int,
        meters: Float
    ) {
        fused.removeLocationUpdates(callback)

        val baseIntervalMs = (seconds.coerceAtLeast(1)) * 1000L
        val baseDistanceM = meters.coerceAtLeast(1f) // ja és Float

        val builder = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            baseIntervalMs
        )
            .setGranularity(Granularity.GRANULARITY_FINE)
            .setWaitForAccurateLocation(false)
            .setMaxUpdateDelayMillis(baseIntervalMs)

        if (useTime) {
            builder
                .setMinUpdateIntervalMillis(baseIntervalMs)
                .setMinUpdateDistanceMeters(0f)
            Log.d("GPXLY", "Mode TEMPS activat: interval=$seconds s, distància mínima=0 m")
        } else {
            builder
                .setMinUpdateIntervalMillis(0)
                .setMinUpdateDistanceMeters(baseDistanceM)
            Log.d("GPXLY", "Mode DISTÀNCIA activat: interval=$seconds s, distància mínima=$metersThreshold m")
        }

        val request = builder.build()
        fused.requestLocationUpdates(request, callback, mainLooper)
    }

    private fun sendLocationToFlutter(loc: Location) {
        if (loc.accuracy > accuracyThreshold) return
    
        val now = System.currentTimeMillis()
        val lastLoc = lastLocation
        
        // if (lastLoc != null && loc.distanceTo(lastLoc) < 1f) return
        
        if (useTime) {
            // 🔹 MODE TEMPS
            if (now - lastTime < seconds * 1000) return
        } else {
            // 🔹 MODE DISTÀNCIA
            if (lastLoc != null) {
                val distance = lastLoc.distanceTo(loc)
                if (distance < metersThreshold) return
            }
        }

        lastTime = now
        lastLocation = loc

        TrackingPlugin.sendEvent(
            mapOf(
                "lat" to loc.latitude,
                "lon" to loc.longitude,
                "accuracy" to loc.accuracy
            )
        )
    }
}
