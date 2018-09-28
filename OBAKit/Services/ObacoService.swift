//
//  ObacoService.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 9/27/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import Foundation
import PromiseKit

@objc public class ObacoService: NSObject {

    private let obacoDataSource: OBAJsonDataSource
    private let modelFactory = OBAModelFactory()

    @objc init(dataSource: OBAJsonDataSource) {
        self.obacoDataSource = dataSource
    }

    @objc public func cancelOpenConnections() {
        obacoDataSource.cancelOpenConnections()
    }

    deinit {
        obacoDataSource.cancelOpenConnections()
    }

    // MARK: - Weather

    /// Request the forecasted weather for the user's region and/or location.
    ///
    /// - Parameters:
    ///   - region: The user's current region
    ///   - location: An optional location used to determine more accurate weather data.
    /// - Returns: A promise wrapper that resolves to a WeatherForecast object.
    @objc public func requestWeather(in region: OBARegionV2, location: CLLocation?) -> PromiseWrapper {
        let request = buildURLRequestForWeather(in: region, location: location)
        let wrapper = PromiseWrapper(request: request, dataDecodingStrategy: .noStrategy)

        wrapper.promise = wrapper.promise.then { networkResponse -> NetworkResponse in
            // swiftlint:disable force_cast
            let forecast = try self.decodeWeather(data: networkResponse.object as! Data)
            // swiftlint:enable force_cast
            return NetworkResponse.init(object: forecast, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    private func decodeWeather(data: Data) throws -> WeatherForecast {
        let forecast = try WeatherForecast.decoder.decode(WeatherForecast.self, from: data)
        return forecast
    }

    private func buildURLRequestForWeather(in region: OBARegionV2, location: CLLocation?) -> OBAURLRequest {
        let path = "/api/v1/regions/\(region.identifier)/weather"

        var params: [AnyHashable: Any] = [:]
        if let location = location {
            params["lat"] = location.coordinate.latitude
            params["lng"] = location.coordinate.longitude
        }

        return obacoDataSource.buildGETRequest(withPath: path, queryParameters: params)
    }

    // MARK: - Alarms

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
            // swiftlint:disable force_cast
            let dict = networkResponse.object as! [String: Any]
            // swiftlint:enable force_cast

            if dict["error"] != nil {
                throw OBAErrorMessages.cannotRegisterAlarm
            }

            // swiftlint:disable force_cast
            let url = URL(string: dict["url"] as! String)!
            // swiftlint:enable force_cast

            return NetworkResponse.init(object: url, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    private func createAlarmRequest(_ alarm: OBAAlarm, userPushNotificationID: String) -> OBAURLRequest {
        let params: [String: Any] = [
            "seconds_before": alarm.timeIntervalBeforeDeparture,
            "stop_id": alarm.stopID,
            "trip_id": alarm.tripID,
            "service_date": alarm.serviceDate,
            "vehicle_id": alarm.vehicleID,
            "stop_sequence": alarm.stopSequence,
            "user_push_id": userPushNotificationID
        ]

        return obacoDataSource.buildRequest(withPath: "/api/v1/regions/\(alarm.regionIdentifier)/alarms", httpMethod: "POST", queryParameters: nil, formBody: params)
    }

    // MARK: - Vehicle Search

    /// Returns a PromiseWrapper that resolves to an array of `MatchingAgencyVehicle` objects,
    /// suitable for passing along to `requestVehicleTrip()`.
    ///
    /// - Parameter matching: A substring that must appear in all returned vehicles
    /// - Parameter region: The region from which to load all vehicle IDs
    /// - Returns: A `PromiseWrapper` that resolves to `[MatchingAgencyVehicle]`
    @objc public func requestVehicles(matching: String, in region: OBARegionV2) -> PromiseWrapper {
        let request = buildVehicleListRequest(matching: matching, region: region)
        let wrapper = PromiseWrapper(request: request, dataDecodingStrategy: .noStrategy)

        wrapper.promise = wrapper.promise.then { networkResponse -> NetworkResponse in
            let decoder = JSONDecoder()
            // swiftlint:disable force_cast
            let objects = try decoder.decode([MatchingAgencyVehicle].self, from: networkResponse.object as! Data)
            // swiftlint:enable force_cast

            if objects.count == 0 {
                throw OBAErrorMessages.vehicleNotFoundError
            }

            return NetworkResponse.init(object: objects, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    private func buildVehicleListRequest(matching: String, region: OBARegionV2) -> OBAURLRequest {
        let path = "/api/v1/regions/\(region.identifier)/vehicles"
        let url = obacoDataSource.constructURL(fromPath: path, params: ["query": matching])
        let obacoRequest = OBAURLRequest.init(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        return obacoRequest
    }

    /// Returns a PromiseWrapper that resolves to an OBATripDetailsV2 object.
    ///
    /// - Parameter vehicleID: The vehicle for which to retrieve trip details.
    /// - Returns: a PromiseWrapper that resolves to trip details.
    @objc public func requestVehicleTrip(_ vehicleID: String) -> PromiseWrapper {
        let request = buildTripForVehicleRequest(vehicleID)
        let wrapper = PromiseWrapper(request: request)

        wrapper.promise = wrapper.promise.then { response -> NetworkResponse in
            var error: NSError?
            // swiftlint:disable force_cast
            let entryWithRefs = self.modelFactory.getTripDetailsV2(fromJSON: response.object as! [AnyHashable: Any], error: &error)
            // swiftlint:enable force_cast
            if let error = error { throw error }

            // swiftlint:disable force_cast
            let tripDetails = entryWithRefs.entry as! OBATripDetailsV2
            // swiftlint:enable force_cast

            return NetworkResponse.init(object: tripDetails, response: response)
        }

        return wrapper
    }

    private func buildTripForVehicleRequest(_ vehicleID: String) -> OBAURLRequest {
        let encodedID = OBAURLHelpers.escapePathVariable(vehicleID)
        let path = "/api/where/trip-for-vehicle/\(encodedID).json"
        return obacoDataSource.buildGETRequest(withPath: path, queryParameters: nil)
    }
}
