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

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    enum Mode {
        case view
        case select
    }
    
    @IBOutlet weak var smallMapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionBtn: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout! 
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var currentLatitude: Double?
    var currentLongitude: Double?
    var pin: Pin!
    var savedPhotoObjects = [Photo]()
    var flickrPhotos: [FlickrPhoto] = []
    let numberOfColumns: CGFloat = 3
    var fetchedResultsController: NSFetchedResultsController<Photo>!

    
    fileprivate func reloadSavedData() -> [Photo]? {
        var photoArray: [Photo] = []
            let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
            let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin!])
            fetchRequest.predicate = predicate
            let sortDescriptor = NSSortDescriptor(key: "imageURL", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            let photoCount = try fetchedResultsController.managedObjectContext.count(for: fetchedResultsController.fetchRequest)
            
            for index in 0..<photoCount {
                
                photoArray.append(fetchedResultsController.object(at: IndexPath(row: index, section: 0)))
            }
            return photoArray
            
        } catch {
            print("error performing fetch")
            return nil
        }
    }
    

    var mMode: Mode = .view {
        didSet {
            switch mMode {
            case .view:
                selectBtn.isEnabled = true
                navigationItem.leftBarButtonItems = nil
                if let selectedItems = collectionView.indexPathsForSelectedItems {
                    for selection in selectedItems {
                        let cell = collectionView.cellForItem(at: selection)
                        cell?.layer.borderColor = UIColor.clear.cgColor
                        cell?.layer.borderWidth = 3
                        collectionView.deselectItem(at: selection, animated: true)
                    }
                }
                collectionView.allowsMultipleSelection = false
            case .select:
                selectBtn.isEnabled = false
                navigationItem.leftBarButtonItems = [cancelBtn, deleteBtn]
                collectionView.allowsMultipleSelection = true
            }
        }
    }
    
    
    lazy var selectBtn: UIBarButtonItem = {
        let barBtnItem = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectBtnPressed(_:)))
        return barBtnItem
    }()

    lazy var cancelBtn: UIBarButtonItem = {
        let barBtnItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelBtnPressed(_:)))
        return barBtnItem
    }()
    lazy var deleteBtn: UIBarButtonItem = {
        let barBtnItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteBtnPressed(_:)))
        return barBtnItem
    }()
    
    
    private func setUpBarButtonItems() {
        navigationItem.rightBarButtonItem = selectBtn
    }
    
    fileprivate func getFlickrPhotos() {
        _ = FlickrClient.shared.getFlickrPhotoURLs(lat: currentLatitude!, lon: currentLongitude!, page: 1) { (photos, error) in
            
            if let error = error {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    let alertVC = UIAlertController(title: "Error", message: "Error retrieving data", preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(alertVC, animated: true)
                    print(error.localizedDescription)
                }
            } else {
                if let photos = photos {
                    
                    DispatchQueue.main.async {
                        self.flickrPhotos = photos
                        self.saveToCoreData(photos: photos)
                        self.activityIndicator.stopAnimating()
                        self.collectionView.reloadData()
                        self.savedPhotoObjects = self.reloadSavedData()!
                        self.showSavedResult()
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBarButtonItems()
        smallMapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //reload saved data
        let savedPhotos = reloadSavedData()
        if savedPhotos != nil && savedPhotos?.count != 0 {
            savedPhotoObjects = savedPhotos!
            showSavedResult()
        } else {
            showNewResult()
        }
        
        setCenter()
        activityIndicator.startAnimating()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
    }
    
    
    @objc func selectBtnPressed(_ sender: UIBarButtonItem) {
        mMode = mMode == .view ? .select : .view
        newCollectionBtn.isEnabled = false
    }
    @objc func cancelBtnPressed(_ sender: UIBarButtonItem) {
        mMode = mMode == .select ? .view : .select
        newCollectionBtn.isEnabled = true
    }
    
    func saveToCoreData(photos: [FlickrPhoto]) {
        
                for flickrPhoto in photos {
                    let photo = Photo(context: DataController.shared.viewContext)
                    if let url = URL(string: flickrPhoto.imageURLString()) {
                      photo.imageData = try? Data(contentsOf: url)
                    }
                    photo.imageURL = flickrPhoto.imageURLString()
                    photo.pin = pin
                    savedPhotoObjects.append(photo)
                    DataController.shared.save()
                }
            
        }
 
    
    func deleteExistingCoreDataPhoto() {
        
        for image in savedPhotoObjects {
            
            DataController.shared.viewContext.delete(image)
        }
    }
    
    func showSavedResult() {
        
        DispatchQueue.main.async {
            
            self.collectionView.reloadData()
        }
    }
    
    func showNewResult() {
        deleteExistingCoreDataPhoto()
        savedPhotoObjects.removeAll()
        
        getFlickrPhotos()
    }
    
    @objc func deleteBtnPressed(_ sender: UIBarButtonItem) {
        
        if let selectedIndexPaths = collectionView.indexPathsForSelectedItems {
            for indexPath in selectedIndexPaths {
                let savedPhoto = savedPhotoObjects[indexPath.row]
                for photo in savedPhotoObjects {
                    if photo.imageURL == savedPhoto.imageURL {
                        DataController.shared.viewContext.delete(photo)
                       try? DataController.shared.viewContext.save()
                    }
                }
            }
            savedPhotoObjects = reloadSavedData()!
            showSavedResult()
        }
    }
    
    fileprivate func getRandomFlickrImages() {
        let random = Int.random(in: 2...4)
        _ = FlickrClient.shared.getFlickrPhotoURLs(lat: currentLatitude!, lon: currentLongitude!, page: random, completion: { (photos, error) in
            
            if let error = error {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    let alertVC = UIAlertController(title: "Error", message: "Error retrieving data", preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(alertVC, animated: true)
                    print(error.localizedDescription)
                }
            } else {
                if let photos = photos {
                    
                    DispatchQueue.main.async {
                        self.flickrPhotos = photos
                        self.saveToCoreData(photos: photos)
                        self.activityIndicator.stopAnimating()
                        self.savedPhotoObjects = self.reloadSavedData()!
                        self.showSavedResult()
                    }
                }
            }
        })
    }
    
    @IBAction func newCollectionBtnPressed(_ sender: Any) {
        
        
        activityIndicator.startAnimating()
        deleteExistingCoreDataPhoto()
        getRandomFlickrImages()
        activityIndicator.stopAnimating()
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
        return savedPhotoObjects.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrViewCell", for: indexPath) as! FlickrViewCell
        
        let photoObject = savedPhotoObjects[indexPath.row]
        activityIndicator.stopAnimating()
        cell.initWithPhoto(photoObject)
        
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
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if selectBtn.isEnabled == false {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderColor = UIColor.clear.cgColor
            cell?.layer.borderWidth = 3
            cell?.isSelected = false
        }
    }
    
}



