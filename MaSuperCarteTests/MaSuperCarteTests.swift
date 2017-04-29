//
//  MaSuperCarteTests.swift
//  MaSuperCarteTests
//
//  Created by Guillaume Bellut on 29/04/2017.
//  Copyright © 2017 Guillaume Bellut. All rights reserved.
//

import XCTest
import UIKit
import Mapbox
import MapboxGeocoder

@testable import MaSuperCarte

class MaSuperCarteTests: XCTestCase {
	
	static let MaxAllowedDistance: CLLocationDistance = 15.0
	
	var mapViewController: MapViewController?
	
	override func setUp() {
		super.setUp()
		
		let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
		if let viewController = storyboard.instantiateInitialViewController() as? MapViewController {
			mapViewController = viewController
		}
		
		XCTAssertNotNil(mapViewController!.view)
    }
	
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func testCenterMap() {
		let location = CLLocation(latitude: 48.98925323, longitude: 2.22508226)
		
		mapViewController!.centerMap(on: location)
		
		let mapLocation = CLLocation(latitude: mapViewController!.mapView.centerCoordinate.latitude, longitude: mapViewController!.mapView.centerCoordinate.longitude)
		
		let distanceFromCenter = location.distance(from: mapLocation)
		
		XCTAssertLessThan(distanceFromCenter, MaSuperCarteTests.MaxAllowedDistance)
	}
	
	func testLocationIsRelevant() {
		mapViewController!.currentUserLocation = CLLocation(latitude: 48.98925323, longitude: 2.22508226)
		let newNearLocation = CLLocation(latitude: 48.98925320, longitude: 2.22508220)	// Should be irrelevant because too close from the current one
		let newFarLocation = CLLocation(latitude: 1, longitude: 1)	// Should be relevant because far enough from the current one
		
		XCTAssertFalse(mapViewController!.locationIsRelevant(newNearLocation))
		XCTAssertTrue(mapViewController!.locationIsRelevant(newFarLocation))
	}
	
	func testCheckAddress() {
		// Can't figure out how to test this function as it is asynchronous
//		let expectation = self.expectation(description: "Address is done being checked")
//
//		let queryWithResults = "20 rue des Prés"
//		let queryWithoutResults = "dfjevnjljzrjdslqmoazrfzlj"
//		
//		mapViewController!.checkAddress(for: queryWithResults)
//		waitForExpectations(timeout: 10) { (error) in
//			guard error == nil else {
//				XCTAssert(false)
//				NSLog("Timeout Error")
//				return
//			}
//			
//			XCTAssertGreaterThan(self.mapViewController!.autoCompletePlacemarks.count, 0)
//		}
//		
//		mapViewController!.checkAddress(for: queryWithResults)
//		waitForExpectations(timeout: 10) { (error) in
//			guard error == nil else {
//				XCTAssert(false)
//				NSLog("Timeout Error")
//				return
//			}
//			
//			XCTAssertEqual(self.mapViewController!.autoCompletePlacemarks.count, 0)
//		}
	}
	
	func testConfirmAddress() {
		let placemarkExpectation = expectation(description: "Placemark has been geocoded")
		
		let queryWithResults = "20 rue des Prés"
		let options = ForwardGeocodeOptions(query: queryWithResults)
		
		var placemark: GeocodedPlacemark?
		
		_ = mapViewController!.geocoder.geocode(options) { (placemarks, attribution, error) in
			XCTAssertNil(error)
			XCTAssertNotNil(placemarks)
			
			if placemarks!.count == 0 {
				XCTFail("Couldn't find any placemark for this query")
				return
			} else {
				placemark = placemarks!.first
			}
			
			XCTAssertNotNil(placemark)
			
			placemarkExpectation.fulfill()
		}
		
		waitForExpectations(timeout: 10) { error in
			if let error = error {
				XCTFail("Error: \(error.localizedDescription)")
			}
			else {
				self.mapViewController!.confirmAddress(for: placemark!)
				
				XCTAssertEqual(self.mapViewController!.addressTextField.text, placemark!.qualifiedName)
				XCTAssertEqual(self.mapViewController!.autoCompletePlacemarks.count, 0)
			}
		}
	}
	
}
