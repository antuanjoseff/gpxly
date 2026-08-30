package app.antuanjoseff.strack_rec

import android.util.Log
import android.app.*
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.os.Build
import android.os.PowerManager
import android.os.SystemClock
import android.location.Location
import android.location.LocationManager
import android.location.GnssStatus
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*

class TrackingService : Service() {

    private lateinit var fused: FusedLocationProviderClient
    private lateinit var callback: LocationCallback
    private lateinit var distanceCallback: LocationCallback
    private lateinit var distanceTimeCallback: LocationCallback
    private lateinit var locationManager: LocationManager
    private var wakeLock: PowerManager.WakeLock? = null

    private var lastLocation: Location? = null
    private var lastTime: Long = 0
    private var satellitesUsed: Int = 0
    private var satellitesInView: Int = 0

    private var useTime: Boolean = true
    private var seconds: Int = 5
    private var metersThreshold: Float = 10f
    private var accuracyThreshold: Float = 30f
    private var debugEnabled: Boolean = false

    private var totalReceived: Long = 0
    private var totalSent: Long = 0
    private var dropAccuracy: Long = 0
    private var dropTimeGate: Long = 0
    private var dropDistanceGate: Long = 0
    private var lastSentFixTime: Long = 0
    private var lastSentWallTime: Long = 0
    private var lastDropDebugWallTime: Long = 0
    private var lastAutoRecoveryWallTime: Long = 0

    private val gapRecoverMs = 60_000L
    private val recoveryCooldownMs = 120_000L
    private val distanceRequestIntervalMs = 1_000L
    private val distanceTimeFallbackMs = 30_000L

