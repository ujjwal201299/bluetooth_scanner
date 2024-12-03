package io.stratosfy.stratosfy_scanner.models

class Geofence(private val geofence: HashMap<String, Any>) {
    var identifier: String = geofence["identifier"] as String
    var latitude: Double = geofence["latitude"] as Double
    var longitude: Double = geofence["longitude"] as Double
    var radius: Float = (geofence["radius"] as Int).toFloat()

    fun toHashMap(): HashMap<String, Any> {
        return geofence
    }
}