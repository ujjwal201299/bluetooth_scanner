package io.stratosfy.stratosfy_scanner.helpers

import android.content.Context
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import io.stratosfy.stratosfy_scanner.models.SnowMiBeacon
import org.altbeacon.beacon.*
import org.altbeacon.beacon.logging.LogManager
import org.altbeacon.bluetooth.BluetoothMedic
import java.util.*
import kotlin.collections.ArrayList
import kotlin.math.floor
import kotlin.math.pow

class BeaconScanner(private val context: Context) {
    private val onBeaconScannedInterfaces: HashMap<String, OnBeaconScanned> = HashMap()
    private var beaconManager = BeaconManager.getInstanceForApplication(context.applicationContext)
    init {
        beaconManager.beaconParsers.add(BeaconParser().setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24"))
        val medic = BluetoothMedic.getInstance()
        medic.enablePowerCycleOnFailures(context)
        medic.enablePeriodicTests(context, BluetoothMedic.SCAN_TEST)
    }
    private fun getDistance(rssi: Int): Double {
        val measuredPower = -65
        val environmetalFactor = getEnvironmentalFactor(rssi)
        val core = (measuredPower - rssi) / (10 * environmetalFactor);
        return 10.0.pow(core)
    }
    private fun getEnvironmentalFactor(rssi: Int): Double {
        if (rssi < -100) return 2.0
        if (rssi > -35) return 4.0
        val range = (rssi + 100) / 65
        val value = 2.0 + 2 * range
        return floor(value)
    }

    fun setOnBeaconScanner(identifier: String, onBeaconScanned: OnBeaconScanned) {
        onBeaconScannedInterfaces[identifier] = onBeaconScanned
    }

    fun rangeBeacons(identifier: String, backgroundBetweenScanPeriod: Double, backgroundScanPeriod: Double) {
        if (identifier == "background") {
            beaconManager.backgroundBetweenScanPeriod = backgroundBetweenScanPeriod.toLong()
            beaconManager.backgroundScanPeriod = backgroundScanPeriod.toLong()
        }
        val region = Region(identifier, null, null, null)
        beaconManager.getRegionViewModel(region).rangedBeacons.observe(context as LifecycleOwner, androidx.lifecycle.Observer { beacons ->
            val scannedBeacons = ArrayList<SnowMiBeacon>()
            print(beacons)
            beacons!!.forEach {
                val beacon = SnowMiBeacon()
                beacon.rssi = it.rssi
                beacon.distance = getDistance(it.rssi)
                beacon.macAddress = it.bluetoothAddress
                beacon.txPower = it.txPower
                beacon.major = it.id2.toInt()
                beacon.minor = it.id3.toInt()
                beacon.uuid = it.id1.toString().toUpperCase()
                scannedBeacons.add(beacon)
            }
            onBeaconScannedInterfaces[identifier]?.onBeaconRanged(scannedBeacons)
        })
        beaconManager.startRangingBeacons(region)
    }

    fun monitorBeacons(identifier: String) {
        val region = Region(identifier, null, null, null)
        beaconManager.getRegionViewModel(region).regionState.observe(context as LifecycleOwner, androidx.lifecycle.Observer {
            if (it == MonitorNotifier.INSIDE)
                onBeaconScannedInterfaces[identifier]?.didEnterRegion(region)
            else if (it == MonitorNotifier.OUTSIDE)
                onBeaconScannedInterfaces[identifier]?.didExitRegion(region)
        })
        beaconManager.startMonitoring(region)
    }


    fun stopRanging(identifier: String) {
        val region = Region(identifier, null, null, null)
        beaconManager.stopRangingBeacons(region)
    }

    fun stopMonitoring(identifier: String) {
        val region = Region(identifier, null, null, null)
        beaconManager.stopMonitoring(region)
    }

    interface OnBeaconScanned {
        fun onBeaconRanged(beacons: ArrayList<SnowMiBeacon>)
        fun didEnterRegion(p0: Region?)
        fun didExitRegion(p0: Region?)
    }
}

