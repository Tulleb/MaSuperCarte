//
//  ContainerViewController.swift
//  MaSuperCarte
//
//  Created by Guillaume Bellut on 01/05/2017.
//  Copyright © 2017 Guillaume Bellut. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift

class ContainerViewController: SlideMenuController {
	
	// MARK: Overriding Functions
	
	override func awakeFromNib() {
		if let controller = self.storyboard?.instantiateViewController(withIdentifier: "MapViewController") {
			self.mainViewController = controller
		}
		if let controller = self.storyboard?.instantiateViewController(withIdentifier: "MenuViewController") {
			self.leftViewController = controller
		}
		super.awakeFromNib()
	}
	
}
