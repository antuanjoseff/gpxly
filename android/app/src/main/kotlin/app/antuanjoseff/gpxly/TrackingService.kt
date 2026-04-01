package app.antuanjoseff.gpxly

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
        // 🔹 Evitem NPE, però si és null, parem
        if (intent == null) return START_NOT_STICKY

        // 🔹 Llegim la configuració que ve de Flutter
        val useTime = intent.getBooleanExtra("useTime", true)
        val seconds = intent.getIntExtra("seconds", 5)
        val meters = intent.getIntExtra("meters", 10)

        startForegroundServiceNotification()
        startLocationUpdates(useTime, seconds, meters)

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
    meters: Int
    ) {
        val baseIntervalMs = (seconds.coerceAtLeast(1)) * 1000L
        val baseDistanceM = meters.coerceAtLeast(1).toFloat()

        val builder = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            baseIntervalMs
        )
            .setGranularity(Granularity.GRANULARITY_FINE)
            .setWaitForAccurateLocation(false)
            .setMaxUpdateDelayMillis(0)

        if (useTime) {
            // MODE TEMPS
            builder
                .setMinUpdateIntervalMillis(baseIntervalMs)
                .setMinUpdateDistanceMeters(0f)
        } else {
            // MODE DISTÀNCIA
            builder
                .setMinUpdateIntervalMillis(baseIntervalMs)   // 🔥 IMPORTANT
                .setMinUpdateDistanceMeters(baseDistanceM)    // 🔥 Ara sí funciona
        }

        val request = builder.build()
        fused.requestLocationUpdates(request, callback, mainLooper)
    }

    private fun sendLocationToFlutter(loc: Location) {
        TrackingPlugin.sendEvent(
            mapOf(
                "lat" to loc.latitude,
                "lon" to loc.longitude,
                "accuracy" to loc.accuracy
            )
        )
    }
}
