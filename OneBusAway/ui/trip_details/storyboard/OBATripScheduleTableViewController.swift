//
//  OBAArrivalAndDepartureTimetableViewController.swift
//  OneBusAway
//
//  Created by Alan Chu on 9/21/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import UIKit
import OBAKit

public class OBATripScheduleTableViewController: UITableViewController {
	public var arrivalAndDepartureViewDelegate: OBAArrivalAndDepartureViewDelegate!
	
	override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let tripDetails = self.arrivalAndDepartureViewDelegate.tripDetails else { return 0 }
		return tripDetails.schedule.stopTimes.count
	}
	
	override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let tripDetails = self.arrivalAndDepartureViewDelegate.tripDetails else { fatalError() }
		let stopTime = tripDetails.schedule.stopTimes[indexPath.row]
		let stop = stopTime.stop!
		
		let cell = tableView.dequeueReusableCell(withIdentifier: OBATripScheduleTableViewCell.ReuseIdentifier, for: indexPath) as! OBATripScheduleTableViewCell
		
		let properties = (selectedStopForRider: stop.stopId == arrivalAndDepartureViewDelegate.arrivalAndDeparture?.stopId,
						  closestStopToVehicle: stop.stopId == arrivalAndDepartureViewDelegate.arrivalAndDeparture?.tripStatus.closestStopID,
						  routeType: stop.firstAvailableRouteTypeForStop(),
						  historicalOccupancyStatus: stopTime.historicalOccupancy)
		
		cell.update(with: tripDetails.schedule.stopTimes[indexPath.row], tripDetails: tripDetails, properties: properties)

		return cell
	}
}
