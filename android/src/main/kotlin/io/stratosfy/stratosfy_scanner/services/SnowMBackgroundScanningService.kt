package io.stratosfy.stratosfy_scanner.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import io.stratosfy.stratosfy_scanner.BackgroundWakeableApplication
import io.stratosfy.stratosfy_scanner.R
import io.stratosfy.stratosfy_scanner.helpers.BeaconScanner
import io.stratosfy.stratosfy_scanner.helpers.BeaconScanner.OnBeaconScanned
import io.stratosfy.stratosfy_scanner.helpers.MqttHelper
import io.stratosfy.stratosfy_scanner.helpers.NotificationHelper.removeNotification
import io.stratosfy.stratosfy_scanner.helpers.NotificationHelper.sendNotification
import io.stratosfy.stratosfy_scanner.helpers.PermissionManager
import io.stratosfy.stratosfy_scanner.models.SnowMiBeacon
import org.altbeacon.beacon.Identifier
import org.altbeacon.beacon.Region
import kotlin.properties.Delegates

open class SnowMBackgroundScanningService : Service(), PermissionManager.BluetoothStateListener {
    lateinit var customData: Map<String, Any>
    private lateinit var uuids: List<String>
    private lateinit var mqttHelper: MqttHelper
    private lateinit var beaconScanner: BeaconScanner
    private lateinit var permissionManager: PermissionManager
    var backgroundBetweenScanPeriod by Delegates.notNull<Double>()
    var backgroundScanPeriod by Delegates.notNull<Double>()
    private var regionMap: HashMap<String, Boolean> = HashMap()

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    companion object {
        var scanId: String? = null
    }

    private var onBeaconScanned: OnBeaconScanned = object : OnBeaconScanned {
        override fun onBeaconRanged(beacons: ArrayList<SnowMiBeacon>) {
            val validBeacons: ArrayList<SnowMiBeacon> = ArrayList()
            beacons.forEach() {
                mqttHelper.sendIBeaconInformation(it)
                if (uuids.contains(it.uuid))
                    validBeacons.add(it)
            }
            onBeaconsDetected(validBeacons)
        }

        override fun didEnterRegion(p0: Region?) {
            val uuid = p0?.id1.toString()
            if (!uuids.contains(uuid)) return
            if (!regionMap.values.contains(true)) onRegionEntered()

            regionMap[uuid] = true
        }

        override fun didExitRegion(p0: Region?) {
            val uuid = p0?.id1.toString()
            if (!uuids.contains(uuid)) return
            regionMap[uuid] = false
            if (!regionMap.values.contains(true)) onRegionExited()

        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d("BackgroundService", "created")
        mqttHelper = MqttHelper(this)
        beaconScanner = BeaconScanner(this)
        permissionManager = PermissionManager(this)
        beaconScanner.monitorBeacons("background")
        permissionManager.bluetoothState("background", this)
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        val extra = intent.extras ?: return START_NOT_STICKY
        val title = extra.getString("title")
        val body = extra.getString("body")
        scanId = extra.getString("scanId")

        uuids = extra.getStringArrayList("uuids")?.toList()!!
        uuids.forEach {
            regionMap[it] = false
            if (application is BackgroundWakeableApplication)
                (application as BackgroundWakeableApplication).registerRegion(Region(it, Identifier.parse(it), null, null))
        }
        customData = extra.getSerializable("customData") as Map<String, Any>
        backgroundBetweenScanPeriod = extra.getDouble("backgroundBetweenScanPeriod")
        backgroundScanPeriod = extra.getDouble("backgroundBetweenScanPeriod")
        beaconScanner.rangeBeacons("background", backgroundBetweenScanPeriod, backgroundScanPeriod)
        beaconScanner.setOnBeaconScanner("background", onBeaconScanned)
        onScannerRegistered(scanId = scanId!!, customData = customData)
        createNotificationChannel(this)
        val activityIntent = Intent()
        activityIntent.setPackage(this.packageName)
        activityIntent.action = "android.intent.action.MAIN"
        activityIntent.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        val contentIntent = PendingIntent.getActivity(this, 0, activityIntent, 0)
        val notification = NotificationCompat.Builder(this, "snowm_scanner").setContentTitle(title).setContentText(body).setSmallIcon(R.drawable.skel_logo).setContentIntent(contentIntent).build()
        startForeground(1, notification)
        return START_STICKY
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel("snowm_scanner", "Background Scanner", importance)
            channel.description = "Notification alerts for beacon scanner."
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        scanId = null
        permissionManager.dispose()
        stopScan()
    }

    open fun onBeaconsDetected(beacons: ArrayList<SnowMiBeacon>) {}

    open fun onRegionEntered() {
    }

    open fun onRegionExited() {
    }

    open fun onScannerRegistered(scanId: String, customData: Map<String, Any>) {

    }

    fun stopScan() {
        beaconScanner.stopRanging("background")
        beaconScanner.stopMonitoring("background")
        uuids.forEach {
            if (application is BackgroundWakeableApplication)
                (application as BackgroundWakeableApplication).unregisterRegion(Region(it, Identifier.parse(it), null, null))
        }
    }

    override fun onStateChanged(state: PermissionManager.BluetoothState) {
        when (state) {
            PermissionManager.BluetoothState.OFF -> {
                sendNotification(20, "Bluetooth State", this, applicationInfo.nonLocalizedLabel?.toString(), "Please turn on the bluetooth so that we can scan our devices.", true)
            }
            PermissionManager.BluetoothState.ON -> {
                removeNotification(this, 20)
            }
            else -> removeNotification(this, 20)
        }
    }
}
