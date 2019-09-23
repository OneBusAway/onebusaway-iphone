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
	public var arrivalAndDepartureViewDelegate: OBAArrivalAndDepartureViewDataSource!
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self,
											   selector: #selector(contentSizeDidChange),
											   name: UIContentSizeCategory.didChangeNotification,
											   object: nil)
	}
	
	deinit { NotificationCenter.default.removeObserver(self) }
	
	@objc func contentSizeDidChange() {
		self.reloadData()
	}
	
	public func reloadData() {
		self.tableView.reloadData()	// TODO: Don't reload everything.
		self.tableView.layoutIfNeeded()
		
		// Scroll down to the selected stop.
		if let tripDetails = arrivalAndDepartureViewDelegate.tripDetails,
			let arrivalAndDeparture = arrivalAndDepartureViewDelegate.arrivalAndDeparture {

			let indexOfSelectedStop = tripDetails.schedule.tableViewDataSource.firstIndex(where: {
				switch $0 {
				case .stopTime(let stopTime):
					return stopTime.stopId == arrivalAndDeparture.stopId
				case .trip:
					return false
				}
			})
			
			if let index = indexOfSelectedStop {
				self.tableView.scrollToRow(at: IndexPath(item: index, section: 0), at: .top, animated: false)
			}
			
		}
	}
	
	override public func numberOfSections(in tableView: UITableView) -> Int {
		return self.arrivalAndDepartureViewDelegate.tripDetails != nil ? 1 : 0
	}
	
	override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let tripDetails = self.arrivalAndDepartureViewDelegate.tripDetails else { return 0 }
		return tripDetails.schedule.tableViewDataSource.count
	}
	
	override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let tripDetails = self.arrivalAndDepartureViewDelegate.tripDetails else { fatalError() }
		let data = tripDetails.schedule.tableViewDataSource[indexPath.row]
		
		switch data {
		case .trip(let trip):
			let cell = tableView.dequeueReusableCell(withIdentifier: OBATripScheduleConnectionTableViewCell.ReuseIdentifier, for: indexPath) as! OBATripScheduleConnectionTableViewCell
			
			cell.update(with: trip, as: indexPath.row == 0 ? .previousConnection : .nextConnection)
			cell.layoutIfNeeded()
			
			return cell
		case .stopTime(let stopTime):
			let stop = stopTime.stop!
			
			let cell = tableView.dequeueReusableCell(withIdentifier: OBATripScheduleTableViewCell.ReuseIdentifier, for: indexPath) as! OBATripScheduleTableViewCell
			
			let properties = (selectedStopForRider: stop.stopId == arrivalAndDepartureViewDelegate.arrivalAndDeparture?.stopId,
							  closestStopToVehicle: stop.stopId == arrivalAndDepartureViewDelegate.arrivalAndDeparture?.tripStatus.closestStopID,
							  routeType: stop.firstAvailableRouteTypeForStop(),
							  historicalOccupancyStatus: stopTime.historicalOccupancy)
			
			cell.update(with: stopTime, tripDetails: tripDetails, properties: properties)
			cell.layoutIfNeeded()
			
			return cell
		}
	}

	override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let data = self.arrivalAndDepartureViewDelegate.tripDetails?.schedule.tableViewDataSource else { return }
		let item = data[indexPath.row]
		
		switch item {
		case .trip(let trip):
			self.arrivalAndDepartureViewDelegate.didSelectTrip(trip)
		case .stopTime(let stopTime):
			if let stop = stopTime.stop {
				self.arrivalAndDepartureViewDelegate.didSelectStop(stop)
			}
		}
	}
}
