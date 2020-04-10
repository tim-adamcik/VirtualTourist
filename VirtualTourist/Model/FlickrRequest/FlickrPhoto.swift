//
//  FlickrPhoto.swift
//  VirtualTourist
//
//  Created by Timothy Adamcik on 3/19/20.
//  Copyright © 2020 Timothy Adamcik. All rights reserved.
//

import Foundation


struct JsonFlickrApi: Codable {
    let photos: FlickrPhotoResponse
}

struct FlickrPhotoResponse: Codable {
    let page: Int
    let pages: Int
    let photo: [FlickrPhoto]
}

struct FlickrPhoto: Codable {
    let id: String
    let secret: String
    let server: String
    let farm: Int
 
    func imageURLString() -> String {
        
        return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_q.jpg"
    }
    
}
