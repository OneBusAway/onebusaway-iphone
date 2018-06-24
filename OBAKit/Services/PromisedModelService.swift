//
//  PromisedModelService.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 11/5/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import PromiseKit
import Mantle

// MARK: Stop -> OBAArrivalAndDepartureV2
@objc public class PromisedModelService: OBAModelService {
    @objc public func requestStopArrivalsAndDepartures(withID stopID: String, minutesBefore: UInt, minutesAfter: UInt) -> PromiseWrapper {
        let request = buildURLRequestForStopArrivalsAndDepartures(withID: stopID, minutesBefore: minutesBefore, minutesAfter: minutesAfter)
        let promiseWrapper = PromiseWrapper.init(request: request)

        promiseWrapper.promise = promiseWrapper.promise.then { networkResponse -> NetworkResponse in
            let arrivals = try self.decodeStopArrivals(json: networkResponse.object)
            return NetworkResponse.init(object: arrivals, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return promiseWrapper
    }

    // TODO: extract this URL generation code into a new, separate class somewhere that is
    // solely focused on URL generation.
    @objc public func buildURLRequestForStopArrivalsAndDepartures(withID stopID: String, minutesBefore: UInt, minutesAfter: UInt) -> OBAURLRequest {
        let args = ["minutesBefore": minutesBefore, "minutesAfter": minutesAfter]
        let escapedStopID = OBAURLHelpers.escapePathVariable(stopID)
        let path = String.init(format: "/api/where/arrivals-and-departures-for-stop/%@.json", escapedStopID)

        return self.obaJsonDataSource.buildGETRequest(withPath: path, queryParameters: args)
    }

    private func decodeStopArrivals(json: Any) throws -> OBAArrivalsAndDeparturesForStopV2 {
        var error: NSError?

        let modelObjects = self.modelFactory.getArrivalsAndDeparturesForStopV2(fromJSON: json as! [AnyHashable : Any], error: &error)
        if let error = error {
            throw error
        }

        return modelObjects
    }
}

// MARK: - Regions
@objc extension PromisedModelService {
    ///  Retrieves all available OBA regions, including experimental and inactive regions.
    ///
    /// - Returns: An array of OBARegionV2 objects.
    @objc public func requestRegions() -> PromiseWrapper {
        let request = buildURLRequestForRegions()
        let wrapper = PromiseWrapper.init(request: request)

        wrapper.promise = wrapper.promise.then { networkResponse -> NetworkResponse in
            let regions = try self.decodeRegions(json: networkResponse.object)
            return NetworkResponse.init(object: regions, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    private func decodeRegions(json: Any) throws -> [OBARegionV2] {
        var error: NSError? = nil
        let listWithRangeAndReferences = self.modelFactory.getRegionsV2(fromJson: json, error: &error)

        if let error = error {
            throw error
        }

        let regions = listWithRangeAndReferences.values as! [OBARegionV2]

        return regions
    }

    private func buildURLRequestForRegions() -> OBAURLRequest {
        let path = "/regions-v3.json"
        return self.obaRegionJsonDataSource.buildGETRequest(withPath: path, queryParameters: nil)
    }
}

// MARK: - Regional Alerts
@objc extension PromisedModelService {
    /// Retrieves a list of alert messages for the specified `region` since `date`. The completion block's responseData is [OBARegionalAlert]
    ///
    /// - Parameters:
    ///   - region: The region from which alerts are desired.
    ///   - date: The last date that alerts were requested. Specify nil for all time.
    /// - Returns: A promise wrapper that resolves to [OBARegionalAlert]
    @objc func requestAlerts(for region: OBARegionV2, since date: Date?) -> PromiseWrapper {
        let request = buildURLRequestForRegionalAlerts(region: region, since: date)
        let wrapper = PromiseWrapper.init(request: request)

        wrapper.promise = wrapper.promise.then { networkResponse -> NetworkResponse in
            let alerts = try self.decodeRegionalAlerts(json: networkResponse.object as! [Any])
            return NetworkResponse.init(object: alerts, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    @nonobjc private func buildURLRequestForRegionalAlerts(region: OBARegionV2, since date: Date?) -> OBAURLRequest {
        var params = ["since": 0]

        if let date = date {
            params["since"] = Int(date.timeIntervalSince1970)
        }

        let path = "/regions/\(region.identifier)/alert_feed_items"

        return self.obacoJsonDataSource.buildGETRequest(withPath: path, queryParameters: params)
    }

    @nonobjc private func decodeRegionalAlerts(json: [Any]) throws -> [OBARegionalAlert] {
        let models: [OBARegionalAlert] = try MTLJSONAdapter.models(of: OBARegionalAlert.self, fromJSONArray: json) as! [OBARegionalAlert]

        // Mark all alerts older than one day as 'read' automatically.
        return models.map {
            if let published = $0.publishedAt {
                $0.unread = abs(published.timeIntervalSinceNow) < 86400 // Number of seconds in 1 day.
            }
            return $0
        }
    }
}

// MARK: - Weather
@objc extension PromisedModelService {

    /// Request the forecasted weather for the user's region and/or location.
    ///
    /// - Parameters:
    ///   - region: The user's current region
    ///   - location: An optional location used to determine more accurate weather data.
    /// - Returns: A promise wrapper that resolves to a WeatherForecast object.
    @objc public func requestWeather(in region: OBARegionV2, location: CLLocation?) -> PromiseWrapper {
        let request = buildURLRequestForWeather(in: region, location: location)
        let wrapper = PromiseWrapper.init(request: request)

        wrapper.promise = wrapper.promise.then { networkResponse -> NetworkResponse in
            let forecast = try self.decodeWeather(json: networkResponse.object as! [AnyHashable : Any])
            return NetworkResponse.init(object: forecast, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    @nonobjc private func decodeWeather(json: [AnyHashable: Any]) throws -> WeatherForecast {
        let model = try MTLJSONAdapter.model(of: WeatherForecast.self, fromJSONDictionary: json)

        return model as! WeatherForecast
    }

    @nonobjc private func buildURLRequestForWeather(in region: OBARegionV2, location: CLLocation?) -> OBAURLRequest {
        let path = "/regions/\(region.identifier)/weather"

        var params: [AnyHashable: Any] = [:]
        if let location = location {
            params["lat"] = location.coordinate.latitude
            params["lng"] = location.coordinate.longitude
        }

        return self.obacoJsonDataSource.buildGETRequest(withPath: path, queryParameters: params)
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
    @objc func createAlarm(_ alarm: OBAAlarm, userPushNotificationID: String) -> PromiseWrapper {
        let request = createAlarmRequest(alarm, userPushNotificationID: userPushNotificationID)
        let wrapper = PromiseWrapper.init(request: request)

        wrapper.promise = wrapper.promise.then { networkResponse -> NetworkResponse in
            let dict = networkResponse.object as! Dictionary<String, Any>
            let url = URL.init(string: dict["url"] as! String)!

            return NetworkResponse.init(object: url, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    @nonobjc private func createAlarmRequest(_ alarm: OBAAlarm, userPushNotificationID: String) -> OBAURLRequest {
        let params: [String: Any] = [
            "seconds_before": alarm.timeIntervalBeforeDeparture,
            "stop_id":        alarm.stopID,
            "trip_id":        alarm.tripID,
            "service_date":   alarm.serviceDate,
            "vehicle_id":     alarm.vehicleID,
            "stop_sequence":  alarm.stopSequence,
            "user_push_id":   userPushNotificationID
        ]

        return self.obacoJsonDataSource.buildRequest(withPath: "/regions/\(alarm.regionIdentifier)/alarms", httpMethod: "POST", queryParameters: nil, formBody: params)
    }
}

// MARK: - Trip Details
@objc extension PromisedModelService {
    /// Trip details for the specified OBATripInstanceRef
    ///
    /// - Parameter tripInstance: The trip instance reference
    /// - Returns: A PromiseWrapper that resolves to an instance of OBATripDetailsV2
    @objc public func requestTripDetails(tripInstance: OBATripInstanceRef) -> PromiseWrapper {
        let request = self.buildTripDetailsRequest(tripInstance: tripInstance)
        let wrapper = PromiseWrapper.init(request: request)

        wrapper.promise = wrapper.promise.then { networkResponse -> NetworkResponse in
            let tripDetails = try self.decodeTripDetails(json: networkResponse.object as! [AnyHashable : Any])
            return NetworkResponse.init(object: tripDetails, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    @nonobjc private func decodeTripDetails(json: [AnyHashable: Any]) throws -> OBATripDetailsV2 {
        var error: NSError? = nil
        let model = self.modelFactory.getTripDetailsV2(fromJSON: json, error: &error)

        if let error = error {
            throw error
        }

        let entry = model.entry as! OBATripDetailsV2
        return entry
    }

    @nonobjc private func buildTripDetailsRequest(tripInstance: OBATripInstanceRef) -> OBAURLRequest {
        var args: [String: Any] = [:]
        if tripInstance.serviceDate > 0 {
            args["serviceDate"] = tripInstance.serviceDate
        }

        if tripInstance.vehicleId != nil {
            args["vehicleId"] = tripInstance.vehicleId
        }

        let escapedTripID = OBAURLHelpers.escapePathVariable(tripInstance.tripId)

        return self.obaJsonDataSource.buildGETRequest(withPath: "/api/where/trip-details/\(escapedTripID).json", queryParameters: args)
    }
}
