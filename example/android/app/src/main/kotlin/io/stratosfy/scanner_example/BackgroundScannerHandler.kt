package io.stratosfy.scanner_example

import android.util.Log
import io.stratosfy.stratosfy_scanner.models.SnowMiBeacon
import io.stratosfy.stratosfy_scanner.services.SnowMBackgroundScanningService
import java.util.*


class BackgroundScannerHandler : SnowMBackgroundScanningService() {
    override fun onBeaconsDetected(beacons: ArrayList<SnowMiBeacon>) {
        super.onBeaconsDetected(beacons)
        Log.d("Scanner", "Scanned beacons")
        beacons.forEach {
            Log.d("Scanner", it.uuid)
        }
    }

    override fun onRegionEntered() {
        super.onRegionEntered()
        print("on Region entered")
    }

    override fun onRegionExited() {
        super.onRegionExited()
        print("on Region exited")
    }
}