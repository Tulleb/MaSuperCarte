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
		let newLocation1 = CLLocation(latitude: 48.98925320, longitude: 2.22508220)	// Should be irrelevant because too close from the current one
		let newLocation2 = CLLocation(latitude: 1, longitude: 1)	// Should be relevant because far enough from the current one
		
		XCTAssertFalse(mapViewController!.locationIsRelevant(newLocation1))
		XCTAssertTrue(mapViewController!.locationIsRelevant(newLocation2))
	}
}
