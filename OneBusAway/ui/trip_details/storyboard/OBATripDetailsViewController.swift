//
//  OBATripScheduleTableViewHeader.swift
//  OneBusAway
//
//  Created by Alan Chu on 9/22/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import UIKit

public class OBATripDetailsViewController: UIViewController {
	public weak var arrivalAndDepartureViewDelegate: OBAArrivalAndDepartureViewDelegate?
	
	@IBOutlet var routeInfoLabel: UILabel!
	@IBOutlet var arrivalInfoLabel: UILabel!
	@IBOutlet var estimatedTimeLabel: UILabel!
	
	public func reloadData() {
		let tripDetails = arrivalAndDepartureViewDelegate?.tripDetails
		routeInfoLabel.text = tripDetails?.trip?.asLabel ?? "..."
	}
}
