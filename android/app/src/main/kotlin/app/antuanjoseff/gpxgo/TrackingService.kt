package app.antuanjoseff.gpxgo

import android.util.Log
import android.app.*
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.os.Build
import android.location.Location
import android.location.LocationManager
import android.location.GnssStatus
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*

class TrackingService : Service() {

    private lateinit var fused: FusedLocationProviderClient
    private lateinit var callback: LocationCallback
    private lateinit var locationManager: LocationManager
    
    private var lastLocation: Location? = null
    private var lastTime: Long = 0
    private var satellitesUsed: Int = 0
    private var satellitesInView: Int = 0

    private var useTime: Boolean = true
    private var seconds: Int = 5
    private var metersThreshold: Float = 10f
    private var accuracyThreshold: Float = 30f

    // Callback per rebre l'estat dels satèl·lits
    private val gnssStatusCallback = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        object : GnssStatus.Callback() {
            override fun onSatelliteStatusChanged(status: GnssStatus) {
                var used = 0
                val total = status.satelliteCount
                for (i in 0 until total) {
                    if (status.usedInFix(i)) used++
                }
                satellitesUsed = used
                satellitesInView = total
            }
        }
    } else null

    override fun onCreate() {
        super.onCreate()
        fused = LocationServices.getFusedLocationProviderClient(this)
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager

        // Registrar el seguiment de satèl·lits
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && gnssStatusCallback != null) {
                locationManager.registerGnssStatusCallback(gnssStatusCallback, null)
            }
        } catch (e: SecurityException) { Log.e("GPXLY", "Error permisos GNSS") }

        callback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                for (loc in result.locations) sendLocationToFlutter(loc)
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY
        
        lastLocation = null
        lastTime = 0
        useTime = intent.getBooleanExtra("useTime", true)
        seconds = intent.getIntExtra("seconds", 5)
        metersThreshold = intent.getFloatExtra("meters", 10.0f)
        accuracyThreshold = intent.getFloatExtra("accuracy", 30.0f)

        startForegroundServiceNotification()
        startLocationUpdates()

        return START_STICKY
    }

    private fun startLocationUpdates() {
        fused.removeLocationUpdates(callback)
        val safeSeconds = if (seconds < 1) 1 else seconds
        val intervalMs = safeSeconds * 1000L
        
        
        // En lloc de 0L, posa un interval mínim d'1 o 2 segons quan vagis per metres
        val realInterval = if (useTime) intervalMs else 2000L 
        val minDistance = if (useTime) 0f else metersThreshold

        val builder = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, realInterval)
            .setGranularity(Granularity.GRANULARITY_FINE)
            .setMinUpdateDistanceMeters(minDistance)
            .setWaitForAccurateLocation(false)

        // Si usem temps, definim el MinUpdateInterval una mica més curt que l'interval 
        // nominal per evitar que petits retards descartin la lectura.
        if (useTime) {
            builder.setMinUpdateIntervalMillis(intervalMs / 2)
        }

        try {
            fused.requestLocationUpdates(builder.build(), callback, mainLooper)
        } catch (e: SecurityException) {
            Log.e("GPXLY", "Sense permisos per actualitzacions")
        }
    }

    private fun sendLocationToFlutter(loc: Location) {
        // 1. Filtre de precisió horitzontal
        if (loc.accuracy > accuracyThreshold) return

        val now = System.currentTimeMillis()

        // 2. Filtre de seguretat per evitar duplicats o micro-moviments si el Fused s'embala
        if (useTime) {
            // Deixem un marge del 10% del temps (p.ex. si demanes 5s, acceptem a partir de 4.5s)
            if (now - lastTime < (seconds * 1000 * 0.9)) return
        } else {
            // Només enviem si realment ens hem mogut la distància demanada respecte l'última
            if (lastLocation != null && lastLocation!!.distanceTo(loc) < metersThreshold) return
        }

        lastTime = now
        lastLocation = loc

        // Recuperem la vAccuracy (Vertical Accuracy)
        val vAcc = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && loc.hasVerticalAccuracy()) {
            loc.verticalAccuracyMeters
        } else {
            0.0f
        }

        TrackingPlugin.sendEvent(mapOf(
            "lat" to loc.latitude,
            "lon" to loc.longitude,
            "accuracy" to loc.accuracy,
            "vAccuracy" to vAcc, // <-- Aquí la tens de nou!
            "altitude" to loc.altitude,
            "speed" to loc.speed,
            "heading" to loc.bearing,
            "timestamp" to loc.time,
            "sat_used" to satellitesUsed,
            "sat_view" to satellitesInView
        ))
    }



    

    private fun startForegroundServiceNotification() {
        val channelId = "tracking_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "GPS Tracking", NotificationManager.IMPORTANCE_LOW)
            (getSystemService(NotificationManager::class.java)).createNotificationChannel(channel)
        }
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Gravant track").setContentText("GPS actiu")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation).build()
        startForeground(1, notification)
    }

    override fun onDestroy() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && gnssStatusCallback != null) {
            locationManager.unregisterGnssStatusCallback(gnssStatusCallback)
        }
        fused.removeLocationUpdates(callback)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
