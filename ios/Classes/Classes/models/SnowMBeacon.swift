import Foundation

public class SnowMBeacon: NSObject {
    public var uuid: String?
    public var macAddress: String?
    public var major: Int?
    public var minor: Int?
    public var txPower: Int?
    public var distance: Double{
        get {
            return getDistance(rssi: self.rssi ?? -65)
        }
    }
    public var rssi: Int?
    
    
    public func toObject()->[AnyHashable:Any]{
        var obj:[AnyHashable:Any] = [AnyHashable:Any]()
        obj["uuid"] = uuid
        obj["macAddress"] = macAddress
        obj["major"] = major
        obj["minor"] = minor
        obj["txPower"] = txPower
        obj["distance"] = distance
        obj["rssi"] = rssi
        return obj
    }
    func getDistance(rssi:Int) -> Double{
        let mesauredPower = -65;
        let environmentalFactor = getEnvironmentalFactor(rssi:rssi)
        let core: Double = (Double(mesauredPower - rssi)) / (10.0 * environmentalFactor)
        let distance = Double(10) ^^ Double(core);
        return distance
    }
    
    func getEnvironmentalFactor(rssi:Int) -> Double{
        if(rssi < -100){ return 2}
        if(rssi > -35) {return 4}
        let range: Double = Double(rssi+100) / Double(65)
        return 2.0 + 2.0 * range
    }
    
}

