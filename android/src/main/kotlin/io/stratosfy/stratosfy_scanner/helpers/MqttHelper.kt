package io.stratosfy.stratosfy_scanner.helpers

import android.content.Context
import io.stratosfy.stratosfy_scanner.models.SnowMiBeacon
import java.util.*

class MqttHelper(context: Context) {
    private var snowMMqttClient: SnowMMqttClient = SnowMMqttClient(context)
    private val dataSentHistory: HashMap<String, Long> = HashMap()

    var timeInterval: Int = 6000
    var enabled: Boolean = false

    private fun timeToSendData(time: Long?, timeInterval: Int): Boolean {
        return if (time == null)
            true
        else {
            return Date().time.minus(time) >= timeInterval
        }
    }

    fun sendIBeaconInformation(iBeacon: SnowMiBeacon) {
        if (enabled && timeToSendData(dataSentHistory[iBeacon.uuid], timeInterval)) {
            snowMMqttClient.init(iBeacon.uuid, iBeacon.toSendObject())
            dataSentHistory[iBeacon.uuid] = Date().time
        }
    }

}