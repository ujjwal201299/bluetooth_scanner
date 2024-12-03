@file:Suppress("DEPRECATION")

package io.stratosfy.stratosfy_scanner

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import com.google.gson.Gson
import io.stratosfy.stratosfy_scanner.helpers.*
import io.stratosfy.stratosfy_scanner.helpers.SnowMBackgroundScanner.Companion.startBackgroundScanning
import io.stratosfy.stratosfy_scanner.helpers.SnowMBackgroundScanner.Companion.stopBackgroundScanning
import io.stratosfy.stratosfy_scanner.models.Geofence
import io.stratosfy.stratosfy_scanner.models.SnowMiBeacon
import io.stratosfy.stratosfy_scanner.services.SnowMBackgroundScanningService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.altbeacon.beacon.Region
import java.util.*

class StratosfyScannerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
      var TAG: String = "SNOWM_SCANNER_PLUGIN"
      private lateinit var channel: MethodChannel
      private var iBeaconScanner: BeaconScanner? = null
      private lateinit var telemetryPacketScanner: TelemetryPacketScanner
      private lateinit var mqttHelper: MqttHelper
      private lateinit var permissionManager: PermissionManager
      private lateinit var context: Context
      private lateinit var geofencingHelper: GeofencingHelper
      private lateinit var sharedPreferences: SharedPreferences
      private var snowMBeaconTrasmitter: SnowMBeaconTrasmitter? = null

      override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
            Log.d(TAG, "onAttachedToEngine")
            channel =
                  MethodChannel(flutterPluginBinding.flutterEngine.dartExecutor, "snowm_scanner")
            channel.setMethodCallHandler(this)
      }

      private fun initilizeWithContext() {
            Log.d(TAG, "initializeWithContext")
            mqttHelper = MqttHelper(context)
            permissionManager = PermissionManager(context)
            geofencingHelper = GeofencingHelper(context)
            telemetryPacketScanner = TelemetryPacketScanner(context)
            sharedPreferences = context.getSharedPreferences("snowm_scanner", Context.MODE_PRIVATE)
            snowMBeaconTrasmitter = SnowMBeaconTrasmitter(context)
      }

      companion object {
            @JvmStatic
            fun registerWith(registrar: Registrar) {

                  val channel = MethodChannel(registrar.messenger(), "snowm_scanner")
                  channel.setMethodCallHandler(StratosfyScannerPlugin())
            }
      }

      override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
            Log.d(TAG, "onMethodCall ${call.method}")
            val method: String = call.method
            Log.d(TAG, "checking for method $method")
            when {
                  method.contains("snowm_scanner") -> {
                        Log.d(TAG, "method contains snowm_scanner")
                  }

                  method.contains("scanIBeacons") -> {
                        val uuids: ArrayList<String> = call.argument("uuids")!!
                        val enableMqtt: Boolean = call.argument<Boolean>("enableMqtt")!!
                        val timeInterval: Int = call.argument<Int>("timeInterval")!!
                        val scanAllBeacons = call.argument<Boolean>("scanAllIBeacons")!!
                        mqttHelper.timeInterval = timeInterval
                        mqttHelper.enabled = enableMqtt
                        if (permissionManager.hasLocationPermission()) {
                              scan(uuids, method, scanAllBeacons)
                        } else {
                              permissionManager.requestLocationPermission()
                              scan(uuids, method, scanAllBeacons)
                        }
                        result.success(true)
                  }

                  method.contains("scanTelemetryBeacons") -> {
                        val syncWithServer: Boolean = call.argument<Boolean>("syncWithServer")!!
                        if (permissionManager.hasLocationPermission()) {
                              scanTelemetry(method, syncWithServer)
                        } else {
                              permissionManager.requestLocationPermission()
                              scanTelemetry(method, syncWithServer)
                        }
                        // scanTelemetry(method, syncWithServer)
                        result.success(true)
                  }

                  method.contains("geofence#register") -> {
                        val geofenceMap: HashMap<String, Any> =
                              call.arguments as HashMap<String, Any>

                        val geofence = Geofence(geofenceMap)
                        geofencingHelper.stopGepfencing(geofence.identifier)
                        geofencingHelper.startGeoFencing(geofence)

                        sharedPreferences.edit().putString(
                              "geofenceCustomData#${geofence.identifier}",
                              Gson().toJson(geofenceMap["customData"])
                        ).apply()
                        result.success(true)
                  }

                  method == "geofence#remove" -> {
                        val id = call.argument<String>("identifier")!!
                        geofencingHelper.stopGepfencing(id)
                        result.success(true)
                  }

                  method == "geofence#removeAll" -> {
                        geofencingHelper.removeAllGeofencing()
                        result.success(true)
                  }

                  method == "scanIBeaconBackground" -> {
                        val uuids: ArrayList<String> = call.argument("uuids")!!
                        val customData: HashMap<String, Any> = call.argument("customData")!!
                        val title: String = call.argument("title")!!
                        val body: String = call.argument("body")!!
                        val scanId: String = call.argument("scanId")!!
                        val backgroundBetweenScanPeriod: Long =
                              call.argument("backgroundBetweenScanPeriod")!!
                        val backgroundScanPeriod: Long = call.argument("backgroundScanPeriod")!!
                        val geofences: ArrayList<HashMap<String, Any>> =
                              call.argument("geofences")!!

                        val bundle = Bundle()
                        bundle.putString("title", title)
                        bundle.putString("body", body)
                        bundle.putString("scanId", scanId)
                        bundle.putLong("backgroundBetweenScanPeriod", backgroundBetweenScanPeriod)
                        bundle.putLong("backgroundScanPeriod", backgroundScanPeriod)
                        bundle.putSerializable("customData", customData)
                        bundle.putSerializable("geofences", geofences)
                        bundle.putStringArrayList("uuids", uuids)

                        sharedPreferences.edit()
                              .putString("backgroundScanner", Gson().toJson(bundle)).apply()

                        if (!permissionManager.hasLocationPermission())
                              permissionManager.requestLocationPermission()
                        startBackgroundScanning(context)
                        for (it in geofences) {
                              val geofence = Geofence(it)
                              geofencingHelper.stopGepfencing(geofence.identifier)
                              geofencingHelper.startGeoFencing(geofence)
                        }
                        result.success(true)
                  }

                  method == "stopBackgroundScan" -> {
                        val bundleData =
                              sharedPreferences.getString("backgroundScanner", null) ?: return
                        val bundle = Gson().fromJson<Bundle>(bundleData, Bundle::class.java)
                        bundle.getStringArrayList("uuids")?.forEach {
                              geofencingHelper.stopGepfencing(it)
                        }
                        sharedPreferences.edit().remove("backgroundScanner").apply()
                        stopBackgroundScanning(context)
                        result.success(true)
                  }

                  method == "requestPermission" -> {
                        result.success(permissionManager.requestLocationPermission())
                  }

                  method == "permissionState" -> {
                        result.success(permissionManager.bluetoothPermissionState)
                  }

                  method == "bluetoothState" -> {
                        result.success(permissionManager.bluetoothState)
                  }

                  method.contains("bluetoothStateListener") -> {
                        permissionManager.bluetoothState(
                              method,
                              object : PermissionManager.BluetoothStateListener {

                                    override fun onStateChanged(bluetoothState: PermissionManager.BluetoothState) {
                                          sendBluetoothResponse(method, bluetoothState.state)
                                    }
                              })
                        result.success(true)
                  }

                  method == "cancelStream" -> {
                        if (iBeaconScanner == null) {
                              iBeaconScanner = BeaconScanner(context)
                        }
                        val streamIdentifier = call.argument<String>("methodName")!!
                        iBeaconScanner!!.stopRanging(streamIdentifier)
                        result.success(true)
                  }

                  method == "cancelBluetoothStateListener" -> {
                        val streamIdentifier = call.argument<String>("methodName")!!
                        permissionManager.removeBluetoothState(streamIdentifier)
                        result.success(true)
                  }

                  method == "getCurrentScanId" -> {
                        val scanId = SnowMBackgroundScanningService.scanId
                        Log.d(TAG,"getCurrentScanID $scanId")
                        result.success(scanId)
                  }

                  method == "transmitIBeacon" -> {
                        val beacon = SnowMiBeacon()
                        beacon.uuid = call.argument<String>("uuid")!!
                        beacon.major = call.argument<Number>("major")!!
                        beacon.minor = call.argument<Number>("minor")!!
                        beacon.txPower = call.argument<Number>("txPower")!!
                        snowMBeaconTrasmitter?.startTransmission(beacon, object : OnTransmitted {
                              override fun onSuccess(message: String?) {
                                    result.success(message)
                              }

                              override fun onUncapabelDevice(message: String?) {
                                    result.error("UncapabelDevice", message, {})

                              }

                              override fun onFaliure(errorCode: Int, message: String?) {
                                    result.error(errorCode.toString(), message, {})
                              }

                              override fun onUnknownAdvertiser(message: String?) {
                                    result.error("UnknownAdvertiser", message, {})

                              }


                        })

                  }

                  method == "stopTransmission" -> {
                        snowMBeaconTrasmitter?.stopTransmission()
                        result.success(true)
                  }

                  method == "checkTransmission" -> {
                        result.success(snowMBeaconTrasmitter?.isTransmiting ?: false)
                  }

                  method == "stopScanningTelemetry" -> {
                        telemetryPacketScanner.stopScanning()
                        result.success(true)
                  }

                  else -> {
                        print("method not implemented")
                        result.notImplemented()
                  }
            }
      }

      private fun scan(uuids: ArrayList<String>, method: String, scanAllBeacons: Boolean) {
            Log.d(TAG, "scan function called --->")
            if (iBeaconScanner == null) {
                  iBeaconScanner = BeaconScanner(context)
            }
            iBeaconScanner!!.rangeBeacons(method, 1000.0, 1100.0)
            iBeaconScanner!!.monitorBeacons(method)
            iBeaconScanner!!.setOnBeaconScanner(method,
                  object : BeaconScanner.OnBeaconScanned {
                        override fun onBeaconRanged(beacons: ArrayList<SnowMiBeacon>) {
                              val validBeacons: ArrayList<SnowMiBeacon> = ArrayList()
                              for (it in beacons) {
                                    if (!scanAllBeacons) {
                                          if (uuids.contains(it.uuid.toUpperCase()))
                                                validBeacons.add(it)
                                    } else
                                          validBeacons.add(it)
                              }
                              sendBeaconResponse(method, validBeacons)
                        }

                        override fun didEnterRegion(p0: Region?) {
                        }

                        override fun didExitRegion(p0: Region?) {
                        }
                  })
      }

      private fun scanTelemetry(method: String, syncWithServer: Boolean) {
            telemetryPacketScanner.startScanning(object : RawPacketListener {
                  override fun onPacket(rawData: String) {
                        sendRawResponse(method, rawData)
                  }
            }, syncWithServer)

      }

      private fun sendRawResponse(method: String, raw: String) {
            val response: HashMap<String, String> = HashMap()
            response["rawData"] = raw
            channel.invokeMethod(method, response)
      }

      private fun sendBeaconResponse(method: String, beacons: ArrayList<SnowMiBeacon>) {
            val response: HashMap<String, Any> = HashMap()
            response["beacons"] = beacons.map { b -> b.toObject() }
            channel.invokeMethod(method, response)
      }

      private fun sendBluetoothResponse(method: String, state: String) {
            val response: String = state
            channel.invokeMethod(method, response)
      }


      override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
            channel.setMethodCallHandler(null)
      }

      override fun onDetachedFromActivity() {
      }

      override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
      }

      override fun onAttachedToActivity(binding: ActivityPluginBinding) {
            this.context = binding.activity
            initilizeWithContext()
      }

      override fun onDetachedFromActivityForConfigChanges() {
      }


}

