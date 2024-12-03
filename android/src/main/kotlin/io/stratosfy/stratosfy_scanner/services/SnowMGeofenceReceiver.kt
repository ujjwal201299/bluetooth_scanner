package io.stratosfy.stratosfy_scanner.services

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import com.google.android.gms.location.*
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.lang.reflect.Type


var type: Type = object : TypeToken<HashMap<String, Any>>() {}.type

open class SnowMGeofenceReceiver : BroadcastReceiver() {
    lateinit var context: Context

    private var locationProviderClient: FusedLocationProviderClient? = null
    private var sharedPreferences: SharedPreferences? = null

    override fun onReceive(context: Context, intent: Intent) {
        this.context = context
        locationProviderClient = LocationServices.getFusedLocationProviderClient(context)
        sharedPreferences = context.getSharedPreferences("snowm_scanner", Context.MODE_PRIVATE)
        if (intent.action == "android.intent.action.BOOT_COMPLETED") {
            onBootComplete()
        } else if (intent.action == "io.snowm.geofence") {
            val geofencingEvent = GeofencingEvent.fromIntent(intent)
            if (geofencingEvent.hasError()) {
                val errorMessage: String = GeofenceStatusCodes.getStatusCodeString(geofencingEvent.errorCode)
                println(errorMessage)
                return
            }
            geofencingEvent.triggeringGeofences.forEach {

                val stringData = sharedPreferences?.getString("geofenceCustomData#${it.requestId}", "{}")
                val customData = Gson().fromJson<HashMap<String, Any>?>(stringData, type)
                if (geofencingEvent.geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER) {
                    didEnterGeofence(it, customData)
                } else if (geofencingEvent.geofenceTransition == Geofence.GEOFENCE_TRANSITION_EXIT) {
                    didExitGeofence(it, customData)
                }
            }
        }
    }

    open fun didEnterGeofence(geofence: Geofence, customData: HashMap<String, Any>?) {
        println("entered")
    }

    open fun didExitGeofence(geofence: Geofence, customData: HashMap<String, Any>?) {
        println("exited")
    }

    open fun onBootComplete() {
        println("boot complete")
    }
}