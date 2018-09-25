//
//  BoxedCoordinateRegion.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 9/19/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

@objc(OBABoxedCoordinateRegion)
public class BoxedCoordinateRegion: NSObject, NSCoding {
    @objc public let coordinateRegion: MKCoordinateRegion

    @objc
    public init(coordinateRegion: MKCoordinateRegion) {
        self.coordinateRegion = coordinateRegion
    }

    // MARK: - NSCoding

    private let kLatitude = "latitude"
    private let kLongitude = "longitude"
    private let kLatitudeDelta = "latitudeDelta"
    private let kLongitudeDelta = "longitudeDelta"

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(coordinateRegion.center.latitude, forKey: kLatitude)
        aCoder.encode(coordinateRegion.center.longitude, forKey: kLongitude)

        aCoder.encode(coordinateRegion.span.latitudeDelta, forKey: kLatitudeDelta)
        aCoder.encode(coordinateRegion.span.longitudeDelta, forKey: kLongitudeDelta)
    }

    public required init?(coder aDecoder: NSCoder) {
        let center = CLLocationCoordinate2D(latitude: aDecoder.decodeDouble(forKey: kLatitude), longitude: aDecoder.decodeDouble(forKey: kLongitude))
        let span = MKCoordinateSpan(latitudeDelta: aDecoder.decodeDouble(forKey: kLatitudeDelta), longitudeDelta: aDecoder.decodeDouble(forKey: kLongitudeDelta))
        self.coordinateRegion = MKCoordinateRegion(center: center, span: span)

        super.init()
    }
}
