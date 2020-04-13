//
//  FlickrViewCell.swift
//  VirtualTourist
//
//  Created by Timothy Adamcik on 3/11/20.
//  Copyright © 2020 Timothy Adamcik. All rights reserved.
//

import UIKit

class FlickrViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImage: UIImageView!
    
    func initWithPhoto(_ photo: Photo) {
        
        if photo.imageData != nil {
            
            DispatchQueue.main.async {
                
                self.photoImage.image = UIImage(data: photo.imageData! as Data)
            }
            
        } else {
            
            downloadImage(photo)
        }
    }
    
    //Download Images
    
    func downloadImage(_ photo: Photo) {
        
        URLSession.shared.dataTask(with: URL(string: photo.imageURL!)!) { (data, response, error) in
            
            if error == nil {
                DispatchQueue.main.async {
                    self.photoImage.image = UIImage(data: data! as Data)
                    self.saveImageDataToCoreData(photo, imageData: data! as Data)
                }
            }
        }
        .resume()
    }
    
    func saveImageDataToCoreData(_ photo: Photo, imageData: Data) {
        
        do {
            photo.imageData = imageData
            try DataController.shared.viewContext.save()
        } catch {
            print("saving photo image failed")
        }
    }
//
//    func setupCell(url: URL) {
//        let task = URLSession.shared.dataTask(with: url) { (data, _, _) in
//            DispatchQueue.main.async {
//                if let data = data, let image = UIImage(data: data) {
//                    self.photoImage.image = image
//                }
//            }
//        }
//        task.resume()
//    }
//

//    
}
