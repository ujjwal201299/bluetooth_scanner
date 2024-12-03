# snowm_scanner

A cross platform package for flutter to scan beacons from SnowM Inc.

## Getting Started

### Installation

```
dependencies:
  snowm_scanner:
```

#### Android Configuration

Make use you have flutter_embedding v2 enabled. Add the following code on the manifest file inside `<application>` tag to enable embedding.

```
<meta-data
    android:name="flutterEmbedding"
    android:value="2" />
```

Also, use `io.flutter.embedding.android.FlutterActivity` as your FlutterActivity

### Bluetooth Permission

#### Check permission

```
    BluetoothPermissionState permissionState = await snowmScanner.getPermissionState();
```

#### Ask permission

```
    snowmScanner.requestPermission();
```

### Bluetooth Adapter State

#### Check State Once

```
    BluetoothState bluetoothState = await snowmScanner.getBluetoothState();
```

#### Get Status Stream

```
    snowmScanner.getBluetoothStateStream().listen((bluetoothState){
        // Get the state changed here
    });
```

### Scanner Configuration

Configure whether to send the scanned information to IOT Core via MQTT protocol. (Optional)

```
    snowmScanner.configure(enableMqtt: true);

```

### Scanning

Start Scanning beacons on foreground. Cancel the scanner by calling `cancel()` on the subscription stream
(Will only scan when the app is on foreground or just entered to background and has not been terminated by the OS)

```
snowmScanner.scanBeacons(uuids: uuids).listen((beacons) {
     // Do anything with beacon
});
```

## Background Scanning (Optional)

### Android configuration

Create a class that extends `FlutterApplication` and add the following code on the `onCreate` function.

```
import io.stratosfy.stratosfy_scanner.services.SnowMBackgroundScanningService
import io.flutter.app.FlutterApplication

class MyApplication  : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        SnowMBackgroundScanningService.initializeWithApplication(this)
    }
}
```

Now register the class as your application name on manifest file under name label.

```
    <application
        android:name=".MyApplication"
        ...
```

Create a service which extends to `SnowMBackgroundScanningService` as below. You will get beacons scanned response on the `onBeaconsDetected` callback with `beacons` and `customData` that you can send while scanning.

```
class BackgroundScanner : SnowMBackgroundScanningService() {

    override fun onBeaconsDetected(beacons: ArrayList<SnowMiBeacon>, customData: HashMap<String,Any>) {
        super.onBeaconsDetected(beacons, customData)
        Log.d("Scanner","Scanned beacons")
        beacons.forEach {
            Log.d("Scanner",it.uuid)
        }
    }
}
```

Now define the service on the manifest as below

```
        <service
            android:name="io.stratosfy.stratosfy_scanner_example.BackgroundScanner"
            android:exported="false">
            <intent-filter>
                <action android:name="io.stratosfy.stratosfy_scanner.BACKGROUND_SCANNER" />
            </intent-filter>
        </service>
```

Also define a broadcast receiver to re initilize the scanner if its closed by uncertain events

```
        <receiver
            android:name="io.stratosfy.stratosfy_scanner.services.SnowMGeofenceReceiver"
            android:enabled="true"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
            </intent-filter>
        </receiver>
```

### iOS configuration

Create a class which extends `SnowMBackgroundScanningServiceDelegate` to receive detection callback.

```
import Foundation
import CoreLocation
import snowm_scanner

class BackgroundScannerResponse: NSObject, SnowMBackgroundScanningServiceDelegate, CLLocationManagerDelegate {
    static let shared = BackgroundScannerResponse()

    func onLocationUpdated(locations: [CLLocation]) {
        print("on Location change detected");
    }

    func onBeaconDetected(beacons: [SnowMBeacon], customData: Dictionary<String, Any>?) {
        print("onBeacon detected called from background scanner");
    }
}
```

You have to add an extension over your background scanner handler class

```
extension BackgroundScannerResponse{
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion{
            self.didEnterGeofence(region: region as! CLCircularRegion);
        } else if region is CLBeaconRegion{
            self.onRegionEntered(region: region as! CLBeaconRegion)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion{
            self.didExitGeofence(region: region as! CLCircularRegion)
        } else {
            self.onRegionExited(region: region as! CLBeaconRegion)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.onLocationUpdated(locations: locations)
    }

    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if (beacons.count==0) {return}
        let snowmBeacons:[SnowMBeacon] = beacons.map {
            let snowmBeacon = SnowMBeacon()
            snowmBeacon.uuid = $0.proximityUUID.uuidString
            snowmBeacon.major = $0.major.intValue
            snowmBeacon.minor = $0.minor.intValue
            snowmBeacon.txPower = 0
            snowmBeacon.macAddress = "Unavailable"
            snowmBeacon.rssi = $0.rssi
            return snowmBeacon
        }
        self.onBeaconDetected(beacons: snowmBeacons)
    }

}
```

Now, call the `registerScannerDelegate` from your `AppDelegate` class inside `didFinishLaunchingWithOptions` function.

```
    BackgroundBeaconScanner.shared.delegate = BackgroundScannerResponse.shared
    BackgroundBeaconScanner.shared.locationDelegate = BackgroundScannerResponse.shared
```

### Background Scanning

Start Scanning beacons on background
(Will only scan the beacons on both foreground/background/terminated states)

```
    snowmScanner.scanBeaconsBackground(uuids: uuids);
```

It will start background scanner and send a callback on native android and iOS platforms respectively
