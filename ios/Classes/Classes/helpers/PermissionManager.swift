
import Foundation
import CoreBluetooth
import CoreLocation

public class PermissionManager : NSObject, CBCentralManagerDelegate, CLLocationManagerDelegate  {
    let locationManager = CLLocationManager()
    var manager: CBCentralManager!
    var state = "unknown"
    var listeners : Dictionary<String,(_ state:String)->()> = Dictionary()
    var permissionStatus:String = "denied"
    
    override init() {
        super.init()
        manager = CBCentralManager()
        manager.delegate = self
        
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self;
    }
    
    public func getState()->String{
        return state;
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            permissionStatus = "denied"
            break
        case .authorizedAlways:
            permissionStatus = "granted"
            break
        case .authorizedWhenInUse:
            permissionStatus = "whenInUse"
            break
        case .notDetermined:
            permissionStatus = "unknown"
            break
        case .denied:
            permissionStatus = "denied"
            break
        default:
            permissionStatus = "unknown"
            break
        }
    }
    
    
    public func requestPermission(){
        locationManager.requestAlwaysAuthorization()
    }
    
    
    public func bluetoothState(method:String, completion: @escaping (_ state:String)->()){
        completion(state)
        listeners[method] = completion
    }
    
    public func removeBluetoothState(identifier:String){
        listeners.removeValue(forKey: identifier)
    }
    
    func sendToListeners(){
        listeners.forEach { (data) in
            let (_, value) = data
            value(state);
        }
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            state = "on"
            break;
        case .unknown:
            state = "unknown"
            break;
        case .resetting:
            state = "resetting"
            break;
        case .unsupported:
            state = "unsupported"
            break;
        case .unauthorized:
            state = "unauthorized"
            break;
        case .poweredOff:
            state = "off"
            break;
        @unknown default:
            state = "unknown"
            break;
        }
        sendToListeners()
    }
    
    
    
    
    
}
