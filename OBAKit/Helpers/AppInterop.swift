//
//  AppInterop.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 9/2/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import Foundation
import CoreLocation

@objc public class AppInterop: NSObject {

    /// Creates an URL that can open the Google Maps app with the user's desired
    /// destination in walking directions mode.
    ///
    /// - Parameter coordinate: The destination coordinate
    /// - Returns: An URL that will launch Google Maps in walking directions mode
    @objc public class func googleMapsWalkingDirectionsURL(coordinate: CLLocationCoordinate2D) -> URL? {
        var params: [URLQueryItem] = []
        params.append(URLQueryItem.init(name: "daddr", value: "\(coordinate.latitude),\(coordinate.longitude)"))
        params.append(URLQueryItem.init(name: "directionsmode", value: "walking"))

        guard let components = NSURLComponents.init(string: "comgooglemaps://") else {
            return nil
        }

        components.queryItems = params
        return components.url
    }

    /// Creates an URL that can open the Apple Maps app with the user's desired
    /// destination in walking directions mode.
    ///
    /// - Parameter coordinate: The destination coordinate
    /// - Returns: An URL that will launch Apple Maps in walking directions mode
    @objc public class func appleMapsWalkingDirectionsURL(coordinate: CLLocationCoordinate2D) -> URL? {
        var params: [URLQueryItem] = []
        params.append(URLQueryItem.init(name: "daddr", value: "\(coordinate.latitude),\(coordinate.longitude)"))
        params.append(URLQueryItem.init(name: "dirflg", value: "w"))

        guard let components = NSURLComponents.init(string: "http://maps.apple.com/") else {
            return nil
        }

        components.queryItems = params

        return components.url
    }
}
