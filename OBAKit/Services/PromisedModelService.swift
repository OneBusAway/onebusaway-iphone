//
//  PromisedModelService.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 11/5/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import PromiseKit

// swiftlint:disable force_cast

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

    @objc public func buildURLRequestForStopArrivalsAndDepartures(withID stopID: String, minutesBefore: UInt, minutesAfter: UInt) -> OBAURLRequest {
        let args = ["minutesBefore": minutesBefore, "minutesAfter": minutesAfter]
        let escapedStopID = OBAURLHelpers.escapePathVariable(stopID)
        let path = String.init(format: "/api/where/arrivals-and-departures-for-stop/%@.json", escapedStopID)

        return obaJsonDataSource.buildGETRequest(withPath: path, queryParameters: args)
    }

    private func decodeStopArrivals(json: Any) throws -> OBAArrivalsAndDeparturesForStopV2 {
        var error: NSError?

        let modelObjects = modelFactory.getArrivalsAndDeparturesForStopV2(fromJSON: json as! [AnyHashable: Any], error: &error)
        if let error = error {
            throw error
        }

        return modelObjects
    }
}

// MARK: - Trip Details
@objc extension PromisedModelService {
    /// Trip details for the specified OBATripInstanceRef
    ///
    /// - Parameter tripInstance: The trip instance reference
    /// - Returns: A PromiseWrapper that resolves to an instance of OBATripDetailsV2
    public func requestTripDetails(tripInstance: OBATripInstanceRef) -> PromiseWrapper {
        let request = self.buildTripDetailsRequest(tripInstance: tripInstance)
        let wrapper = PromiseWrapper.init(request: request)

        wrapper.promise = wrapper.promise.then { networkResponse -> NetworkResponse in
            let tripDetails = try self.decodeTripDetails(json: networkResponse.object as! [AnyHashable: Any])
            return NetworkResponse.init(object: tripDetails, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    @nonobjc private func decodeTripDetails(json: [AnyHashable: Any]) throws -> OBATripDetailsV2 {
        var error: NSError?
        let model = modelFactory.getTripDetailsV2(fromJSON: json, error: &error)

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

        return obaJsonDataSource.buildGETRequest(withPath: "/api/where/trip-details/\(escapedTripID).json", queryParameters: args)
    }

    /// Returns a PromiseWrapper that resolves to an OBATripDetailsV2 object.
    ///
    /// - Parameter vehicleID: The vehicle for which to retrieve trip details.
    /// - Returns: a PromiseWrapper that resolves to trip details.
    public func requestVehicleTrip(_ vehicleID: String) -> PromiseWrapper {
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
        return obaJsonDataSource.buildGETRequest(withPath: path, queryParameters: nil)
    }
}

// MARK: - Agencies with Coverage
@objc extension PromisedModelService {
    public func requestAgenciesWithCoverage() -> PromiseWrapper {
        let request = buildRequest()
        let wrapper = PromiseWrapper.init(request: request)

        wrapper.promise = wrapper.promise.then { networkResponse -> NetworkResponse in
            // swiftlint:disable force_cast
            let agencies = try self.decodeData(json: networkResponse.object as! [AnyHashable: Any])
            // swiftlint:enable force_cast
            return NetworkResponse.init(object: agencies, URLResponse: networkResponse.URLResponse, urlRequest: networkResponse.urlRequest)
        }

        return wrapper
    }

    @nonobjc private func buildRequest() -> OBAURLRequest {
        return obaJsonDataSource.buildGETRequest(withPath: "/api/where/agencies-with-coverage.json", queryParameters: nil)
    }

    @nonobjc private func decodeData(json: [AnyHashable: Any]) throws -> [OBAAgencyWithCoverageV2] {
        var error: NSError?
        let listWithRange = modelFactory.getAgenciesWithCoverageV2(fromJson: json, error: &error)

        if let error = error {
            throw error
        }

        // swiftlint:disable force_cast
        let entries = listWithRange.values as! [OBAAgencyWithCoverageV2]
        // swiftlint:enable force_cast
        return entries
    }
}

// MARK: - Regional Alerts
extension PromisedModelService {
    public func requestRegionalAlerts() -> Promise<[AgencyAlert]> {
        return requestAgenciesWithCoverage().promise.then { networkResponse -> Promise<[AgencyAlert]> in
            // swiftlint:disable force_cast
            let agencies = networkResponse.object as! [OBAAgencyWithCoverageV2]
            // swiftlint:enable force_cast
            var requests = agencies.map { self.buildRequest(agency: $0) }

            let obacoRequest = self.buildObacoRequest(region: self.modelDAO.currentRegion!)
            requests.append(obacoRequest)

            let promises = requests.map { request -> Promise<[TransitRealtime_FeedEntity]> in
                return CancellablePromise.go(request: request).then { networkResponse -> Promise<[TransitRealtime_FeedEntity]> in
                    // swiftlint:disable force_cast
                    let data = networkResponse.object as! Data
                    // swiftlint:enable force_cast
                    let message = try TransitRealtime_FeedMessage(serializedData: data)
                    return Promise(value: message.entity)
                }
            }

            return when(fulfilled: promises).then { nestedEntities in
                let allAlerts: [AgencyAlert] = nestedEntities.reduce(into: [], { (acc, entities) in
                    let alerts = entities.filter { (entity) -> Bool in
                        return entity.hasAlert && AgencyAlert.isAgencyWideAlert(alert: entity.alert)
                    }.compactMap { try? AgencyAlert(feedEntity: $0, agencies: agencies) }
                    acc.append(contentsOf: alerts)
                })
                return Promise(value: allAlerts)
            }
        }
    }

    private func buildObacoRequest(region: OBARegionV2) -> OBAURLRequest {
        var params: [String: Any]?
        if OBAApplication.shared().userDefaults.bool(forKey: OBAShowTestAlertsDefaultsKey) {
            params = ["test": "1"]
        }
        let url = obacoJsonDataSource.constructURL(fromPath: "/api/v1/regions/\(region.identifier)/alerts.pb", params: params)
        let obacoRequest = OBAURLRequest.init(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        return obacoRequest
    }

    private func buildRequest(agency: OBAAgencyWithCoverageV2) -> OBAURLRequest {
        let encodedID = OBAURLHelpers.escapePathVariable(agency.agencyId)
        let path = "/api/gtfs_realtime/alerts-for-agency/\(encodedID).pb"
        return unparsedDataSource.buildGETRequest(withPath: path, queryParameters: nil)
    }
}
