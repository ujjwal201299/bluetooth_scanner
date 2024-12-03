import Foundation
import CoreLocation

public class BackgroundBeaconScanner: NSObject, CLLocationManagerDelegate{
    
    public static let shared = BackgroundBeaconScanner();
    open var delegate: SnowMBackgroundScanningServiceDelegate?
    var defaults = UserDefaults.standard
    
    private let locationManager = CLLocationManager()
    private var customData: Dictionary<String,Any>?
    private var uuids: [String]?
    private var identifierPrefix:String?
    
    public override init(){
        super.init()
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    public func setLocationDelegate(locationDelegate: CLLocationManagerDelegate) {
        locationManager.delegate = locationDelegate
    }
    
    public func scanBeacons(scanId:String, uuids:[String], customData: Dictionary<String,Any>,identifierPrefix:String){
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        defaults.setValue(scanId, forKey: "currentScannerId")
        defaults.setValue(uuids, forKey: "uuids")
        defaults.setValue(identifierPrefix, forKey: "identifierPrefix")
        do{
            let data = try JSONSerialization.data(withJSONObject: customData, options: .prettyPrinted)
            let jsonData = String(data: data, encoding: .ascii)
            defaults.setValue(jsonData, forKey: "customData")
        } catch {
            print(error)
        }
        startBeaconRanging()
        delegate?.onScannerRegistered(scanId: scanId, customData: customData)
    }
    
    public func currentScannerId()-> String? {
        return defaults.string(forKey: "currentScannerId")
    }
    
    public func currentIdentifierPrefix()-> String? {
        getDataFromStorage()
        return identifierPrefix
    }
    
    public func startBeaconRanging(){
        getDataFromStorage()
        removeBeaconRanging()
        removeBeaconMonitoring()
        uuids!.forEach { (id) in
            let uuid = UUID(uuidString: id)
            let region = CLBeaconRegion(proximityUUID: uuid!, identifier: id+(!identifierPrefix!.isEmpty ? ("_"+identifierPrefix!) : "" ))
            locationManager.startMonitoring(for: region)
            locationManager.startRangingBeacons(in: region)
        }
    }
    
    public func addGeoFencing(identifier:String, location: CLLocationCoordinate2D, radius: CLLocationDistance, customData: Dictionary<String, Any>?){
        locationManager.requestAlwaysAuthorization()
        let region = CLCircularRegion(center: location, radius: radius, identifier: identifier)
        region.notifyOnExit = true
        region.notifyOnEntry = true
        locationManager.startMonitoring(for: region)
        if(customData == nil) {return}
        do{
            let data = try JSONSerialization.data(withJSONObject: customData, options: .prettyPrinted)
            let jsonData = String(data: data, encoding: .ascii)
            defaults.setValue(jsonData, forKey:"custom_data" + identifier)
        } catch {
            print(error)
        }
        delegate?.onGeofenceRegistered(region:region);
    }
    
    public func removeBeaconRanging(){
        for region in locationManager.rangedRegions {
            if(region is CLBeaconRegion){
                locationManager.stopRangingBeacons(in: region as! CLBeaconRegion)
            }
        }
    }
    
    public func removeLocationUpdate(){
        locationManager.stopUpdatingLocation()
    }
    
    public func removeBeaconMonitoring(){
        for region in locationManager.monitoredRegions {
            if(region is CLBeaconRegion){
                locationManager.stopMonitoring(for: region)
            }
        }
    }
    
    public func removeGeofencing(identifier:String){
        for region in locationManager.monitoredRegions {
            if(region is CLCircularRegion){
                if(region.identifier == identifier){
                    locationManager.stopMonitoring(for: region)
                }
            }
        }
    }
    
    public func removeAllGeofencing(){
        for region in locationManager.monitoredRegions {
            if(region is CLCircularRegion){
                locationManager.stopMonitoring(for: region)
            }
        }
    }
    
    public func stopBackgroundScanning(){
        removeBeaconMonitoring()
        removeLocationUpdate()
        removeBeaconRanging()
        removeGeofencing(identifier: "backgroundGeofence")
        defaults.set(nil, forKey: "currentScannerId")
        defaults.set(nil, forKey: "identifierPrefix")

    }
    
    private func getDataFromStorage(){
        uuids = defaults.stringArray(forKey: "uuids")!
        identifierPrefix = defaults.string(forKey: "identifierPrefix")
        let jsonData: String? = defaults.string(forKey: "customData")
        if(jsonData != nil){
            do{
                let data = jsonData?.data(using: .utf8)
                let decoded = try JSONSerialization.jsonObject(with: data!, options: [])
                customData = decoded as? Dictionary<String, Any>
            } catch{
                print(error)
            }
        }
    }
    
    public func getGeofenceCustomData(identifier: String) -> Dictionary<String, Any>? {
        let jsonData: String? = defaults.string(forKey:"custom_data" + identifier)
        if(jsonData != nil){
            do{
                let data = jsonData?.data(using: .utf8)
                let decoded = try JSONSerialization.jsonObject(with: data!, options: [])
                return decoded as? Dictionary<String, Any>
            } catch{
                return nil
            }
        }
        
        return nil
    }
    
    func getUuidToBeScanned() ->  [String]?{
        getDataFromStorage()
        return uuids
    }
    
    func getCustomData() ->Dictionary<String,Any>?{
        getDataFromStorage()
        return customData
    }
    
    public func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
    }
}


precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ^^ : PowerPrecedence
func ^^ (radix: Double, power: Double) -> Double {
    return Double(pow(radix, power))
}
