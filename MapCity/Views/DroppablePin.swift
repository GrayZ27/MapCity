//
//  DroppablePin.swift
//  MapCity
//
//  Created by Gray Zhen on 11/19/17.
//  Copyright © 2017 GrayStudio. All rights reserved.
//

import UIKit
import MapKit

class DroppablePin: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var identifier: String
    
    init(coordinate: CLLocationCoordinate2D, identifier: String) {
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
}
