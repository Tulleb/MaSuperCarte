//
//  MapViewController.swift
//  MaSuperCarte
//
//  Created by Guillaume Bellut on 29/04/2017.
//  Copyright © 2017 Guillaume Bellut. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift
import RxSwift

class MapViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, SlideMenuControllerDelegate {
	
	// MARK: Storyboard properties
	
	@IBOutlet weak var mapView: UIView!
	@IBOutlet weak var addressTextField: UITextField!
	@IBOutlet weak var autoCompletePlacemarkTableView: UITableView!
	@IBOutlet weak var autoCompletePlacemarkTableViewHeightConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var menuButton: UIButton!
	
	
	// MARK: Basic properties
	
	var mapViewModel: MapboxViewModel?
	
	var autoCompletePlacemarks: [String] = [] {
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
	
	let disposeBag = DisposeBag()
	
	// MARK: Overriding functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard let mapViewModel = mapViewModel else {
			return
		}
		
//		mapViewModel.mapView.bindTo(mapView.rx_).addDisposableTo(disposeBag)
		mapViewModel.addressText.bindTo(addressTextField.rx_text).addDisposableTo(disposeBag)
		carViewModel.kilowattText.bindTo(kilowattField.rx_text).addDisposableTo(disposeBag)
		
		makeField.rx_text.bindTo(carViewModel.makeText).addDisposableTo(disposeBag)
		modelField.rx_text.bindTo(carViewModel.modelText).addDisposableTo(disposeBag)
		kilowattField.rx_text.filter({ (string) -> Bool in
			// Validate we are only passing Ints
			return Int(string) != nil || string.isEmpty
		}).bindTo(carViewModel.kilowattText).addDisposableTo(disposeBag)
		
		carViewModel.titleText.subscribeNext { (title) in
			self.navigationItem.title = title
			}.addDisposableTo(disposeBag)
		
		navigationItem.rightBarButtonItem = saveButton
		
		mapView = mapViewModel.setupView()
		
		autoCompletePlacemarkTableView.rowHeight = UITableViewAutomaticDimension;
		autoCompletePlacemarkTableView.estimatedRowHeight = MapViewModel.DefaultAutoCompleteAddressTableViewRowHeight
		
		addressTextField.addTarget(self, action: #selector(textFieldDidChange), for: UIControlEvents.editingChanged)
		
		menuButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
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
	
	
	// MARK: Storyboard functions
	
	@IBAction func menuAction(_ sender: Any) {
		self.slideMenuController()?.openLeft()
	}
	
	
	// MARK: Class functions
	
	func textFieldDidChange(_ sender: UITextField) {
		if sender == addressTextField {
			guard let text = addressTextField.text, text != "" else {
				self.autoCompletePlacemarks = []
				return
			}
			
			placemarks(from: text) { (placemarks: [GeocodedPlacemark]?) in
				if let placemarks = placemarks {
					self.autoCompletePlacemarks = placemarks
				}
			}
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
		
		placemarks(from: text) { (placemarks: [GeocodedPlacemark]?) in
			if let placemarks = placemarks {
				self.autoCompletePlacemarks = placemarks
			}
		}
		
		return true
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		textField.text = ""
		textField.resignFirstResponder()
		
		return false
	}
	
	
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return autoCompletePlacemarks.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell") as? AddressCell else {
			return UITableViewCell()
		}
		
		let placemark = autoCompletePlacemarks[indexPath.row]
		cell.addressLabel.text = address(from: placemark)
		
		return cell
	}
	
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		confirmAddress(for: autoCompletePlacemarks[indexPath.row])
	}
	
	
	// MARK: SlideMenuControllerDelegate
	
	func leftDidClose() {
		print("Left menu just closed")
		
		let applicationDelegate = UIApplication.shared.delegate as! AppDelegate
		
		guard let selectedAddress = applicationDelegate.selectedAddressFromMenu else {
			return
		}
		
		print("Centering card on \(selectedAddress.name)...")
		mapView.setCenter(selectedAddress.coordinate, animated: true)
		
		applicationDelegate.selectedAddressFromMenu = nil
	}
	
}

