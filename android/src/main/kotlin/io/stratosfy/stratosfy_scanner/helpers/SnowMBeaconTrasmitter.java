package io.stratosfy.stratosfy_scanner.helpers;

import android.bluetooth.BluetoothManager;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import androidx.annotation.RequiresApi;

import io.stratosfy.stratosfy_scanner.models.SnowMiBeacon;

import org.altbeacon.beacon.Beacon;
import org.altbeacon.beacon.BeaconParser;
import org.altbeacon.beacon.BeaconTransmitter;

import java.lang.reflect.Field;
import java.util.Collections;


public class SnowMBeaconTrasmitter {
    private BeaconTransmitter mBeaconTransmitter;
    Context context;

    public SnowMBeaconTrasmitter(Context context) {
        this.context = context;
        mBeaconTransmitter = new BeaconTransmitter(context, new BeaconParser().setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24"));
    }

    public void startTransmission(SnowMiBeacon snowMiBeacon, final OnTransmitted onResult) {
        if (checkTransmissionCapabilityOfDevice()) {
            BluetoothLeAdvertiser bluetoothLeAdvertis = ((BluetoothManager) this.context.getSystemService(Context.BLUETOOTH_SERVICE)).getAdapter().getBluetoothLeAdvertiser();
            if (bluetoothLeAdvertis != null) {
                Beacon beacon = new Beacon.Builder()
                        .setId1(snowMiBeacon.uuid)
                        .setId2(snowMiBeacon.major.toString())
                        .setId3(snowMiBeacon.minor.toString())
                        .setManufacturer(0x004C)
                        .setTxPower((Integer) snowMiBeacon.txPower)
                        .setDataFields(Collections.singletonList(10L))
                        .build();
                mBeaconTransmitter.startAdvertising(beacon, new AdvertiseCallback() {
                    @Override
                    public void onStartSuccess(AdvertiseSettings settingsInEffect) {
                        super.onStartSuccess(settingsInEffect);
                        onResult.onSuccess("Transmitted successfully");
                    }

                    @Override
                    public void onStartFailure(int errorCode) {
                        super.onStartFailure(errorCode);
                        onResult.onFaliure(errorCode, getErrorFromCode(errorCode));
                    }
                });

            } else {
                onResult.onUnknownAdvertiser("Your device cannot broadcast beacons");
            }

        } else {
            onResult.onUncapabelDevice("Your Device is not capable of transmitting beacons");
        }

    }

    String getErrorFromCode(int errorCode) {
        switch (errorCode) {
            case 0:
                return "The requested operation was successful.";
            case 1:
                return "Failed to start advertising as the advertise data to be broadcasted is larger than 31 bytes.";
            case 2:
                return "Failed to start advertising as there are too many Advertisers";
            case 3:
                return "Failed to start advertising as the advertising is already started.";
            case 4:
                return "Operation failed due to an internal error.";
            case 5:
                return "This feature is not supported on this platform.";
            default:
                return "Internal error";
        }
    }

    public void stopTransmission() {
        if (mBeaconTransmitter.isStarted())
            mBeaconTransmitter.stopAdvertising();
    }

    public boolean isTransmiting() {
        return mBeaconTransmitter.isStarted();
    }

    boolean checkTransmissionCapabilityOfDevice() {
        if (!context.getApplicationContext().getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            return false;
        }
        return true;
    }
}

