package io.stratosfy.stratosfy_scanner.helpers

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import com.google.gson.Gson

class SnowMBackgroundScanner() {
    companion object {
        fun startBackgroundScanning(context: Context) {
            val sharedPreferences = context.getSharedPreferences("snowm_scanner", Context.MODE_PRIVATE)
            val bundleData = sharedPreferences.getString("backgroundScanner", null) ?: return
            val bundle = Gson().fromJson<Bundle>(bundleData, Bundle::class.java)
            val mServiceIntent = Intent()
            mServiceIntent.setPackage(context.packageName)
            mServiceIntent.action = "io.stratosfy.stratosfy_scanner.BACKGROUND_SCANNER"
            mServiceIntent.putExtras(bundle)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(mServiceIntent)
            } else {
                context.startService(mServiceIntent)
            }
        }

        fun stopBackgroundScanning(context: Context) {
            val mServiceIntent = Intent()
            mServiceIntent.setPackage(context.packageName)
            mServiceIntent.action = "io.stratosfy.stratosfy_scanner.BACKGROUND_SCANNER"
            context.stopService(mServiceIntent)
        }
    }
}