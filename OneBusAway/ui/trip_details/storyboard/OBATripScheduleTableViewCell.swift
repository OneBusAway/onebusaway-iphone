//
//  OBATripScheduleTableViewCell.swift
//  OneBusAway
//
//  Created by Alan Chu on 9/21/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import UIKit

public class OBATripScheduleTableViewCell: UITableViewCell {
	public static let ReuseIdentifier = "OBATripScheduleTableViewCell_ReuseIdentifier"
	
	public typealias PropertiesToSet = (selectedStopForRider: Bool,
										closestStopToVehicle: Bool,
										routeType: OBARouteType,
										historicalOccupancyStatus: OBAOccupancyStatus)
	
	@IBOutlet var stopLabel: UILabel!
	@IBOutlet var timeLabel: UILabel!
	@IBOutlet var stateImageView: UIImageView!
	
	public func update(with tripStopTime: OBATripStopTimeV2, tripDetails: OBATripDetailsV2, properties: PropertiesToSet) {
		self.stopLabel.text = tripStopTime.stop!.name
		self.timeLabel.text = self.formattedStopTime(tripStopTime: tripStopTime, tripDetails: tripDetails)
		
		// Set state image
		let imageViewSize = CGSize(width: self.stateImageView.bounds.width, height: self.stateImageView.bounds.height)
		if properties.closestStopToVehicle {
			let image = OBAStopIconFactory.image(for: properties.routeType)
			self.stateImageView.image = OBAImageHelpers.circleImage(with: imageViewSize, contents: image, stroke: OBATheme.obaDarkGreen)
			
			self.stateImageView.accessibilityLabel = String(format: NSLocalizedString("arrival_departure_cell.closest_stop", comment: "The vehicle is currently closest to <STOP NAME>"), tripStopTime.stop!.name)
		} else if properties.selectedStopForRider {
			let image = UIImage(named: "walkTransport")!
			self.stateImageView.image = OBAImageHelpers.circleImage(with: imageViewSize, contents: image, stroke: OBATheme.obaDarkGreen)
			self.stateImageView.accessibilityLabel = nil
		} else {
			self.stateImageView.image = OBAImageHelpers.circleImage(with: imageViewSize, contents: nil)
			self.stateImageView.accessibilityLabel = nil
		}
	}
	
	fileprivate func formattedStopTime(tripStopTime: OBATripStopTimeV2, tripDetails: OBATripDetailsV2) -> String {
//		if tripDetails.schedule.frequency {
//			let firstStopTime = tripDetails.schedule.stopTimes[0]
//			let minutes = (tripStopTime.arrivalTime - firstStopTime.departureTime) / 60
//			return "\(minutes) \(NSLocalizedString("msg_mins", comment: "minutes"))"
//		} else {
			let time = OBADateHelpers.getTripStopTime(asDate: tripStopTime, tripDetails: tripDetails)
			return OBADateHelpers.formatShortTimeNoDate(time)
//		}
	}
}
