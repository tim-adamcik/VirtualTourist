//
//  NetworkingError.swift
//  VirtualTourist
//
//  Created by Timothy Adamcik on 3/20/20.
//  Copyright © 2020 Timothy Adamcik. All rights reserved.
//

import Foundation

enum NetworkingError: Error {
    case invalidURLComponents
    case invalidURL
    case nilData
    case httpError
}
