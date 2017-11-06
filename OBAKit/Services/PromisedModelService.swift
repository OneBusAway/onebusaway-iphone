//
//  PromisedModelService.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 11/5/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import PromiseKit

@objc public class PromisedModelService: OBAModelService {

    /// Swift-Compatible: Stop data with arrivals and departures for the specified stop ID.
    ///
    /// - Parameters:
    ///   - withID: The ID of the stop that will be returned.
    ///   - minutesBefore: How many minutes of elapsed departures should be included
    ///   - minutesAfter: How many minutes into the future should be returned
    /// - Returns: A promise that resolves to an OBAArrivalsAndDeparturesForStopV2 object
    @nonobjc public func stop(withID: String, minutesBefore: UInt, minutesAfter: UInt) -> Promise<OBAArrivalsAndDeparturesForStopV2> {
        let promise = Promise<OBAArrivalsAndDeparturesForStopV2> { fulfill, reject in
            self.requestStopWithArrivalsAndDepartures(forId: withID, withMinutesBefore: minutesBefore, withMinutesAfter: minutesAfter) { (responseObject, response, error) in
                if let error = error {
                    reject(error)
                }
                else if response.statusCode == 404 {
                    reject(OBAErrorMessages.stopNotFoundError)
                }
                else if response.statusCode >= 300 {
                    reject(OBAErrorMessages.connectionError(response))
                }

                fulfill(responseObject as! OBAArrivalsAndDeparturesForStopV2)
            }
        }
        return promise
    }

    /// Obj-C Compatible: Stop data with arrivals and departures for the specified stop ID.
    ///
    /// - Parameters:
    ///   - withID: The ID of the stop that will be returned.
    ///   - minutesBefore: How many minutes of elapsed departures should be included
    ///   - minutesAfter: How many minutes into the future should be returned
    /// - Returns: A promise that resolves to an OBAArrivalsAndDeparturesForStopV2 object
    @objc public func promiseStop(withID: String, minutesBefore: UInt, minutesAfter: UInt) -> AnyPromise {
        return AnyPromise(stop(withID: withID, minutesBefore: minutesBefore, minutesAfter: minutesAfter))
    }
}

// MARK: - Regional Alerts
@objc extension PromisedModelService {
    /// Retrieves a list of alert messages for the specified `region` since `date`.
    ///
    /// - Parameters:
    ///   - region: The region from which alerts are desired
    ///   - sinceDate: The last date that alerts were requested. Specify nil for all time.
    /// - Returns: A promise that resolves to [OBARegionalAlert]
    @nonobjc public func regionalAlerts(region: OBARegionV2, sinceDate: Date?) -> Promise<[OBARegionalAlert]> {
        let promise = Promise<[OBARegionalAlert]> { fulfill, reject in
            self.requestRegionalAlerts(region, since: sinceDate) { (responseObject, response, error) in
                if let error = error {
                    reject(error)
                }
                else {
                    fulfill(responseObject as! [OBARegionalAlert])
                }
            }
        }

        return promise
    }

    /// Retrieves a list of alert messages for the specified `region` since `date`.
    ///
    /// - Parameters:
    ///   - region: The region from which alerts are desired
    ///   - sinceDate: The last date that alerts were requested. Specify nil for all time.
    /// - Returns: A promise that resolves to [OBARegionalAlert]
    @objc public func promiseRegionalAlerts(region: OBARegionV2, sinceDate: Date?) -> AnyPromise {
        return AnyPromise(regionalAlerts(region: region, sinceDate: sinceDate))
    }
}
