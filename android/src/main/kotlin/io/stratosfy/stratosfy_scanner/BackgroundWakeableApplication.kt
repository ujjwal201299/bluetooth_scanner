@file:Suppress("DEPRECATION")

package io.stratosfy.stratosfy_scanner

import io.stratosfy.stratosfy_scanner.helpers.SnowMBackgroundScanner.Companion.startBackgroundScanning
import io.flutter.app.FlutterApplication
import org.altbeacon.beacon.Region
import org.altbeacon.beacon.startup.BootstrapNotifier
import org.altbeacon.beacon.startup.RegionBootstrap

open class BackgroundWakeableApplication : FlutterApplication(), BootstrapNotifier {
    private var regionBootstrap: RegionBootstrap? = null
    override fun onCreate() {
        super.onCreate()
    }

    fun registerRegion(region: Region?) {
       if (regionBootstrap == null)
           regionBootstrap = RegionBootstrap(this, region)
       else
           regionBootstrap?.addRegion(region)
    }

    fun unregisterRegion(region: Region?) {
        regionBootstrap?.removeRegion(region)
    }

    override fun didEnterRegion(region: Region) {
        startBackgroundScanning(this)
    }

    override fun didExitRegion(region: Region) {
        startBackgroundScanning(this)
    }

    override fun didDetermineStateForRegion(i: Int, region: Region) {}
}