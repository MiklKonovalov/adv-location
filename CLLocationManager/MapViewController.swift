//
//  ViewController.swift
//  CLLocationManager
//
//  Created by Misha on 05.03.2022.
//

import CoreLocation
import MapKit
import UIKit

enum Strings: String {
    case location
    case startpoint
    case destination
    
    var localized: String {
        return NSLocalizedString(rawValue, comment: "")
    }
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {

    var locationManager = CLLocationManager()
    
    var valueLocationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var count = 0
    
    private let map: MKMapView = {
        let map = MKMapView()
        map.mapType = .satellite
        map.showsTraffic = true
        return map
    }()
    
    //MARK: -Lifecycle:
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(map)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        title = Strings.location.localized

        self.map.delegate = self
        locationManager.delegate = self
        
        valueLocationLabel.text = "Test"
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(pinLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2.0
        gestureRecognizer.delegate = self
        gestureRecognizer.cancelsTouchesInView = false
        map.addGestureRecognizer(gestureRecognizer)
        
        LocationManager.shared.getUserLocation { [weak self] location in
            DispatchQueue.main.async { [self] in
                guard let strongSelf = self else { return }
                strongSelf.addMapPin(with: location)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
        
    }

    //MARK: -Functions:
    
    func addMapPin(with location: CLLocation) {
        let pin = MKPointAnnotation()
        pin.coordinate = location.coordinate
        pin.title = Strings.startpoint.localized
        map.setRegion(MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(
                                latitudeDelta: 0.1,
                                longitudeDelta: 0.1)
                            ),
                            animated: true)
        map.addAnnotation(pin)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4.0
        
        return renderer
    }
    
    //MARK: -Selectors
    @objc func pinLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: self.map)
            let touchCoordinates = self.map.convert(touchPoint, toCoordinateFrom: self.map)
           
            let newPin = MKPointAnnotation()
            newPin.coordinate = touchCoordinates
            
            count += 1
            
            func pinCountUniversal(count: UInt) -> String{
                    
                let formatString : String = NSLocalizedString("pin count", comment: "Pin count string format to be found in Localized.stringsdict")
                    let resultString : String = String.localizedStringWithFormat(formatString, count)
                    return resultString;
            }
            
            if count != 0 {
                newPin.title = pinCountUniversal(count: UInt(count))
            }
            
            map.addAnnotation(newPin)
            
            LocationManager.shared.getUserLocation { [weak self] location in
                DispatchQueue.main.async {
                    //1.
                    let destinationLocation = CLLocationCoordinate2D(latitude: newPin.coordinate.latitude, longitude: newPin.coordinate.longitude)
                    //2.
                    let destinationPlacemark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
                    //3.
                    let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
                    //4.
                    let destinationAnnotation = MKPointAnnotation()
                    destinationAnnotation.title = newPin.title

                    if let location = destinationPlacemark.location {
                        destinationAnnotation.coordinate = location.coordinate
                    }
                    //5.
                    self?.map.addAnnotation(destinationAnnotation)
            
                    //6.
                    let directionRequest = MKDirections.Request()
            
                    let sourceLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)

                    directionRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceLocation, addressDictionary: nil))
                    directionRequest.destination = destinationMapItem
                    directionRequest.requestsAlternateRoutes = true
                    directionRequest.transportType = .automobile
            
                    // Calculate the direction
                    let directions = MKDirections(request: directionRequest)
            
                    //7.
                    directions.calculate { (response, error) -> Void in
                        guard let directionResponse = response else {
                            if let error = error {
                                print("Error getting directions: \(error.localizedDescription)")
                            }
                            return
                        }
    
                        let route = directionResponse.routes[0]
                        self?.map.addOverlay(route.polyline, level: .aboveRoads)
    
                        let rect = route.polyline.boundingMapRect
                        self?.map.setRegion(MKCoordinateRegion(rect), animated: true)
                    }
                }
            }
        }
    }
}

