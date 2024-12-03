import Foundation
import CoreLocation

public class BeaconScanner: NSObject, CLLocationManagerDelegate{
    
    private let locationManager = CLLocationManager()
    private var listeners:Dictionary<String, (_ beacons:[SnowMBeacon])->()> = Dictionary()

    override init(){
        super.init()
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self;
    }
    
    public func scanBeacons(method:String ,uuids:[String], completion: @escaping (_ beacons:[SnowMBeacon])->()){
        locationManager.requestWhenInUseAuthorization()
        self.listeners[method] = completion
        uuids.forEach { (id) in
            let uuid = UUID(uuidString: id)
            let region = CLBeaconRegion(proximityUUID: uuid!, identifier: method+"_"+id)
            locationManager.startMonitoring(for: region)
            locationManager.startRangingBeacons(in: region)
        }
    }
    
    public func removeScanner(identifier: String){
        listeners.removeValue(forKey: identifier);
        locationManager.monitoredRegions.forEach { (region) in
            locationManager.stopMonitoring(for: region)
        }
        locationManager.rangedRegions.forEach { (region) in
            if(region is CLBeaconRegion){
                locationManager.stopRangingBeacons(in: region as! CLBeaconRegion)
            }
        }
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
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
        let method:String = region.identifier.split {$0 == "_"}.map(String.init)[0]
        if(listeners[method] != nil){
            self.listeners[method]!(snowmBeacons)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
    }
}
