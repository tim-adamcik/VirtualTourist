//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Timothy Adamcik on 3/10/20.
//  Copyright © 2020 Timothy Adamcik. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    fileprivate let locationManager: CLLocationManager = CLLocationManager()
    
    var annotations = [MKPointAnnotation]()
    
    fileprivate func findCurrentLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
    }
    
    fileprivate func setCenter() {
        let defaults = UserDefaults.standard
        defaults.set(37.7749, forKey: "Lat")
        defaults.set(-122.4194, forKey: "Lon")
        let center = CLLocationCoordinate2DMake(defaults.double(forKey: "Lat"), defaults.double(forKey: "Lon"))
        mapView.setCenter(center, animated: true)
        let mySpan: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        let myRegion: MKCoordinateRegion = MKCoordinateRegion(center: center, span: mySpan)
        mapView.region = myRegion
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
         // Do any additional setup after loading the view.
        mapView.delegate = self
        setCenter()
        findCurrentLocation()
        let myLongPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        myLongPress.addTarget(self, action: #selector(recognizeLongPress(_ :)))
        mapView.addGestureRecognizer(myLongPress)
    }
    
    @objc private func recognizeLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state != UIGestureRecognizer.State.began {
            return
        }
        let location = sender.location(in: mapView)
        let myCoordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
        let myPin: MKPointAnnotation = MKPointAnnotation()
        myPin.coordinate = myCoordinate
        myPin.title = "Title"
        mapView.addAnnotation(myPin)
        annotations.append(myPin)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifer = "idForView"
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifer) as? MKPinAnnotationView
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifer)
            view!.canShowCallout = true
            view!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return view
        } else {
            view!.annotation = annotation
        }
        return view
    }


    

}

