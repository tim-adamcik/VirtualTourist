//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Timothy Adamcik on 3/10/20.
//  Copyright © 2020 Timothy Adamcik. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    fileprivate let locationManager: CLLocationManager = CLLocationManager()
    
    var annotations = [Pin]()
    var savedPins = [MKPointAnnotation]()
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var latitude: Double?
    var longitude: Double?
    
    fileprivate func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            annotations = result
            for annotation in annotations {
                let savePin = MKPointAnnotation()
                if let lat = CLLocationDegrees(exactly: annotation.latitude), let lon = CLLocationDegrees(exactly: annotation.longitude) {
                    let coordinateLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    savePin.coordinate = coordinateLocation
                    savePin.title = "Photos"
                    savedPins.append(savePin)
                }
            }
            mapView.addAnnotations(savedPins)
        }
    }
    
    
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
        setUpFetchedResultsController()
        findCurrentLocation()
        let myLongPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        myLongPress.addTarget(self, action: #selector(recognizeLongPress(_ :)))
        mapView.addGestureRecognizer(myLongPress)
    }
    
    @objc private func recognizeLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == UIGestureRecognizer.State.began else { return }
        let location = sender.location(in: mapView)
        let myCoordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
        let myPin: MKPointAnnotation = MKPointAnnotation()
        myPin.coordinate = myCoordinate
        myPin.title = "Photos"
        mapView.addAnnotation(myPin)
        let pin = Pin(context: DataController.shared.viewContext)
        pin.latitude = Double(myCoordinate.latitude)
        pin.longitude = Double(myCoordinate.longitude)
        annotations.append(pin)
        DataController.shared.save()
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
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let vc = storyboard?.instantiateViewController(identifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        let locationLat = view.annotation?.coordinate.latitude
        let locationLon = view.annotation?.coordinate.longitude
        let myCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: locationLat!, longitude: locationLon!)
        let selectedPin: MKPointAnnotation = MKPointAnnotation()
        selectedPin.coordinate = myCoordinate
        vc.currentLatitude = myCoordinate.latitude
        vc.currentLongitude = myCoordinate.longitude
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

