//
//  Constants.swift
//  MapCity
//
//  Created by Gray Zhen on 11/24/17.
//  Copyright © 2017 GrayStudio. All rights reserved.
//

import Foundation

let PHOTO_CELL = "photoCell"

let DROPPABLE_PIN = "droppablePin"

let apiKey = "580de5e11f3dc033223552098a6f62d3"

func flickrURL(forApiKey key: String, withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int) -> String {
    
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(key)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"

}
