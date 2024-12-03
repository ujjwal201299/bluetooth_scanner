//
//  TelemetryPacketScanner.swift
//  snowm_scanner
//
//  Created by Brainants Work on 18/01/2021.
//

import Foundation
import CoreBluetooth

public class TelemetryPacketScanner: NSObject,CBCentralManagerDelegate{
    var canScan = false
    var cbCentralManager:CBCentralManager!
    var postLink:String = "https://api.genius.stratosfy.io/device/deviceData"
    static let Instance = TelemetryPacketScanner()
    var defaults:UserDefaults = UserDefaults.standard
    var oneHourInMills = 3600000
    
    var onPacket :((String)->())?
    
    private override init(){
        super.init()
        cbCentralManager = CBCentralManager.init(delegate: self, queue: nil)
    }
    
    
    private func saveSentDetails(packet: String) {
        defaults.set(Int(NSDate().timeIntervalSince1970), forKey: packet)
    }
    
    private func getSentDetails(packet: String) -> Int {
        var date = defaults.value(forKey: packet)
        if(date==nil){
            date=0
        }
        return date as! Int
    }
   
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let raw = "\(String(describing: advertisementData["kCBAdvDataManufacturerData"]))"
        if(raw != "nil")
        {
            let finalRaw = self.getRawDataOnly(raw)
            if(self.stratosfyCompanyCode(finalRaw)){
                let callBackRawData = self.getRaw(raw: finalRaw)
                onPacket?(callBackRawData);
            }
        }
    }
    func startScan(onPacket:@escaping(String)->(),syncWithServer:Bool) {
        self.onPacket = onPacket
        cbCentralManager.scanForPeripherals(withServices: nil)
    }

    func getRaw(raw:String)->String{
        //currently all headers are same as per doc (also  of no use) and cannot get the header so this is currently hack for the headers
        return "0201061BFF"+raw.uppercased().removingWhitespaces();
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            canScan = true
        default:
            print("central.state missing")
        }
        
    }
    func stopScan(){
        cbCentralManager.stopScan()
    }
    
    func getRawDataOnly(_ allData:String)->String{
        let midRaw = allData.components(separatedBy: "Optional(<")[1]
        return midRaw.components(separatedBy: ">)")[0]
    }
    
    func stratosfyCompanyCode(_ rawData:String)->Bool{
        let companyId = rawData.prefix(4)
        //change company code if required here
        return companyId == "8646"
    }
    
}

protocol RawPacketListener {
    func onPacket(rawData:String) -> Void
}



extension String {
    subscript(_ i: Int) -> String {
        let idx1 = index(startIndex, offsetBy: i)
        let idx2 = index(idx1, offsetBy: 1)
        return String(self[idx1..<idx2])
    }
}
extension Data {
    
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    var decimalString: String {
        return map { String(format: "%d", $0) }.joined()
    }
    
}
