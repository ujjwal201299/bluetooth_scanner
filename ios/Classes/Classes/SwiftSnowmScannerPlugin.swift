import Flutter
import UIKit
import CoreLocation
public class SwiftSnowmScannerPlugin: NSObject, FlutterPlugin {
    var beaconScanner = BeaconScanner()
    var telemetryPacketScanner:TelemetryPacketScanner=TelemetryPacketScanner.Instance
    var permissionManager = PermissionManager()
    var mqttHelper = MqttHelper()
    var channel: FlutterMethodChannel?
    let backgroundScanner: BackgroundBeaconScanner = BackgroundBeaconScanner.shared
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "snowm_scanner", binaryMessenger: registrar.messenger())
        let instance = SwiftSnowmScannerPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let method = call.method
        let arguments: Dictionary<String, Any>? = call.arguments as! Dictionary<String, Any>?
        if method.contains("scanIBeacons"){
            let uuids:[String]  = arguments?["uuids"] as! [String]
            //TODO: Trigger mqtt protocol on native side
            let enableMqtt:Bool  =  arguments?["enableMqtt"] as! Bool
            beaconScanner.scanBeacons(method:method, uuids: uuids) { (beacons) -> () in
                if enableMqtt {
                    beacons.forEach { (beacon) in
                        self.mqttHelper.sendBeaconData(beacons:beacon)
                    }
                }
                self.sendBeaconResponse(method:method, beacons: beacons)
            }
            result(true)
        } else if method == "requestPermission"{
            result(permissionManager.requestPermission())
        } else if method == "permissionState"{
            result(permissionManager.permissionStatus)
        } else if method == "bluetoothState"{
            result(permissionManager.state)
        }  else if method == "getCurrentScanId"{
            result(backgroundScanner.currentScannerId())
        } else if method.contains( "bluetoothStateListener"){
            permissionManager.bluetoothState(method: method) { (state) in
                self.sendBluetoothStateResponse(method: method, state: state)
            }
            result(true)
        } else if method == "cancelBluetoothStateListener"{
            let streamIdentifier = arguments?["methodName"] as! String
            permissionManager.removeBluetoothState(identifier: streamIdentifier)
            result(true)
        } else if method == "cancelStream"{
            let streamIdentifier = arguments?["methodName"] as! String
            beaconScanner.removeScanner(identifier: streamIdentifier)
            result(true)
        } else if method.contains("scanTelemetryBeacons"){
            let syncWithServer = arguments?["syncWithServer"] as! Bool
            
            telemetryPacketScanner.startScan(onPacket:{ (raw) in
                self.sendRawDataResponse(method: method, raw: raw)
            },syncWithServer: syncWithServer)
            result(true)
        } else if method == "geofence#register"{
       
            let geofence: Dictionary<String, Any>  = arguments as! Dictionary<String, Any>
            
            let customData: Dictionary<String, Any>  = arguments?["customData"] as! Dictionary<String, Any>
            let id: String = geofence["identifier"] as! String
            let radius: CLLocationDistance = geofence["radius"] as! CLLocationDistance
            let point: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: geofence["latitude"] as! CLLocationDegrees, longitude: geofence["longitude"] as! CLLocationDegrees)
            backgroundScanner.addGeoFencing(identifier: id, location: point, radius: radius, customData: customData)
 
            result(true)
        } else if method == "geofence#remove"{
            let id = arguments?["identifier"] as! String
            backgroundScanner.removeGeofencing(identifier: id)
            result(true)
        } else if method == "geofence#removeAll"{
           backgroundScanner.removeAllGeofencing()
           result(true)
        } else if method == "scanIBeaconBackground"{
            let uuids:[String]  = arguments?["uuids"] as! [String]
            let scanId:String  = arguments?["scanId"] as! String
            let identifierPrefix:String  = arguments?["identifierPrefix"] as! String
            let customData:Dictionary = arguments?["customData"] as! Dictionary<String, Any>
            backgroundScanner.scanBeacons(scanId:scanId, uuids: uuids, customData: customData,identifierPrefix: identifierPrefix)
            let geofences: [Dictionary<String, Any>?] = (arguments?["geofences"] as! [Dictionary<String, Any>?])
            var count = 1
            geofences.forEach { (geofence) in
                let radius: CLLocationDistance = geofence?["radius"] as! CLLocationDistance
                let point: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: geofence?["latitude"] as! CLLocationDegrees, longitude: geofence?["longitude"] as! CLLocationDegrees)
                backgroundScanner.addGeoFencing(identifier: "backgroundGeofence#\(count)",location: point, radius: radius, customData: nil)
                count+=1
            }
            result(true)
        } else if method == "stopBackgroundScan"{
            backgroundScanner.stopBackgroundScanning()
            result(true)
        }
        else if method == "stopScanningTelemetry"{
            telemetryPacketScanner.stopScan()
            result(true)
        }
    }
    
    private func sendBluetoothStateResponse(method:String, state:String){
        channel?.invokeMethod(method, arguments: state)
    }
    private func sendRawDataResponse(method:String, raw:String){
        var response: [AnyHashable:Any] = [AnyHashable:Any]();
        response["rawData"] = raw;
        channel?.invokeMethod(method, arguments:response)
    }
    
    private func sendBeaconResponse(method:String, beacons: [SnowMBeacon]){
        var response: [AnyHashable:Any] = [AnyHashable:Any]();
        response["beacons"] = beacons.map{ $0.toObject()};
        channel?.invokeMethod(method, arguments: response)
    }
}
extension String {
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
}
