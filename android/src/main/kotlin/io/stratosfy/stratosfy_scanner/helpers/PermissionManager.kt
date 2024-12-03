package io.stratosfy.stratosfy_scanner.helpers

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import pub.devrel.easypermissions.EasyPermissions
import java.util.*

class PermissionManager(val context: Context) {
    private val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
    private val REQUEST_LOCATION_PERMISSION = 1
    private val perms = arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
    private val perms1 = arrayOf(Manifest.permission.BLUETOOTH)
    private val bluetoothStateRequests: HashMap<String?, BluetoothStateListener?> = HashMap()

    fun hasLocationPermission(): Boolean {
        return EasyPermissions.hasPermissions(context, *perms)
    }

    val bluetoothPermissionState: String
        get() = if (EasyPermissions.hasPermissions(context, *perms1)) {
            "granted"
        } else {
            "denied"
        }

    val bluetoothState: String
        get() = when {
            bluetoothAdapter == null -> {
                "unknown"
            }
            bluetoothAdapter.isEnabled -> {
                "on"
            }
            else -> {
                "off"
            }
        }

    fun bluetoothState(identifier: String?, bluetoothStateListener: BluetoothStateListener?) {
        bluetoothStateRequests[identifier] = bluetoothStateListener
        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        context.registerReceiver(mReceiver, filter)
        mReceiver.onReceive(context, Intent())
    }

    fun dispose(){
        context.unregisterReceiver(mReceiver)
    }

    fun requestLocationPermission() {
        EasyPermissions.requestPermissions((context as Activity), "Please grant the location permission", REQUEST_LOCATION_PERMISSION, *perms)
    }

    private val mReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            for (onStateRequest in bluetoothStateRequests.values) {
                try {
                    when (bluetoothAdapter!!.state) {
                        BluetoothAdapter.STATE_OFF -> onStateRequest!!.onStateChanged(BluetoothState.OFF)
                        BluetoothAdapter.STATE_ON -> onStateRequest!!.onStateChanged(BluetoothState.ON)
                        else -> onStateRequest!!.onStateChanged(BluetoothState.UNKNOWN)
                    }
                } catch (e: SecurityException) {
                    Log.d("SnowM Scanner", "Unable to retrive the bluetooth status. May be this device doesnt have a bluetooth support.")
                }
            }
        }
    }

    fun destroy() {
        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        context.unregisterReceiver(mReceiver);
    }

    fun removeBluetoothState(streamIdentifier: String) {
        bluetoothStateRequests.remove(streamIdentifier)
    }

    interface BluetoothStateListener {
        fun onStateChanged(state: BluetoothState)
    }

    enum class BluetoothState(val state: String) {
        ON("on"),
        OFF("off"),
        UNKNOWN("unknown"),
    }
}