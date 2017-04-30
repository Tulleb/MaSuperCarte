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
	
	func testPlacemarksFromText() {
		let expectationTimeout: TimeInterval = 10.0
		
		let resultsPlacemarksQueryExpectation = self.expectation(description: "Address with placemarks is done being checked")

		let queryWithResults = "20 rue des Prés Franconville"
		let queryWithoutResults = "dfjevnjljzrjdslqmoazrfzlj"
		
		mapViewController!.placemarks(from: queryWithResults) { (placemarks: [GeocodedPlacemark]?) in
			guard let placemarks = placemarks, placemarks.count > 0 else {
				XCTFail("Couldn't find any placemark for this query")
				return
			}
			
			XCTAssertNotNil(placemarks)
			XCTAssertGreaterThan(placemarks.count, 0)
			
			resultsPlacemarksQueryExpectation.fulfill()
		}
		
		waitForExpectations(timeout: expectationTimeout) { error in
			if let error = error {
				XCTFail("Error with results query: \(error.localizedDescription)")
			}
		}
		
		let emplyPlacemarksQueryExpectation = self.expectation(description: "Address without placemarks is done being checked")
		
		mapViewController!.placemarks(from: queryWithoutResults) { (placemarks: [GeocodedPlacemark]?) in
			XCTAssertNil(placemarks)
			
			emplyPlacemarksQueryExpectation.fulfill()
		}
		
		waitForExpectations(timeout: expectationTimeout) { error in
			if let error = error {
				XCTFail("Error with empty query: \(error.localizedDescription)")
			}
		}
	}
	
	func testConfirmAddress() {
		let placemarkExpectation = expectation(description: "Placemark has been geocoded")
		
		let queryWithResults = "20 rue des Prés Franconville"
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
				
				XCTAssertEqual(self.mapViewController!.addressTextField.text, self.mapViewController!.address(from: placemark!))
				XCTAssertEqual(self.mapViewController!.autoCompletePlacemarks.count, 0)
			}
		}
	}
	
	func testAddressFromCoordinate() {
		let resultsAddressExpectation = self.expectation(description: "Coordinate is done being checked")
		
		let addressCoordinate = CLLocation(latitude: 48.98925320, longitude: 2.22508220).coordinate
		
		mapViewController!.address(from: addressCoordinate) { (address: String?) in
			guard let address = address else {
				XCTFail("Couldn't find any address for this coordinate")
				return
			}
			
			XCTAssertNotNil(address)
			
			resultsAddressExpectation.fulfill()
		}
		
		waitForExpectations(timeout: 10) { error in
			if let error = error {
				XCTFail("Error with results query: \(error.localizedDescription)")
			}
		}
	}
	
	func testAddressFromPlacemark() {
		let placemarkExpectation = expectation(description: "Placemark has been geocoded")
		
		let queryWithResults = "20 rue des Prés Franconville"
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
				let address = self.mapViewController!.address(from: placemark!)
				
				XCTAssertEqual(address, "20 Rue des Prés, 95130 Franconville")
			}
		}
	}
	
}
