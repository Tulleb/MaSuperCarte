//
//  MapboxParser.swift
//  MaSuperCarte
//
//  Created by Guillaume Bellut on 01/05/2017.
//  Copyright © 2017 Guillaume Bellut. All rights reserved.
//

import Foundation
import Mapbox
import MapboxGeocoder

class MapboxParser: NSObject, MGLMapViewDelegate, MapViewModelDelegate {
	
	var delegate: MapViewModel
	var mapView: MGLMapView
	
	init(delegate: MapViewModel) {
		self.delegate = delegate
		self.mapView = MGLMapView()
		self.mapView.delegate = self
	}
	
	
	// MARK: MapViewModelDelegate
	
	func centerMap(on coordinate: CLLocationCoordinate2D)
		// Using a minimum zoom level to avoid centering issue
		mapView.setCenter(location.coordinate, zoomLevel: max(mapView.zoomLevel, MapViewController.MinimumZoomLevel), animated: false)
		
		// Add camera animation
		let camera = MGLMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: MapViewController.DefaultCameraDistance, pitch: MapViewController.DefaultCameraPitch, heading: MapViewController.DefaultCameraHeading)
		mapView.setCamera(camera, withDuration: MapViewController.DefaultCameraAnimationDuration, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
		
		if currentPin == nil {
			currentPin = MGLPointAnnotation()
			mapView.addAnnotation(currentPin!)
		}
		
		currentPin!.coordinate = location.coordinate
	}
	
	func placemarks(from query: String, completionHandler: @escaping (_ placemarks: [GeocodedPlacemark]?) -> Void) {
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
	
	func confirmAddress(for placemark: GeocodedPlacemark) {
		addressTextField.resignFirstResponder()
		
		let name = address(from: placemark)
		addressTextField.text = name
		
		save(name: name, coordinate: placemark.location.coordinate)
		
		autoCompletePlacemarks = []
		
		centerMap(on: placemark.location)
		print("Centered map on confirmed address")
	}
	
	func address(from coordinate: CLLocationCoordinate2D, completionHandler: @escaping (_ address: String?) -> Void) {
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
