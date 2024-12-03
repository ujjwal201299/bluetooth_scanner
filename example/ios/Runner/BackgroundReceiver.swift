import Foundation
import CoreLocation
import snowm_scanner


@available(iOS 10.0, *)
class BackgroundReceiver: NSObject, SnowMBackgroundScanningServiceDelegate, CLLocationManagerDelegate {
   
    
    static let shared  = BackgroundReceiver()
    
    let backgroundScanner = BackgroundBeaconScanner.shared
    let notificationHelper  = NotificationHelper()
    func onScannerRegistered(scanId: String, customData: Dictionary<String, Any>?) {
        
    }
    
    func onBeaconDetected(beacons: [SnowMBeacon]) {
        
    }
    
    func onGeofenceRegistered(region: CLCircularRegion) {
        notificationHelper.scheduleNotification(body: "Hello there!!!")
        var customData = backgroundScanner.getGeofenceCustomData(identifier: region.identifier)
        print(customData)
    }
    
    // Come to life 20 seconds
    func didExitGeofence(region: CLCircularRegion) {
        var customData = backgroundScanner.getGeofenceCustomData(identifier: region.identifier)
        notificationHelper.scheduleNotification(body:"Hello Exit Event")
        
    }
    func didEnterGeofence(region: CLCircularRegion) {
        var customData = backgroundScanner.getGeofenceCustomData(identifier: region.identifier)
        notificationHelper.scheduleNotification(body:"Hello Enter Event")
    }
    func onRegionExited(region: CLBeaconRegion) {
        
    }
    func onRegionEntered(region: CLBeaconRegion) {
        
    }
    func onLocationUpdated(locations: [CLLocation]) {
        
    }
    
}


@available(iOS 10.0, *)
extension BackgroundReceiver {
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
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
    }
}
