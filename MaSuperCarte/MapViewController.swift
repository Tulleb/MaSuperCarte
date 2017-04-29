//
//  MapViewController.swift
//  MaSuperCarte
//
//  Created by Guillaume Bellut on 29/04/2017.
//  Copyright © 2017 Guillaume Bellut. All rights reserved.
//

import UIKit
import Mapbox

class MapViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
	
	static let DefaultDistanceGapToBeRelevant: CLLocationDistance = 15.0
	
	static let DefaultZoomLevel: Double = 1.0
	
	static let DefaultCameraDistance: CLLocationDistance = 1750.0
	static let DefaultCameraPitch: CGFloat = 0.0
	static let DefaultCameraHeading: CLLocationDirection = 0.0
	static let DefaultCameraAnimationDuration: CLLocationDirection = 5.0
	
	@IBOutlet weak var mapView: MGLMapView!
	
	var locationManager: CLLocationManager = CLLocationManager()
	var currentPin: MGLPointAnnotation?
	
	var currentUserLocation: CLLocation? {
		didSet {
			guard let currentUserLocation = currentUserLocation else {
				return
			}
			
			print("Stopped to update location")
			locationManager.stopUpdatingLocation()
			
			centerMap(on: currentUserLocation)
			
			if currentPin == nil {
				currentPin = MGLPointAnnotation()
				mapView.addAnnotation(currentPin!)
			}
			
			currentPin!.coordinate = currentUserLocation.coordinate
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		locationManager.delegate = self
		
		locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
		locationManager.requestWhenInUseAuthorization()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		if currentUserLocation == nil {
			print("Started to update location")
			locationManager.startUpdatingLocation()
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func centerMap(on location: CLLocation) {
		mapView.setCenter(location.coordinate, zoomLevel: MapViewController.DefaultZoomLevel, animated: false)
		
		// Add camera animation
		let camera = MGLMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: MapViewController.DefaultCameraDistance, pitch: MapViewController.DefaultCameraPitch, heading: MapViewController.DefaultCameraHeading)
		mapView.setCamera(camera, withDuration: MapViewController.DefaultCameraAnimationDuration, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
	}
	
	// Test to check if location sent is relevant compared to the current one
	func locationIsRelevant(_ location: CLLocation) -> Bool {
		if let currentUserLocation = currentUserLocation {
			if location.distance(from: currentUserLocation) < MapViewController.DefaultDistanceGapToBeRelevant {
				
				return false
			}
		}
		
		return true
	}

	
	// MARK: CLLocationManagerDelegate
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		switch status {
			
		case .denied:
			let alertController = UIAlertController (title: "Partager votre position", message: "Vous n'avez pas accepté de partager votre position actuelle.\n\nSouhaitez-vous accéder aux réglages afin de la partager ?", preferredStyle: .alert)
			
			let settingsAction = UIAlertAction(title: "Réglages", style: .cancel) { (_) -> Void in
				guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
					return
				}
				
				if UIApplication.shared.canOpenURL(settingsUrl) {
					UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
						print("Settings opened: \(success)") // Prints true
					})
				}
			}
			
			let cancelAction = UIAlertAction(title: "Refuser", style: .default, handler: nil)
			
			alertController.addAction(settingsAction)
			alertController.addAction(cancelAction)
			
			present(alertController, animated: true, completion: nil)
			
		default:
			return
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let newLocation = locations.last else {
			return
		}
		
		print("New locations received: \(locations)")
		
		if locationIsRelevant(newLocation) {
			currentUserLocation = newLocation
			print("Saved new location: \(currentUserLocation!)")
		} else {
			print("Location is too close from the previous one. Aborted.")
		}
	}
	
}

