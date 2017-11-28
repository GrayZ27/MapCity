//
//  MapVC.swift
//  MapCity
//
//  Created by Gray Zhen on 11/16/17.
//  Copyright © 2017 GrayStudio. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate {

    //IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var pullUpVIewHeightConstraints: NSLayoutConstraint!
    
    //variables
    var locationManager = CLLocationManager()
    
    //optional variables
    var spinner: UIActivityIndicatorView?
    var progressLbl: UILabel?
    var collectionView: UICollectionView?
    //needed when using collectionView programmatically
    var flowLayout = UICollectionViewFlowLayout()
    var imageUrlsArray = [String]()
    var imageArray = [UIImage]()
    
    //constants
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    let screenSize = UIScreen.main.bounds
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        configureLocationService()
        addDoubleTap()
        
        //set up collectionView
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: PHOTO_CELL)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 0.5)
        
        //needed for add 3D Touch
        registerForPreviewing(with: self, sourceView: collectionView!)
        
        pullUpView.addSubview(collectionView!)
        
    }
    
    //added function when user double tap
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    //added action when user swipe down on screen
    func addSwipeDown() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipeDown.direction = .down
        pullUpView.addGestureRecognizer(swipeDown)
    }
    
    //added spinner programmatically
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: screenSize.width / 2 - (spinner?.frame.width)! / 2, y: 150)
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    //added label programmatically
    func addProgressLbl() {
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: 0, y: 175, width: pullUpView.frame.width, height: 40)
        progressLbl?.font = UIFont(name: "Optima Bold", size: 16)
        progressLbl?.textColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
        progressLbl?.textAlignment = .center
        progressLbl?.text = "Downloading pictures"
        collectionView?.addSubview(progressLbl!)
    }
    
    //remove exist spinner
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func removeProgressLbl() {
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
    }
    
    //pull up a hidden view
    func animateViewUp() {
        pullUpVIewHeightConstraints.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    //swipe down the hidden view
    @objc func animateViewDown() {
        cancelAllSession()
        pullUpVIewHeightConstraints.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    //IBActions
    @IBAction func centerMapBtnPresssed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapUserLocation()
        }
    }

}

extension MapVC: MKMapViewDelegate {
    
    //change pin color
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: DROPPABLE_PIN)
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9619460702, green: 0.6525279284, blue: 0.136488229, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    //center the user location on map and zoom in
    func centerMapUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    //drop a pin on the map
    @objc func dropPin(sender: UITapGestureRecognizer){
        removePin()
        removeSpinner()
        removeProgressLbl()
        cancelAllSession()
        
        imageUrlsArray = []
        imageArray = []
        collectionView?.reloadData()
        
        animateViewUp()
        addSwipeDown()
        addSpinner()
        addProgressLbl()
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: DROPPABLE_PIN)
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius * 2, regionRadius * 2)
        mapView.setRegion(coordinateRegion, animated: true)
        
        //getting image from flickr
        retrieveUrls(forAnnotation: annotation) { (done) in
            if done {
                self.retrieveImage(hander: { (done) in
                    if done {
                        self.removeSpinner()
                        self.removeProgressLbl()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
        
    }
    
    //remove exist pin
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func retrieveUrls(forAnnotation annotation: DroppablePin, handler: @escaping (_ status: Bool) -> ()){

        Alamofire.request(flickrURL(forApiKey: apiKey, withAnnotation: annotation, andNumberOfPhotos: 30)).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
            let photoDict = json["photos"] as! Dictionary<String, AnyObject>
            let photoDictArray = photoDict["photo"] as! [Dictionary<String, AnyObject>]
            for photo in photoDictArray {
                let farmNum = photo["farm"]!
                let serverNum = photo["server"]!
                let id = photo["id"]!
                let secret = photo["secret"]!
                let photoURL = "https://farm\(farmNum).staticflickr.com/\(serverNum)/\(id)_\(secret)_h_d.jpg"
                self.imageUrlsArray.append(photoURL)
            }
            handler(true)
        }
    }
    
    func retrieveImage(hander: @escaping (_ status: Bool) -> ()){
        
        for url in imageUrlsArray{
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                
                guard let image = response.result.value else { return }
                self.imageArray.append(image)
                self.progressLbl?.text = "\(self.imageArray.count)/30 Images Downloaded"
                
                if self.imageArray.count == self.imageUrlsArray.count {
                    hander(true)
                }
            })
        }
        
    }
    
    func cancelAllSession() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, sessionUploadTask, sessionDownloadTask) in
            sessionDataTask.forEach({ $0.cancel() })
            sessionDownloadTask.forEach({ $0.cancel() })
        }
    }
    
}

extension MapVC: CLLocationManagerDelegate {
    
    //check authorization to get user location
    func configureLocationService() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapUserLocation()
    }
    
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    //functions must needed for collection view--------------------------------------------------------
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return imageArray.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PHOTO_CELL, for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return }
        popVC.initData(forImage: imageArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
        
    }
    //functions must needed for collection view--------------------------------------------------------
    
}

//added 3D touch
extension MapVC: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else { return nil }
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return nil }
        
        popVC.initData(forImage: imageArray[indexPath.row])
        previewingContext.sourceRect = cell.contentView.frame
        
        return popVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        show(viewControllerToCommit, sender: self)
        
    }
    
}