//
//  LocationPickerViewController.swift
//  Messenger
//
//  Created by LoganMacMini on 2024/2/2.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> Void)?
    
    private var coordinates: CLLocationCoordinate2D?
    
    public var isPickable : Bool = true

    private let mapView: MKMapView = {
        let map = MKMapView()
        map.isUserInteractionEnabled = true
        map.showsCompass = true
        return map
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        self.coordinates = coordinates
//        self.isPickable = false
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send",
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(sendButtonTapped))
            
            let gesture = UITapGestureRecognizer(target: self,
                                                 action: #selector(didTapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            mapView.addGestureRecognizer(gesture)
        }
        else {
            // just showing location
            guard let coordinates = self.coordinates else { return }
            // drop a pin on that location
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            //add the pin on map
            mapView.addAnnotation(pin)
            
            //set the level of scale(設定地圖縮放程度)
            let region = MKCoordinateRegion(center: coordinates,
                                            latitudinalMeters: 250,
                                            longitudinalMeters: 250)
            mapView.setRegion(region, animated: true)
        }
        
        view.addSubview(mapView)
    }
    
    @objc private func sendButtonTapped() {
        guard let coordinates = coordinates else { return }
        navigationController?.popViewController(animated: true)
        completion?(coordinates)
    }
    
    @objc private func didTapMap(_ gesture: UITapGestureRecognizer) {
        let locationInView = gesture.location(in: mapView)
        let coordinates = mapView.convert(locationInView, toCoordinateFrom: mapView)
        self.coordinates = coordinates
        
        //get rid of prior pin on map
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
        
        // drop a pin on that location
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        
        //add the last pin on map
        mapView.addAnnotation(pin)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        mapView.frame = view.bounds
    }
}
