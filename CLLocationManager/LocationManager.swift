//
//  LocationManager.swift
//  CLLocationManager
//
//  Created by Misha on 05.03.2022.
//

import CoreLocation
import Foundation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    
    let locationManager = CLLocationManager()
    
    var completion: ((CLLocation) -> Void)?
    
    var lastKnowLocation: CLLocation?
        
    public func getUserLocation(completion: @escaping ((CLLocation) -> Void)) {
        self.completion = completion
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        print(location.coordinate.latitude)
        completion?(location)
        manager.stopUpdatingLocation()
    }
    
    
}
