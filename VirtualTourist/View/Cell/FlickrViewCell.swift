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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func setImageFrom(url: URL, placeholderImage: UIImage? = nil, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        
        if let placeholderImage = placeholderImage {
            photoImage.image = placeholderImage
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, error)
                return }
            
            let image = UIImage(data: data)
            completionHandler(image, nil)
        }
        task.resume()
    }
    
    func handleImageResponse(imageData: FlickrPhoto?, error: Error?) {
        guard let imageMessage = URL(string: (imageData?.imageURLString())!) else {
                   print("cannot print URL")
                   return
               }
        setImageFrom(url: imageMessage, placeholderImage: #imageLiteral(resourceName: "film-reel"), completionHandler: handleImageFileResponse(image:error:))
    }
    
   func handleImageFileResponse(image: UIImage?, error: Error?) {
    
    if let error = error {
        print(error)
    }
       DispatchQueue.main.async {
        self.photoImage.image = image
       }
   }
    
}
