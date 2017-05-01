//
//  AddressObject.swift
//  MaSuperCarte
//
//  Created by Guillaume Bellut on 30/04/2017.
//  Copyright © 2017 Guillaume Bellut. All rights reserved.
//

import Foundation
import CoreLocation

class AddressObject: NSObject, NSCoding {
	
	let name: String
	let latitude: Double
	let longitude: Double
	
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
