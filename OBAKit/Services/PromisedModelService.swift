//
//  PromisedModelService.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 11/5/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import PromiseKit

// MARK: Stop -> OBAArrivalAndDepartureV2
@objc public class PromisedModelService: OBAModelService {
    @objc public func requestStopArrivalsAndDepartures(withID stopID: String, minutesBefore: UInt, minutesAfter: UInt) -> PromiseWrapper {
        let request = buildURLRequestForStopArrivalsAndDepartures(withID: stopID, minutesBefore: minutesBefore, minutesAfter: minutesAfter)
        let promiseWrapper = PromiseWrapper.init(request: request)

        promiseWrapper.promise = promiseWrapper.promise.then { networkResponse -> NetworkResponse in
            let checkCode = self.obaJsonDataSource.checkStatusCodeInBody
            var responseObject = networkResponse.object as AnyObject
            var urlResponse = networkResponse.URLResponse

            if checkCode && responseObject.responds(to: #selector(self.value(forKey:))) {
                let statusCode = (responseObject.value(forKey: "code") as! NSNumber).intValue
                urlResponse = HTTPURLResponse.init(url: urlResponse.url!, statusCode: statusCode, httpVersion: nil, headerFields: urlResponse.allHeaderFields as? [String : String])!
                responseObject = responseObject.value(forKey: "data") as AnyObject
            }

            let (arrivals, error) = self.decodeStopArrivals(json: responseObject)

            if let error = error {
                throw error
            }
            else {
                return NetworkResponse.init(object: arrivals!, URLResponse: networkResponse.URLResponse)
            }
        }

        return promiseWrapper
    }

    private func buildURLRequestForStopArrivalsAndDepartures(withID stopID: String, minutesBefore: UInt, minutesAfter: UInt) -> URLRequest {
        let args = ["minutesBefore": minutesBefore, "minutesAfter": minutesAfter]
        let escapedStopID = OBAURLHelpers.escapePathVariable(stopID)
        let path = String.init(format: "/api/where/arrivals-and-departures-for-stop/%@.json", escapedStopID)

        return self.obaJsonDataSource.buildGETRequest(withPath: path, queryParameters: args)
    }

    private func decodeStopArrivals(json: Any) -> (OBAArrivalsAndDeparturesForStopV2?, Error?) {
        var error: NSError?

        let modelObjects = self.modelFactory.getArrivalsAndDeparturesForStopV2(fromJSON: json as! [AnyHashable : Any], error: &error)
        if let error = error {
            return (nil, error)
        }
        else {
            return (modelObjects,nil)
        }
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

// MARK: - Alarms
@objc extension PromisedModelService {

    /// Creates an alarm object on the server
    ///
    /// - Parameters:
    ///   - alarm: The local alarm object
    ///   - userPushNotificationID: The user's unique push notification ID
    /// - Returns: A promise that fulfills into an URL object
    @nonobjc func createAlarm(_ alarm: OBAAlarm, userPushNotificationID: String) -> Promise<URL> {
        let promise = Promise<URL> { fulfill, reject in
            let request = self.request(alarm, userPushNotificationID: userPushNotificationID) { (responseObject, response, error) in
                if let error = error {
                    reject(error)
                    return
                }

                let dict = responseObject as! Dictionary<String, Any>
                let url = URL.init(string: dict["url"] as! String)

                fulfill(url!)
            }

            if request == nil {
                reject(OBAErrorMessages.cannotRegisterAlarm)
            }
        }
        return promise
    }

    /// Creates an alarm object on the server
    ///
    /// - Parameters:
    ///   - alarm: The local alarm object
    ///   - userPushNotificationID: The user's unique push notification ID
    /// - Returns: A promise that fulfills into an URL object
    @objc func createAlarmPromise(_ alarm: OBAAlarm, userPushNotificationID: String) -> AnyPromise {
        return AnyPromise(createAlarm(alarm, userPushNotificationID: userPushNotificationID))
    }
}

// MARK: - Trip Details
@objc extension PromisedModelService {

    /// Trip details for the specified OBATripInstanceRef
    ///
    /// - Parameter tripInstance: The trip instance reference
    /// - Returns: A Promise that resolves to an instance of OBATripDetailsV2
    @nonobjc func tripDetails(for tripInstance: OBATripInstanceRef) -> Promise<OBATripDetailsV2> {
        let promise = Promise<OBATripDetailsV2> { fulfill, reject in
            self.requestTripDetails(for: tripInstance) { (responseObject, response, error) in
                if let error = error {
                    reject(error);
                    return
                }

                let entry = responseObject as! OBAEntryWithReferencesV2

                fulfill(entry.entry as! OBATripDetailsV2)
            }
        }

        return promise
    }

    /// Trip details for the specified OBATripInstanceRef
    ///
    /// - Parameter tripInstance: The trip instance reference
    /// - Returns: A Promise that resolves to an instance of OBATripDetailsV2
    @objc func promiseTripDetails(for tripInstance: OBATripInstanceRef) -> AnyPromise {
        return AnyPromise(tripDetails(for: tripInstance))
    }
}
