//
//  MapViewModel.swift
//  MaSuperCarte
//
//  Created by Guillaume Bellut on 01/05/2017.
//  Copyright © 2017 Guillaume Bellut. All rights reserved.
//

import UIKit
import CoreLocation

enum MapSDK {
	case mapbox
	// Add one more case by supported SDK
}

protocol MapViewModelDelegate {
	var mapView: UIView { get set }
	
	func centerMap(on coordinate: CLLocationCoordinate2D)
	func addresses(from query: String, completionHandler: @escaping (_ placemarks: [String]?) -> Void)
	func goTo(address: String)
	func address(from coordinate: CLLocationCoordinate2D, completionHandler: @escaping (_ address: String) -> Void)
}

class MapViewModel: NSObject, CLLocationManagerDelegate {
	
	// MARK: Static properties
	
	static let DefaultDistanceGapToBeRelevant: CLLocationDistance = 15.0
	
	static let MinimumZoomLevel: Double = 1.0
	
	static let DefaultCameraDistance: CLLocationDistance = 1750.0
	static let DefaultCameraPitch: CGFloat = 0.0
	static let DefaultCameraHeading: CLLocationDirection = 0.0
	static let DefaultCameraAnimationDuration: CLLocationDirection = 2.0
	
	static let MaxAutoCompletePlacemarks: Int = 3
	static let DefaultAutoCompleteAddressTableViewRowHeight: CGFloat = 44.0
	
	static let EncodedAddressesKey: String = "encodedAddressesKey"
	static let MaxEncodedAddressesCount: Int = 15
	
	
	// MARK: Basic properties
	
	var locationManager: CLLocationManager = CLLocationManager()
	var currentPin: MGLPointAnnotation?
	
	let geocoder = Geocoder.shared
	
	var mapIsBeingDragged = false

	let currentSDK: MapSDK = .mapbox
	var delegate: MapViewModelDelegate?
	
	
	// MARK: Observing properties
	
	var currentUserLocation: CLLocation? {
		didSet {
			guard let currentUserLocation = currentUserLocation else {
				return
			}
			
			print("Stopped to update location")
			locationManager.stopUpdatingLocation()
			
			centerMap(on: currentUserLocation)
		}
	}
	
	var autoCompletePlacemarks: [GeocodedPlacemark] = [] {
		didSet {
			if autoCompletePlacemarks.count > 0 {
				autoCompletePlacemarkTableView.reloadData()
				autoCompletePlacemarkTableViewHeightConstraint.constant = CGFloat(autoCompletePlacemarks.count) * autoCompletePlacemarkTableView.estimatedRowHeight
				autoCompletePlacemarkTableView.isHidden = false
				
				autoCompletePlacemarkTableView.layoutIfNeeded()
			} else {
				autoCompletePlacemarkTableView.isHidden = true
			}
		}
	}
	

	// MARK: Class functions
	
	func setupView() -> UIView {
		switch currentSDK {
		case .mapbox:
			delegate = MapboxParser(delegate: self)
		}
		
		locationManager.delegate = self
		
		locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
		locationManager.requestWhenInUseAuthorization()
		
		return delegate!.mapView
	}
	
	func map() -> UIView {
		return delegate.map()
	}
	
	func mapIsMoving(_ mapView: UIView, newCenterCoordinate: CLLocationCoordinate2D) {
		
	}
	
	func mapDidMove(_ mapView: UIView, newCenterCoordinate: CLLocationCoordinate2D) {
		
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
	
	func save(name: String, coordinate: CLLocationCoordinate2D) {
		let applicationDelegate = UIApplication.shared.delegate as! AppDelegate
		var lastAddressesBuffer = applicationDelegate.lastAddresses
		
		for address in lastAddressesBuffer {
			if name == address.name {
				lastAddressesBuffer.remove(at: lastAddressesBuffer.index(of: address)!)
				break
			}
		}
		
		lastAddressesBuffer.insert(AddressObject(name: name, coordinate: coordinate), at: 0)
		
		if lastAddressesBuffer.count > MapViewController.MaxEncodedAddressesCount {
			lastAddressesBuffer.remove(at: MapViewController.MaxEncodedAddressesCount)
		}
		
		applicationDelegate.lastAddresses = lastAddressesBuffer
		
		print("Cached address list now contains \(lastAddressesBuffer.count) addresses")
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
