package io.stratosfy.scanner_example

import android.content.Intent
import com.google.android.gms.location.Geofence
import io.stratosfy.stratosfy_scanner.services.SnowMGeofenceReceiver

class GeofenceHandler : SnowMGeofenceReceiver() {

    override fun didEnterGeofence(geofence: Geofence, customData: HashMap<String, Any>?) {
        super.didEnterGeofence(geofence, customData)
        print("callback enter")
        print(customData)
        NotificationHelper.sendNotification(123, this.context, "SnowmScanner", "You just entered a geofence", Intent())
    }

    override fun didExitGeofence(geofence: Geofence, customData: HashMap<String, Any>?) {
        super.didExitGeofence(geofence, customData)
        print("callback exit")
        print(customData)
        NotificationHelper.sendNotification(123, this.context, "SnowmScanner", "You just exited a geofence", Intent())
    }
}