//
//  MatchingAgencyVehicle.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 7/10/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import Foundation

@objc(OBAMatchingAgencyVehicle)
public final class MatchingAgencyVehicle: NSObject, Codable {
    @objc public let agencyID: String
    @objc public let name: String
    @objc public let vehicleID: String

    @objc public var userFriendlyVehicleID: String {
        let prefix = "\(agencyID)_"
        if vehicleID.hasPrefix(prefix) {
            return String(vehicleID.dropFirst(prefix.count))
        }
        else {
            return vehicleID
        }
    }

    enum CodingKeys: String, CodingKey {
        case agencyID = "id"
        case name
        case vehicleID = "vehicle_id"
    }

    override init() {
        fatalError()
    }
}