    // Callback per rebre l'estat dels satèl·lits
    private val gnssStatusCallback = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        object : GnssStatus.Callback() {
            override fun onSatelliteStatusChanged(status: GnssStatus) {
                val sats = mutableListOf<Map<String, Any>>()
                var used = 0
                val total = status.satelliteCount

                for (i in 0 until total) {
                    if (status.usedInFix(i)) used++

                    sats.add(
                        mapOf(
                            "svid" to status.getSvid(i),
                            "constellation" to status.getConstellationType(i),
                            "azimuth" to status.getAzimuthDegrees(i),
                            "elevation" to status.getElevationDegrees(i),
                            "cn0" to status.getCn0DbHz(i),
                            "usedInFix" to status.usedInFix(i)
                        )
                    )
                }

                satellitesUsed = used
                satellitesInView = total

                TrackingPlugin.sendEvent(
                    mapOf(
                        "type" to "gnss_status",
                        "satellites" to sats
                    )
                )
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
        } catch (e: SecurityException) { Log.e("SENDA", "Error permisos GNSS") }

        callback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                if (debugEnabled && result.locations.size > 1) {
                    TrackingPlugin.sendEvent(
                        mapOf(
                            "type" to "gps_debug",
                            "kind" to "batch",
                            "batch_size" to result.locations.size,
                            "use_time" to useTime,
                            "seconds" to seconds,
                            "meters" to metersThreshold
                        )
                    )
                }
                for (loc in result.locations) sendLocationToFlutter(loc)
            }
        }

        distanceCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                for (loc in result.locations) sendLocationToFlutter(loc)
            }
        }

        distanceTimeCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                for (loc in result.locations) {
                    sendLocationToFlutter(loc, isDistanceTimeFallback = true)
                }
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
        debugEnabled = intent.getBooleanExtra("debug", false)

        totalReceived = 0
        totalSent = 0
        dropAccuracy = 0
        dropTimeGate = 0
        dropDistanceGate = 0
        lastSentFixTime = 0
        lastSentWallTime = 0
        lastDropDebugWallTime = 0
        lastAutoRecoveryWallTime = 0

        if (debugEnabled) {
            TrackingPlugin.sendEvent(
                mapOf(
                    "type" to "gps_debug",
                    "kind" to "start",
                    "use_time" to useTime,
                    "seconds" to seconds,
                    "meters" to metersThreshold,
                    "accuracy_threshold" to accuracyThreshold
                )
            )
        }

        startForegroundServiceNotification()
        acquireWakeLock()
        startLocationUpdates()

        startService(Intent(this, ServiceKiller::class.java))

        return START_NOT_STICKY
    }

    // Manté la CPU desperta perquè Doze/fabricants no aturin la recepció de GPS amb pantalla apagada
    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "senda:TrackingServiceWakeLock"
        ).apply {
            setReferenceCounted(false)
            acquire(12 * 60 * 60 * 1000L) // límit de seguretat de 12h
        }
    }

    private fun startLocationUpdates() {
        fused.removeLocationUpdates(callback)
        fused.removeLocationUpdates(distanceCallback)
        fused.removeLocationUpdates(distanceTimeCallback)

        val intervalMs = (if (seconds < 1) 1 else seconds) * 1000L

        if (useTime) {
            val builder = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, intervalMs)
                .setGranularity(Granularity.GRANULARITY_FINE)
                .setMinUpdateIntervalMillis(intervalMs)
                .setMinUpdateDistanceMeters(0f)
                .setMaxUpdateDelayMillis(0)
                .build()

            try {
                fused.requestLocationUpdates(builder, callback, mainLooper)
            } catch (e: SecurityException) { /*...*/ }
            return
        }

        // En mode distància, el sistema selecciona els punts per moviment.
        // Una segona petició temporal garanteix un punt cada 30 s durant una
        // parada, sense aplicar un filtre manual de distància al servei.
        val distanceBuilder = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            distanceRequestIntervalMs
        )
            .setGranularity(Granularity.GRANULARITY_FINE)
            .setMinUpdateIntervalMillis(distanceRequestIntervalMs)
            .setMinUpdateDistanceMeters(metersThreshold)
            .setMaxUpdateDelayMillis(0)
            .build()

        val distanceTimeBuilder = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            distanceTimeFallbackMs
        )
            .setGranularity(Granularity.GRANULARITY_FINE)
            .setMinUpdateIntervalMillis(distanceTimeFallbackMs)
            .setMinUpdateDistanceMeters(0f)
            .setMaxUpdateDelayMillis(0)
            .build()

        try {
            fused.requestLocationUpdates(distanceBuilder, distanceCallback, mainLooper)
            fused.requestLocationUpdates(
                distanceTimeBuilder,
                distanceTimeCallback,
                mainLooper
            )
        } catch (e: SecurityException) { /*...*/ }
    }

    private fun sendLocationToFlutter(
        loc: Location,
        isDistanceTimeFallback: Boolean = false
    ) {
        totalReceived += 1

        if (loc.accuracy > accuracyThreshold) {
            dropAccuracy += 1
            maybeEmitDropDebug("accuracy", loc, null)
            return
        }

        // IMPORTANT: use the fix timestamp from GNSS/Fused (`loc.time`) instead
        // of wall clock `now`. Android may deliver batched points in one callback.
        // If we gate by `now`, almost all points in a batch are dropped.
        val fixTime = if (loc.time > 0L) loc.time else System.currentTimeMillis()

        if (useTime) {
            val minDelta = (seconds * 1000 * 0.9).toLong()
            if (lastTime > 0L && fixTime - lastTime < minDelta) {
                dropTimeGate += 1
                maybeEmitDropDebug("time_gate", loc, minDelta)
                return
            }
        } else if (isDistanceTimeFallback &&
            lastSentWallTime > 0L &&
            System.currentTimeMillis() - lastSentWallTime < distanceTimeFallbackMs
        ) {
            // La petició temporal no duplica un punt que acaba d'arribar per
            // distància; el criteri de metres el resol LocationRequest.
            dropTimeGate += 1
            maybeEmitDropDebug("time_fallback_not_due", loc, distanceTimeFallbackMs)
            return
        }


        lastTime = fixTime
        lastLocation = loc
        totalSent += 1

        val gapSincePrevSent = if (lastSentFixTime > 0L) fixTime - lastSentFixTime else 0L
        val nowWall = System.currentTimeMillis()
        val gapWallMs = if (lastSentWallTime > 0L) nowWall - lastSentWallTime else 0L
        lastSentFixTime = fixTime
        lastSentWallTime = nowWall

        val fixAgeMs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1 &&
            loc.elapsedRealtimeNanos > 0L
        ) {
            (SystemClock.elapsedRealtimeNanos() - loc.elapsedRealtimeNanos) / 1_000_000L
        } else {
            -1L
        }

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

        if (debugEnabled && gapSincePrevSent > 0L) {
            TrackingPlugin.sendEvent(
                mapOf(
                    "type" to "gps_debug",
                    "kind" to "sent",
                    "gap_ms" to gapSincePrevSent,
                    "gap_wall_ms" to gapWallMs,
                    "fix_age_ms" to fixAgeMs,
                    "accuracy" to loc.accuracy,
                    "provider" to (loc.provider ?: "unknown"),
                    "speed" to loc.speed,
                    "bearing" to loc.bearing,
                    "lat" to loc.latitude,
                    "lon" to loc.longitude,
                    "is_mock" to loc.isFromMockProvider,
                    "use_time" to useTime,
                    "seconds" to seconds,
                    "meters" to metersThreshold,
                    "sat_used" to satellitesUsed,
                    "sat_view" to satellitesInView,
                    "is_device_idle" to isDeviceIdleMode()
                )
            )
        }

        maybeRecoverAfterLargeGap(gapSincePrevSent)

        if (debugEnabled && totalReceived % 30L == 0L) {
            emitSummary("periodic")
        }
    }

    private fun maybeEmitDropDebug(reason: String, loc: Location, threshold: Long?) {
        if (!debugEnabled) return
        val now = System.currentTimeMillis()
        if (now - lastDropDebugWallTime < 5000L) return
        lastDropDebugWallTime = now

        val fixTime = if (loc.time > 0L) loc.time else now
        val deltaFromLastSent = if (lastSentFixTime > 0L) fixTime - lastSentFixTime else 0L

        TrackingPlugin.sendEvent(
            mapOf(
                "type" to "gps_debug",
                "kind" to "drop",
                "reason" to reason,
                "accuracy" to loc.accuracy,
                "threshold" to (threshold ?: -1L),
                "delta_from_last_sent_ms" to deltaFromLastSent,
                "use_time" to useTime,
                "seconds" to seconds,
                "meters" to metersThreshold
            )
        )
    }

    private fun emitSummary(kind: String) {
        if (!debugEnabled) return
        TrackingPlugin.sendEvent(
            mapOf(
                "type" to "gps_debug",
                "kind" to "summary",
                "summary_kind" to kind,
                "received" to totalReceived,
                "sent" to totalSent,
                "drop_accuracy" to dropAccuracy,
                "drop_time" to dropTimeGate,
                "drop_distance" to dropDistanceGate,
                "use_time" to useTime,
                "seconds" to seconds,
                "meters" to metersThreshold
            )
        )
    }

    private fun isDeviceIdleMode(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
        return pm?.isDeviceIdleMode ?: false
    }

    private fun maybeRecoverAfterLargeGap(gapMs: Long) {
        if (gapMs < gapRecoverMs) return

        val now = System.currentTimeMillis()
        if (now - lastAutoRecoveryWallTime < recoveryCooldownMs) return
        lastAutoRecoveryWallTime = now

        if (debugEnabled) {
            TrackingPlugin.sendEvent(
                mapOf(
                    "type" to "gps_debug",
                    "kind" to "recover",
                    "reason" to "large_gap",
                    "gap_ms" to gapMs,
                    "gap_recover_ms" to gapRecoverMs,
                    "cooldown_ms" to recoveryCooldownMs,
                    "use_time" to useTime,
                    "seconds" to seconds,
                    "meters" to metersThreshold,
                    "sat_used" to satellitesUsed,
                    "sat_view" to satellitesInView,
                    "is_device_idle" to isDeviceIdleMode()
                )
            )
        }

        startLocationUpdates()
    }

    private fun startForegroundServiceNotification() {
        val channelId = "tracking_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "GPS Tracking", NotificationManager.IMPORTANCE_LOW)
            (getSystemService(NotificationManager::class.java)).createNotificationChannel(channel)
        }

        val notificationIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Gravant track")
            .setContentText("GPS actiu")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setContentIntent(pendingIntent)   // 👈 AIXÒ FA QUE S’OBRI L’APP
            .build()

        startForeground(1, notification)
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // 1. EL TRUC: Forcem l'eliminació visual directa utilitzant el gestor de notificacions nativament.
        // Com que a startForeground(1, notification) vas utilitzar l'ID 1, aquí cancel·lem exactament l'ID 1.
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(1) 
        } catch (e: Exception) {
            Log.e("SENDA", "Error cancel·lant notificació visual", e)
        }

        // 2. Traiem el servei de l'estat de primer pla netament
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        
        // 3. Demanem a Android que aturi el servei. Això farà que el sistema cridi a onDestroy() 
        // de manera lícita, ordenada i asíncrona un mil·lisegon després.
        stopSelf()
        
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        if (debugEnabled) emitSummary("stop")

        // Per seguretat, tornem a demanar que es tregui la notificació per si s'ha tancat el servei
        // de manera programàtica des de Flutter en lloc de lliscant l'app.
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(1)
        } catch (e: Exception) { /*...*/ }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }

        // Netegem els teus callbacks de GPS de fons
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && gnssStatusCallback != null) {
            locationManager.unregisterGnssStatusCallback(gnssStatusCallback)
        }
        fused.removeLocationUpdates(callback)
        fused.removeLocationUpdates(distanceCallback)
        fused.removeLocationUpdates(distanceTimeCallback)
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        
        super.onDestroy()
    }


    override fun onBind(intent: Intent?): IBinder? = null
}

class ServiceKiller : Service() {
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_NOT_STICKY

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Aquest mètode SÍ que s'executa sempre perquè aquest servei no té GPS ni fons lligat.
        // Quan es detecta el tancament de l'app, enviem l'ordre d'aturar el servei de tracking principal.
        val stopIntent = Intent(this, TrackingService::class.java)
        stopService(stopIntent)
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }
}
