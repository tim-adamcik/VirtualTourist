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

    
    fileprivate func reloadSavedData() {
        if fetchedResultsController == nil {
            let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
            let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin!])
            fetchRequest.predicate = predicate
            let sortDescriptor = NSSortDescriptor(key: "imageURL", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
        }
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("error performing fetch")
        }
    }
    
    
    var mMode: Mode = .view {
        didSet {
            switch mMode {
            case .view:
                selectBtn.isEnabled = true
                saveBtn.isEnabled = false
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
                saveBtn.isEnabled = true
                navigationItem.leftBarButtonItems = [cancelBtn, deleteBtn]
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
    lazy var deleteBtn: UIBarButtonItem = {
        let barBtnItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteBtnPressed(_:)))
        return barBtnItem
    }()
    
    
    private func setUpBarButtonItems() {
        navigationItem.rightBarButtonItems = [selectBtn, saveBtn]
        saveBtn.isEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBarButtonItems()
        smallMapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        reloadSavedData()
        
        setCenter()
        activityIndicator.startAnimating()
        _ = FlickrClient.shared.getFlickrPhotoURLs(lat: currentLatitude!, lon: currentLongitude!) { (photos, error) in
        
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
                    self.flickrPhotos = photos
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.collectionView.reloadData()
                    }
                }
            }
        }
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
    
    @objc func saveBtnPressed(_ sender: UIBarButtonItem) {
        
        if let selectedIndexPaths = collectionView.indexPathsForSelectedItems {
                for indexPath in selectedIndexPaths {
                    let flickrPhoto = flickrPhotos[indexPath.row]
                    let photo = Photo(context: DataController.shared.viewContext)
                    if let url = URL(string: flickrPhoto.imageURLString()) {
                      photo.imageData = try? Data(contentsOf: url)
                    }
                    photo.imageURL = flickrPhoto.imageURLString()
                    photo.pin = pin
                    DataController.shared.save()
                }
            }
        }
    
    @objc func deleteBtnPressed(_ sender: UIBarButtonItem) {
        
        if let selectedIndexPaths = collectionView.indexPathsForSelectedItems {
            for indexPath in selectedIndexPaths {
                let savedPhoto = fetchedResultsController.object(at: indexPath)
                for photo in fetchedResultsController.fetchedObjects! {
                    if photo.imageURL == savedPhoto.imageURL {
                        DataController.shared.viewContext.delete(photo)
                       try? DataController.shared.viewContext.save()
                    }
                }
            }
        }
    }
    
    @IBAction func newCollectionBtnPressed(_ sender: Any) {
        collectionView.reloadData()
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
        switch section {
        case 0:
            return fetchedResultsController.sections?[section].numberOfObjects ?? 0
        default:
            return flickrPhotos.count
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrViewCell", for: indexPath) as! FlickrViewCell
        
        switch indexPath.section {
        case 0:
            let photoObject = fetchedResultsController.object(at: indexPath)
            DispatchQueue.main.async {
                let image = UIImage(data: photoObject.imageData! as Data)
                cell.photoImage.image = image
            }
        default:
            let shuffledFlickrPhotos = flickrPhotos.shuffled()
            if let url = URL(string: shuffledFlickrPhotos[indexPath.row].imageURLString()) {
                cell.setupCell(url: url)
            }
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



