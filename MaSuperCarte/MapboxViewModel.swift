//
//  MapViewModel.swift
//  MaSuperCarte
//
//  Created by Guillaume Bellut on 01/05/2017.
//  Copyright © 2017 Guillaume Bellut. All rights reserved.
//

import UIKit
import CoreLocation
import Mapbox
import MapboxGeocoder
import RxSwift

protocol MapViewModelDelegate {
	var mapView: UIView { get set }
	
	func centerMap(on coordinate: CLLocationCoordinate2D)
	func addresses(from query: String, completionHandler: @escaping (_ placemarks: [String]?) -> Void)
	func goTo(address: String)
	func address(from coordinate: CLLocationCoordinate2D, completionHandler: @escaping (_ address: String) -> Void)
}

class MapboxViewModel: NSObject, CLLocationManagerDelegate, MapViewModelDelegate {
	
	// MARK: Basic properties
	
	var mapCenterLatitude: BehaviorSubject<CGFloat>
	var mapCenterLongitude: BehaviorSubject<CGFloat>
	
	var addressText: BehaviorSubject<String>
	
	let geocoder = Geocoder.shared
	var currentPin: MGLPointAnnotation?
	var mapIsBeingDragged = false
	
	var locationManager: CLLocationManager = CLLocationManager()
	
	
	// MARK: Observing properties
	
	var currentUserLocation: CLLocation? {
		didSet {
			guard let currentUserLocation = currentUserLocation else {
				return
			}
			
			print("Stopped to update location")
			locationManager.stopUpdatingLocation()
			
			delegate?.centerMap(on: currentUserLocation.coordinate)
		}
	}
	
	

	// MARK: Class functions
	
	func setupView() -> UIView {
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
		
		lastAddressesBuffer.insert(AddressModel(name: name, coordinate: coordinate), at: 0)
		
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
	
	// MARK: MapViewModelDelegate
	
	func centerMap(on coordinate: CLLocationCoordinate2D) {
		// Using a minimum zoom level to avoid centering issue
		mapView.setCenter(coordinate, zoomLevel: max(mapView.zoomLevel, MapViewController.MinimumZoomLevel), animated: false)
		
		// Add camera animation
		let camera = MGLMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: MapViewController.DefaultCameraDistance, pitch: MapViewController.DefaultCameraPitch, heading: MapViewController.DefaultCameraHeading)
		mapView.setCamera(camera, withDuration: MapViewController.DefaultCameraAnimationDuration, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
		
		if currentPin == nil {
			currentPin = MGLPointAnnotation()
			mapView.addAnnotation(currentPin!)
		}
		
		currentPin!.coordinate = coordinate
	}
	
	func addresses(from query: String, completionHandler: @escaping (_ placemarks: [String]?) -> Void) {
		//	func placemarks(from query: String, completionHandler: @escaping (_ placemarks: [GeocodedPlacemark]?) -> Void) {
		let options = ForwardGeocodeOptions(query: query)
		
		options.focalLocation = currentUserLocation
		options.allowedScopes = [.address, .pointOfInterest]	// Added Point of Interest in the scope to improve user experience
		
		_ = geocoder.geocode(options) { (placemarks, attribution, error) in
			guard let placemarks = placemarks, placemarks.count > 0 else {
				completionHandler(nil)
				return
			}
			
			print("Found \(placemarks.count) placemark(s)")
			var returnedPlacemarks: [GeocodedPlacemark] = []
			
			// Giving a maximum number of auto-completed address for a better interface
			if placemarks.count > MapViewController.MaxAutoCompletePlacemarks {
				returnedPlacemarks = Array(placemarks.prefix(upTo: MapViewController.MaxAutoCompletePlacemarks))
			} else {
				returnedPlacemarks = placemarks
			}
			
			completionHandler(returnedPlacemarks)
		}
	}
	
	func goTo(address: String) {
		//	func confirmAddress(for placemark: GeocodedPlacemark) {
		addressTextField.resignFirstResponder()
		
		let name = address(from: placemark)
		addressTextField.text = name
		
		save(name: name, coordinate: placemark.location.coordinate)
		
		autoCompletePlacemarks = []
		
		centerMap(on: placemark.location)
		print("Centered map on confirmed address")
	}
	
	func address(from coordinate: CLLocationCoordinate2D, completionHandler: @escaping (_ address: String) -> Void) {
		//	func address(from coordinate: CLLocationCoordinate2D, completionHandler: @escaping (_ address: String?) -> Void) {
		let options = ReverseGeocodeOptions(coordinate: coordinate)
		
		_ = geocoder.geocode(options) { (placemarks, attribution, error) in
			guard let placemark = placemarks?.first else {
				completionHandler(nil)
				return
			}
			
			completionHandler(self.address(from: placemark))
		}
	}
	
	func address(from placemark: GeocodedPlacemark) -> String {
		guard let postalAddress = placemark.postalAddress, postalAddress.street != "", postalAddress.postalCode != "", postalAddress.city != "" else {
			return placemark.qualifiedName
		}
		
		return "\(postalAddress.street), \(postalAddress.postalCode) \(postalAddress.city)"
	}
	
	
	// MARK: MGLMapViewDelegate
	
	func mapViewRegionIsChanging(_ mapView: MGLMapView) {
		addressTextField.resignFirstResponder()
		addressTextField.placeholder = "Déplacement en cours..."
		addressTextField.text = ""
		mapIsBeingDragged = true
		autoCompletePlacemarks = []
		
		if currentPin == nil {
			currentPin = MGLPointAnnotation()
			mapView.addAnnotation(currentPin!)
		}
		
		currentPin!.coordinate = mapView.centerCoordinate
	}
	
	func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
		if mapIsBeingDragged {
			let centerCoordinate = mapView.centerCoordinate
			address(from: centerCoordinate) { (address: String?) in
				if let address = address {
					self.addressTextField.text = address
					
					self.save(name: address, coordinate: centerCoordinate)
				} else {
					self.addressTextField.text = ""
				}
				
				self.addressTextField.placeholder = "Entrer une adresse..."
			}
			
			mapIsBeingDragged = false
		}
	}
	
}
