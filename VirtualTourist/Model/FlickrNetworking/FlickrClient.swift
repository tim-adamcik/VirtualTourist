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
           
    
    func getFlickrPhotoURLs(lat: Double, lon: Double, page: Int, completion: @escaping ([FlickrPhoto]?, Error?) -> Void) {
        guard var components = URLComponents(string: flickrBase) else {
            completion(nil, NetworkingError.invalidURLComponents)
            return }
        let queryItem1 = URLQueryItem(name: "api_key", value: apiKey)
        let queryItem2 = URLQueryItem(name: "method", value: flickrSearch)
        let queryItem3 = URLQueryItem(name: "format", value: "json")
        let queryItem4 = URLQueryItem(name: "lat", value: String(lat))
        let queryItem5 = URLQueryItem(name: "lon", value: String(lon))
        let queryItem6 = URLQueryItem(name: "radius", value: "10")
        let queryItem7 = URLQueryItem(name: "nojsoncallback", value: "1")
        let queryItem8 = URLQueryItem(name: "page", value: String(page))
        components.queryItems = [queryItem1, queryItem2, queryItem3, queryItem4, queryItem5, queryItem6, queryItem7, queryItem8]
        
        guard let url = components.url else {
            completion(nil, NetworkingError.invalidURL)
            return }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            if let error = error {
                completion(nil, error)
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 else {
                completion(nil, NetworkingError.httpError)
                return }
            
            guard let data = data else {
                completion(nil, NetworkingError.nilData)
                return }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(JsonFlickrApi.self, from: data)
                print(responseObject)
                
                
                let photos = Array(responseObject.photos.photo.prefix(100))
                completion(photos, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    
    
}
