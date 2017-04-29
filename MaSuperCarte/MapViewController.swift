//
//  MapViewController.swift
//  MaSuperCarte
//
//  Created by Guillaume Bellut on 29/04/2017.
//  Copyright © 2017 Guillaume Bellut. All rights reserved.
//

import UIKit
import Mapbox
import MapboxGeocoder

class MapViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
	
	// MARK: Static properties
	
	static let DefaultDistanceGapToBeRelevant: CLLocationDistance = 15.0
	
	static let MinimumZoomLevel: Double = 1.0
	
	static let DefaultCameraDistance: CLLocationDistance = 1750.0
	static let DefaultCameraPitch: CGFloat = 0.0
	static let DefaultCameraHeading: CLLocationDirection = 0.0
	static let DefaultCameraAnimationDuration: CLLocationDirection = 2.0
	
	static let MaxAutoCompletePlacemarks: Int = 3
	static let DefaultAutoCompleteAddressTableViewRowHeight: CGFloat = 44.0
	
	
	// MARK: Storyboard properties
	
	@IBOutlet weak var mapView: MGLMapView!
	@IBOutlet weak var addressTextField: UITextField!
	@IBOutlet weak var autoCompletePlacemarkTableView: UITableView!
	@IBOutlet weak var autoCompletePlacemarkTableViewHeightConstraint: NSLayoutConstraint!
	
	
	// MARK: Basic properties
	
	var locationManager: CLLocationManager = CLLocationManager()
	var currentPin: MGLPointAnnotation?
	
	let geocoder = Geocoder.shared
	
	
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
	
	
	// MARK: Overriding Functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		locationManager.delegate = self
		
		locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
		locationManager.requestWhenInUseAuthorization()
		
		autoCompletePlacemarkTableView.rowHeight = UITableViewAutomaticDimension;
		autoCompletePlacemarkTableView.estimatedRowHeight = MapViewController.DefaultAutoCompleteAddressTableViewRowHeight
		
		addressTextField.addTarget(self, action: #selector(textFieldDidChange), for: UIControlEvents.editingChanged)
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
	
	
	// MARK: Class Functions
	
	func centerMap(on location: CLLocation) {
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
	
	// Test to check if location sent is relevant compared to the current one
	func locationIsRelevant(_ location: CLLocation) -> Bool {
		if let currentUserLocation = currentUserLocation {
			if location.distance(from: currentUserLocation) < MapViewController.DefaultDistanceGapToBeRelevant {
				
				return false
			}
		}
		
		return true
	}
	
	func textFieldDidChange(_ sender: UITextField) {
		if sender == addressTextField {
			guard let text = addressTextField.text, text != "" else {
				self.autoCompletePlacemarks = []
				return
			}
			
			checkAddress(for: text)
		}
	}
	
	func checkAddress(for query: String) {
		let options = ForwardGeocodeOptions(query: query)
		
		options.focalLocation = currentUserLocation
		options.allowedScopes = [.address, .pointOfInterest]	// Added Point of Interest in the scope to improve user experience
		
		_ = geocoder.geocode(options) { (placemarks, attribution, error) in
			guard let placemarks = placemarks else {
				return
			}
			
			print("Found \(placemarks.count) placemark(s)")
			
			// Giving a maximum number of auto-completed address for a better interface
			if placemarks.count > MapViewController.MaxAutoCompletePlacemarks {
				self.autoCompletePlacemarks = Array(placemarks.prefix(upTo: MapViewController.MaxAutoCompletePlacemarks))
			} else {
				self.autoCompletePlacemarks = placemarks
			}
		}
	}
	
	func confirmAddress(for placemark: GeocodedPlacemark) {
		addressTextField.resignFirstResponder()
		addressTextField.text = placemark.qualifiedName
		autoCompletePlacemarks = []
		
		centerMap(on: placemark.location)
		print("Centered map on confirmed address")
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
	
	
	// MARK: UITextFieldDelegate
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		guard let text = textField.text, text != "", autoCompletePlacemarks.indices.contains(0) else {
			return true
		}
		
		confirmAddress(for: autoCompletePlacemarks[0])
		
		return true
	}
	
	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		guard let text = addressTextField.text, text != "" else {
			self.autoCompletePlacemarks = []
			
			return true
		}
		
		checkAddress(for: text)
		
		return true
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		textField.text = ""
		textField.resignFirstResponder()
		
		if let currentUserLocation = currentUserLocation {
			centerMap(on: currentUserLocation)
			print("Address bar cleared, map reset to user's current location")
		}
		
		return false
	}
	
	
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return autoCompletePlacemarks.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "AutoCompletePlacemarkCell") as? AutoCompletePlacemarkCell else {
			return UITableViewCell()
		}
		
		let placemark = autoCompletePlacemarks[indexPath.row]
		cell.qualifiedNameLabel.text = placemark.qualifiedName
		
		return cell
	}
	
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		confirmAddress(for: autoCompletePlacemarks[indexPath.row])
	}
	
}

