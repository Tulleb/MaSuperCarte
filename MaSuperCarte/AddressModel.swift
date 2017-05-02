//
//  AddressModel.swift
//  MaSuperCarte
//
//  Created by Guillaume Bellut on 30/04/2017.
//  Copyright © 2017 Guillaume Bellut. All rights reserved.
//

import Foundation
import CoreLocation

class AddressModel: NSObject, NSCoding {
	
	let name: String
	let latitude: Double
	let longitude: Double
	let qualification: String? = nil // Placemark.qualifiedName for Mapbox
	let street: String? = nil
	let postalCode: String? = nil
	let city: String? = nil
	
	var coordinate: CLLocationCoordinate2D {
		get {
			return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
		}
	}
	
	
	init(name: String, coordinate: CLLocationCoordinate2D) {
		self.name = name
		self.latitude = coordinate.latitude
		self.longitude = coordinate.longitude
	}
	
	
	override var description: String {
		if let street = self.street, let postalCode = self.postalCode, let city = self.city {
			return "\(street), \(postalCode) \(city)"
		} else if let qualification = self.qualification {
			return qualification
		} else {
			return "No address found"
		}
	}
	
	
	// MARK: NSCoding
	
	required init(coder aDecoder: NSCoder) {
		self.name = aDecoder.decodeObject(forKey: "name") as! String
		self.latitude = aDecoder.decodeDouble(forKey: "latitude")
		self.longitude = aDecoder.decodeDouble(forKey: "longitude")
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(name, forKey: "name")
		aCoder.encode(latitude, forKey: "latitude")
		aCoder.encode(longitude, forKey: "longitude")
	}
	
}

class AddressManager: NSObject {	// Singleton
	
	static let sharedInstance = AddressManager()
	
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
	
	
	var selectedAddressFromMenu: AddressModel? = nil
	
	var lastAddresses: [AddressModel] {
		get {
			if let encodedReturnValue = UserDefaults.standard.object(forKey: AddressManager.EncodedAddressesKey) as? Data {
				if let returnValue = NSKeyedUnarchiver.unarchiveObject(with: encodedReturnValue) as? [AddressModel] {
					return returnValue
				}
			}
			
			return []
		}
		
		set {
			print("Encoding addresses...")
			
			let encodedObject = NSKeyedArchiver.archivedData(withRootObject: newValue)
			UserDefaults.standard.set(encodedObject, forKey: AddressManager.EncodedAddressesKey)
			UserDefaults.standard.synchronize()
			
			print("Addresses encoded")
		}
	}
	
	private override init() {
		print("Shared Network Manager instance created")
	}
	
}
