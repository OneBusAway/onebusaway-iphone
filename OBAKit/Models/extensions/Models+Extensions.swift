//
//  Models+Extensions.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 7/12/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import Foundation

public extension Collection where Iterator.Element == OBAStopV2 {
    func sortByDistance(coordinate: CLLocationCoordinate2D?) -> [OBAStopV2] {
        guard let coordinate = coordinate else {
            // swiftlint:disable force_cast
            return self as! [OBAStopV2]
            // swiftlint:enable force_cast
        }

        return self.sorted { (s1, s2) -> Bool in
            let distance1 = OBAMapHelpers.getDistanceFrom(s1.coordinate, to: coordinate)
            let distance2 = OBAMapHelpers.getDistanceFrom(s2.coordinate, to: coordinate)
            return distance1 < distance2
        }
    }
}
