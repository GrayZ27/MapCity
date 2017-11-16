//
//  MapVC.swift
//  MapCity
//
//  Created by Gray Zhen on 11/16/17.
//  Copyright © 2017 GrayStudio. All rights reserved.
//

import UIKit
import MapKit

class MapVC: UIViewController {

    //IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
    }
    
    //IBActions
    @IBAction func centerMapBtnPresssed(_ sender: Any) {
        
        
        
    }

}

extension MapVC: MKMapViewDelegate {
    
}
