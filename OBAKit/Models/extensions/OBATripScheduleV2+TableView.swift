//
//  OBATripScheduleV2+TableView.swift
//  OBAKit
//
//  Created by Alan Chu on 9/22/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

public extension OBATripScheduleV2 {
	enum TableViewDataSourceType {
		case trip(OBATripV2)
		case stopTime(OBATripStopTimeV2)
	}

	var tableViewDataSource: [TableViewDataSourceType] {
		var data: [TableViewDataSourceType] = []
		if let previousTrip = self.previousTrip {
			data.append(.trip(previousTrip))
		}

		self.stopTimes.forEach { data.append(.stopTime($0))}

		if let nextTrip = self.nextTrip {
			data.append(.trip(nextTrip))
		}

		return data
	}
}
