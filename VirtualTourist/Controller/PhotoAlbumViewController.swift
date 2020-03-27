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

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var smallMapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionBtn: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var currentLatitude: Double?
    var currentLongitude: Double?
    let spacingBetweenItems:CGFloat = 3
    var pin: Pin!
    var flickrPhotos: [URL]?
    var savedImages:  [Photo] = []
    let saveBtn = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: Selector(("saveBtnPressed")))
    let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: Selector(("cancelBtnPressed")))
    private let sectionInsets = UIEdgeInsets(top: 50.0,
                                             left: 20.0,
                                             bottom: 50.0,
                                             right: 20.0)
    private let itemsPerRow: CGFloat = 3


    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return flickrPhotos?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrViewCell", for: indexPath) as! FlickrViewCell
        if let desiredArray = flickrPhotos {
            DispatchQueue.main.async {
                cell.activityIndicator.isHidden = false
                cell.activityIndicator.startAnimating()
                if let dataForImage =  try? Data(contentsOf: desiredArray[indexPath.row]) {
                    cell.photoImage.image = UIImage(data: dataForImage)
                } else {
                    cell.photoImage.image = #imageLiteral(resourceName: "film-reel")
                }
                cell.activityIndicator.stopAnimating()
            }
        }
        return cell
    }

//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//
//        let width = UIScreen.main.bounds.width / 3 - spacingBetweenItems
//        let height = width
//        return CGSize(width: width, height: height)
//    }
//
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//
//        return spacingBetweenItems
//    }

    
    
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

//         Flow layout
//        let space: CGFloat = 3.0
//        let dimension = (self.view.frame.size.width - (2 * space)) / 3.0
//
//        flowLayout.minimumInteritemSpacing = spacingBetweenItems
//        flowLayout.minimumLineSpacing = spacingBetweenItems
//        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
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

// MARK: - Collection View Flow Layout Delegate
extension PhotoAlbumViewController : UICollectionViewDelegateFlowLayout {
  //1
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    //2
    let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / itemsPerRow
    
    return CGSize(width: widthPerItem, height: widthPerItem)
  }
  
  //3
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
    return sectionInsets
  }
  
  // 4
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }
}
