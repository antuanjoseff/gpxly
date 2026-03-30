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

        startForegroundServiceNotification()
        startLocationUpdates()

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

    private fun startLocationUpdates() {
        val request = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            2000 // cada 2 segons
        ).setMinUpdateDistanceMeters(3f).build()

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
