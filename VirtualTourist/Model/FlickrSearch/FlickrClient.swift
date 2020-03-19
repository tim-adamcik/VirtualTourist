//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Timothy Adamcik on 3/11/20.
//  Copyright © 2020 Timothy Adamcik. All rights reserved.
//

import Foundation

class FlickrClient {
    
    static let shared = FlickrClient()
    
    let apiKey = "6e3b5ba678c25366ec2cc02d25f9c363"
    let secret = "9a4a284f7e0d21f7"
    
    var flickrBase = "https://api.flickr.com/services/rest/"
    var flickrSearch = "flickr.photos.search"
    var parameters = "?"
           

      
    
    func getFlickrPhotos(lat: Double, lon: Double, completion: @escaping ([FlickrPhoto]?, Error?) -> Void) {
        var components = URLComponents(string: flickrBase)
        let queryItem1 = URLQueryItem(name: "api_key", value: apiKey)
        let queryItem2 = URLQueryItem(name: "method", value: flickrSearch)
        let queryItem3 = URLQueryItem(name: "lat", value: String(lat))
        let queryItem4 = URLQueryItem(name: "lon", value: String(lon))
        let queryItem5 = URLQueryItem(name: "radius", value: "10")
        components?.queryItems = [queryItem1, queryItem2, queryItem3, queryItem4, queryItem5]
        let urlRequest = URLRequest(url: components!.url!)
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            
            if let error = error {
                completion(nil, error)
            }
            guard let data = data else {
                completion([], error)
                return }
            print(data)
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(FlickrPhoto.self, from: data)
                print(responseObject)
//                completion(responseObject, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
    
}
