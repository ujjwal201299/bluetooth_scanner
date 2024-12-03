package io.stratosfy.stratosfy_scanner.models

import com.google.gson.Gson
import java.util.*
import kotlin.collections.HashMap

class SnowMiBeacon {
    lateinit var uuid: String
    lateinit var macAddress: String
    lateinit var major: Number
    lateinit var minor: Number
    lateinit var txPower: Number
    lateinit var distance: Number
    lateinit var rssi: Number
    fun toObject(): HashMap<String, Any> {
        val obj: HashMap<String, Any> = HashMap()
        obj["uuid"] = uuid
        obj["rssi"] = rssi
        obj["major"] = major
        obj["minor"] = minor
        obj["txPower"] = txPower
        obj["distance"] = distance
        obj["macAddress"] = macAddress
        return obj
    }

    fun toSendObject(): String {
        val currentTime = Date().time
        val data = toObject()
        data["timestamp"] = currentTime
        return Gson().toJson(data)
    }
}