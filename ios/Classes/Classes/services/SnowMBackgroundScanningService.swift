//
//  SnowMBackgroundScanningService.swift
//  snowm_scanner
//
//  Created by Aawaz Gyawali on 4/11/20.
//

import Foundation
import CoreLocation

public protocol SnowMBackgroundScanningServiceDelegate {
    
    func onScannerRegistered(scanId: String, customData: Dictionary<String, Any>?)
    
    func onBeaconDetected(beacons:[SnowMBeacon])
    
    func onLocationUpdated(locations: [CLLocation])
    
    func onRegionEntered(region: CLBeaconRegion)
    
    func onRegionExited(region: CLBeaconRegion)
    
    func onGeofenceRegistered(region:CLCircularRegion)
    
    func didEnterGeofence(region:CLCircularRegion)
    
    func didExitGeofence(region:CLCircularRegion)
}
