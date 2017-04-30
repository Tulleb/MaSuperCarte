//
//  MenuViewController.swift
//  MaSuperCarte
//
//  Created by Guillaume Bellut on 30/04/2017.
//  Copyright © 2017 Guillaume Bellut. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	var lastAddresses = (UIApplication.shared.delegate as! AppDelegate).lastAddresses
	
	// MARK: Storyboard properties
	
	@IBOutlet weak var noAddressLabel: UILabel!
	@IBOutlet weak var addressTableView: UITableView!
	
	
	// MARK: Overriding Functions
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		let applicationDelegate = UIApplication.shared.delegate as! AppDelegate
		lastAddresses = applicationDelegate.lastAddresses
		
		if lastAddresses.count > 0 {
			self.noAddressLabel.isHidden = true
			self.addressTableView.isHidden = false
			
			self.addressTableView.reloadData()
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return lastAddresses.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell") as? AddressCell else {
			return UITableViewCell()
		}
		
		let address = lastAddresses[indexPath.row]
		cell.addressLabel.text = address.name
		
		return cell
	}
	
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let applicationDelegate = UIApplication.shared.delegate as! AppDelegate
		applicationDelegate.selectedAddressFromMenu = lastAddresses[indexPath.row]
		
		self.slideMenuController()?.closeLeft()
	}

}
