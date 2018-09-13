//
//  StopViewModel.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 5/23/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import CoreLocation
import UIKit
import IGListKit

class StopViewModel: NSObject {
    let name: String
    let stopID: String
    let direction: String?
    let routeNames: String
    let coordinate: CLLocationCoordinate2D
    let image: UIImage?

    init(name: String, stopID: String, direction: String?, routeNames: String, coordinate: CLLocationCoordinate2D, image: UIImage? = nil) {
        self.name = name
        self.stopID = stopID
        self.direction = direction
        self.routeNames = routeNames
        self.coordinate = coordinate
        self.image = image
    }
}

// MARK: - Helpers
extension StopViewModel {
    var nameWithDirection: String {
        if let dir = direction {
            return "\(name) (\(dir))"
        }
        else {
            return name
        }
    }
}

// MARK: - ListDiffable
extension StopViewModel: ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        return "stop_\(stopID)" as NSObjectProtocol
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard self !== object else { return true }
        guard let object = object as? StopViewModel else { return false }
        return name == object.name
            && stopID == object.stopID
            && direction == object.direction
            && routeNames == object.routeNames
            && coordinate.latitude == object.coordinate.latitude
            && coordinate.longitude == object.coordinate.longitude
            && image == object.image
    }
}
