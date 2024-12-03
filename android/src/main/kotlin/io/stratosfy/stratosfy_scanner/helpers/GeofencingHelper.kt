package io.stratosfy.stratosfy_scanner.helpers

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Bundle
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import java.util.ArrayList

class GeofencingHelper(var context: Context) {
    private var geofencingClient: GeofencingClient = LocationServices.getGeofencingClient(context)
    private var geofenceList: ArrayList<Geofence> = ArrayList()

    val sharedPreferences = context.getSharedPreferences("snowm_scanner", Context.MODE_PRIVATE)
    fun startGeoFencing(geofence: io.stratosfy.stratosfy_scanner.models.Geofence) {
        geofenceList.add(Geofence.Builder()
                .setRequestId(geofence.identifier)
                .setCircularRegion(
                        geofence.latitude, geofence.longitude, geofence.radius
                )
                .setExpirationDuration(Geofence.NEVER_EXPIRE)
                .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
                .build())

        geofencingClient.addGeofences(getGeofencingRequest(), geofencePendingIntent())
        val identifiers = sharedPreferences.getStringSet("geofencesIds", setOf())!!
        identifiers.add(geofence.identifier)
        sharedPreferences.edit().putStringSet("geofencesIds", identifiers).apply()
    }

    fun stopGepfencing(identifier: String) {
        val ids = ArrayList<String>(1)
        ids.add(identifier)
        geofencingClient.removeGeofences(ids)
        val identifiers = ArrayList(sharedPreferences.getStringSet("geofencesIds", setOf())!!)
        identifiers.remove(identifier)
        sharedPreferences.edit().putStringSet("geofencesIds", identifiers.toSet()).apply()
    }

    fun removeAllGeofencing() {
        val identifiers = sharedPreferences.getStringSet("geofencesIds", setOf())!!
        geofencingClient.removeGeofences(identifiers.toList())
        sharedPreferences.edit().putStringSet("geofencesIds", setOf()).apply()
    }

    fun getGeofencingRequest(): GeofencingRequest {
        return GeofencingRequest.Builder().apply {
            setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            addGeofences(geofenceList)
        }.build()
    }

    private fun geofencePendingIntent(): PendingIntent {
        val intent = Intent()
        intent.setPackage(context.packageName)
        intent.action = "io.snowm.geofence"
        return PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
    }
}