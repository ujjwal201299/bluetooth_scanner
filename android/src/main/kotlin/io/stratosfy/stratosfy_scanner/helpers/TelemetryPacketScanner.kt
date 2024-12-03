package io.stratosfy.stratosfy_scanner.helpers

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothAdapter.ACTION_REQUEST_ENABLE
import android.bluetooth.BluetoothAdapter.getDefaultAdapter
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.AsyncTask
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat.startActivityForResult
import com.google.gson.Gson
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.*
import kotlin.collections.HashMap


class TelemetryPacketScanner(private val context: Context) {
    var btAdapter: BluetoothAdapter? = null
    var btScanner: BluetoothLeScanner? = null
    var syncWithServer: Boolean = false
    var rawPacketListener: RawPacketListener? = null
    val sharedPreferences: SharedPreferences = context.getSharedPreferences("telemetry", Context.MODE_PRIVATE)
    var uuidBatteryPool: HashMap<String, String> = HashMap<String, String>()

    fun startScanning(callBack: RawPacketListener, syncWithServer: Boolean) {
        this.syncWithServer = syncWithServer
        rawPacketListener = callBack
        btAdapter = getDefaultAdapter();
        btScanner = btAdapter!!.bluetoothLeScanner
        if (btAdapter != null && !btAdapter!!.isEnabled) {
            val enableIntent = Intent(ACTION_REQUEST_ENABLE)
            startActivityForResult((context as Activity), enableIntent, 1, null);
        }
        AsyncTask.execute { btScanner!!.startScan(leScanCallback) }
    }

    fun stopScanning() {
        AsyncTask.execute { btScanner!!.stopScan(leScanCallback) }
    }

    var oneHourInMills = 3600000
    private val client = OkHttpClient()
    private val gson = Gson()
    private val reportLink = "https://api.genius.stratosfy.io/device/deviceData"

    private fun saveSentDetails(packet: String) {
        sharedPreferences.edit().putLong(packet, Date().time)
    }

    private fun getSentDetails(packet: String): Long {
        return sharedPreferences.getLong(packet, 0)

    }

    fun syncWithServer(packet: String) {
        var time = getSentDetails(packet)
        if (time != null) {
            if ((Date().time - time) > oneHourInMills) {
                val media: MediaType? = "application/json; charset=utf-8".toMediaTypeOrNull()
                var packetInMap: HashMap<String, String> = HashMap()
                packetInMap["rawData"] = packet
                var body = gson.toJson(packetInMap)
                val requestBody: RequestBody = body.toRequestBody(media)
                val request: Request = Request.Builder().url(reportLink).post(requestBody).header("Content-Type", "application/json").build()

                AsyncTask.execute {
                    try {
                        val response: Response = client.newCall(request).execute()
                        if (response.isSuccessful) {
                            saveSentDetails(packet)
                        }
                    } catch (e: Exception) {
                        false
                    }

                }
            }
        }

    }


    private val leScanCallback: ScanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val manufacturerData = trim(result.scanRecord?.bytes!!)?.let { toHex(it) }
            if (manufacturerData?.let { checkIfCorrectCompany(it) } == true) {
                if (syncWithServer) syncWithServer(manufacturerData)
                rawPacketListener?.onPacket(manufacturerData)


            }
        }
    }

    fun trim(bytes: ByteArray): ByteArray? {
        var i = bytes.size - 1
        while (i >= 0 && bytes[i] == byteArrayOf(0)[0]) {
            --i
        }
        return bytes.copyOf(i + 1)
    }


    fun toHex(bytearray: ByteArray): String {
        var data = ""
        for (b in bytearray) {
            val st = String.format("%02X", b)
            data += st;
        }
        return data;
    }

    fun checkIfCorrectCompany(hex: String): Boolean {
        if(hex.length<14) return false;
        val company = hex.substring(10, 14)
        //change company code here if required
        return company == "8646";
    }
}

interface RawPacketListener {
    fun onPacket(rawData: String)
}

