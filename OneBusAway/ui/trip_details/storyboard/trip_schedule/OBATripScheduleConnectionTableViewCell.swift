//
//  OBATripScheduleConnectionTableViewCell.swift
//  OneBusAway
//
//  Created by Alan Chu on 9/22/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import UIKit

public class OBATripScheduleConnectionTableViewCell: UITableViewCell {
	public enum ConnectionType {
		case previousConnection
		case nextConnection
	}
	
	public static let ReuseIdentifier = "OBATripScheduleConnectionTableViewCell_ReuseIdentifier"
	
	@IBOutlet var previousConnectionLine: UIView!
	@IBOutlet var nextConnectionLine: UIView!
	@IBOutlet var label: UILabel!
	
	public func update(with trip: OBATripV2, as type: ConnectionType) {
		switch type {
		case .previousConnection:
			previousConnectionLine.isHidden = false
			nextConnectionLine.isHidden = true
			
			label.text = String(format: NSLocalizedString("text_starts_as_param", comment: ""), trip.asLabel)
			
		case .nextConnection:
			previousConnectionLine.isHidden = true
			nextConnectionLine.isHidden = false
			
			label.text = String(format: NSLocalizedString("text_continues_as_param", comment: ""), trip.asLabel)
		}
	}
}
