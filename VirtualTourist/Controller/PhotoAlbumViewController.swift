//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Timothy Adamcik on 3/11/20.
//  Copyright © 2020 Timothy Adamcik. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var smallMapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionBtn: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var currentLatitude: Double?
    var currentLongitude: Double?
    var pin: Pin!
    var flickrPhotos: [URL]?
    var savedImages:  [Photo] = []
    let numberOfColumns: CGFloat = 3
    let saveBtn = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: Selector(("saveBtnPressed")))
    let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: Selector(("cancelBtnPressed")))
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItems = [saveBtn,cancelBtn]
        cancelBtn.isEnabled = false
        smallMapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        setCenter()
        _ = FlickrClient.shared.getFlickrPhotoURLs(lat: currentLatitude!, lon: currentLongitude!) { (urls, error) in
            if let error = error {
                DispatchQueue.main.async {
                    let alertVC = UIAlertController(title: "Error", message: "Error retrieving data", preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(alertVC, animated: true)
                    print(error.localizedDescription)
                }
            } else {
                if let urls = urls {
                    self.flickrPhotos = urls
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    @objc func saveBtnPressed(sender: UIBarButtonItem) {
        saveBtn.isEnabled = false
        cancelBtn.isEnabled = true
    }
    @objc func cancelBtnPressed(sender: UIBarButtonItem) {
        saveBtn.isEnabled = true
        cancelBtn.isEnabled = false
    }
    
    
    @IBAction func newCollectionBtnPressed(_ sender: Any) {
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func setCenter() {
        if let latitude = currentLatitude,
            let longitude = currentLongitude {
        let center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            smallMapView.setCenter(center, animated: true)
            let mySpan: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let myRegion: MKCoordinateRegion = MKCoordinateRegion(center: center, span: mySpan)
            smallMapView.setRegion(myRegion, animated: true)
            let annotation: MKPointAnnotation = MKPointAnnotation()
            annotation.coordinate = center
            smallMapView.addAnnotation(annotation)
        }
    }
}

extension PhotoAlbumViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return flickrPhotos?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrViewCell", for: indexPath) as! FlickrViewCell
        if let desiredArray = flickrPhotos {
            cell.setupCell(url: desiredArray[indexPath.row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
           let width = collectionView.frame.width / numberOfColumns
           return CGSize(width: width, height: width)
       }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
           return .zero
       }
       
       func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
           return 0
       }
       
       func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
           return 0
       }
    
    
}



