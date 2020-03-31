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
    
    enum Mode {
        case view
        case select
    }
    
    @IBOutlet weak var smallMapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionBtn: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    
    var currentLatitude: Double?
    var currentLongitude: Double?
    var pin: Pin!
    var flickrPhotos: [URL]?
    var collectionImages: [FlickrPhoto]? = []
    var savedImages:  [Photo] = []
    let numberOfColumns: CGFloat = 3
//    var fetchedResultsController: NSFetchedResultsController<Photo>
    
    var copiedFlickrObjectArray: FlickrClient = FlickrClient()
    
    var mMode: Mode = .view {
        didSet {
            switch mMode {
            case .view:
                selectBtn.isEnabled = true
                saveBtn.isEnabled = false
                navigationItem.leftBarButtonItem = nil
                if let selectedItems = collectionView.indexPathsForSelectedItems {
                    for selection in selectedItems {
                        let cell = collectionView.cellForItem(at: selection)
                        cell?.layer.borderColor = UIColor.clear.cgColor
                        cell?.layer.borderWidth = 3
                        collectionView.deselectItem(at: selection, animated: true)
                    }
                }
                dictionarySelectedIndexPath.removeAll()
                collectionView.allowsMultipleSelection = false
            case .select:
                selectBtn.isEnabled = false
                saveBtn.isEnabled = true
                navigationItem.leftBarButtonItem = cancelBtn
                collectionView.allowsMultipleSelection = true
            }
        }
    }
    
    
    lazy var selectBtn: UIBarButtonItem = {
        let barBtnItem = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectBtnPressed(_:)))
        return barBtnItem
    }()
    lazy var saveBtn: UIBarButtonItem = {
        let barBtnItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveBtnPressed(_:)))
        return barBtnItem
    }()
    lazy var cancelBtn: UIBarButtonItem = {
        let barBtnItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelBtnPressed(_:)))
        return barBtnItem
    }()
    
    
    var dictionarySelectedIndexPath: [IndexPath: Bool] = [:]
    
    private func setUpBarButtonItems() {
        navigationItem.rightBarButtonItems = [selectBtn, saveBtn]
        saveBtn.isEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let copiedFlickrObjectArray: FlickrClient = FlickrClient()
        collectionImages = copiedFlickrObjectArray.flickrObjects
        setUpBarButtonItems()
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
    
    @objc func selectBtnPressed(_ sender: UIBarButtonItem) {
        mMode = mMode == .view ? .select : .view
    }
    @objc func cancelBtnPressed(_ sender: UIBarButtonItem) {
        mMode = mMode == .select ? .view : .select
    }
    
    @objc func saveBtnPressed(_ sender: UIBarButtonItem) {
        
        if let selectedItems = collectionView.indexPathsForSelectedItems {
            if selectedItems.count > 0, dictionarySelectedIndexPath.count > 0 {
                for selection in selectedItems {
                    var i = 0
                    let cell = collectionView.cellForItem(at: selection) as! FlickrViewCell
                    let data = cell.photoImage.image?.pngData()
                    
                    let imageURLString = collectionImages?[i].imageURLString()
                    i += 1
                    
                    let photo = Photo(context: DataController.shared.viewContext)
                    photo.imageData = data
                    photo.imageURL = imageURLString
                    photo.pin = pin
                    savedImages.append(photo)
                    //        DataController.shared.save()
                }
              
            }
            
        }
        
        
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

        
        if cell.isSelected {
            cell.layer.borderColor = UIColor.blue.cgColor
            cell.layer.borderWidth = 3
        } else {
            cell.layer.borderColor = UIColor.clear.cgColor
            cell.layer.borderWidth = 3
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectBtn.isEnabled == false {
            let cell = collectionView.cellForItem(at: indexPath)
            if cell?.isSelected == true {
                cell?.layer.borderColor = UIColor.blue.cgColor
                cell?.layer.borderWidth = 3
                dictionarySelectedIndexPath[indexPath] = true
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if selectBtn.isEnabled == false {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderColor = UIColor.clear.cgColor
            cell?.layer.borderWidth = 3
            cell?.isSelected = false
            dictionarySelectedIndexPath[indexPath] = false
        }
    }
    
}



