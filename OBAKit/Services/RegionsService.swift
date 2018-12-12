//
//  RegionsService.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 9/26/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import Foundation
import PromiseKit

@objc(OBARegionsService)
public class RegionsService: NSObject {
    private let regionsDataSource: OBAJsonDataSource
    private let modelFactory = OBAModelFactory()

    @objc init(regionsDataSource: OBAJsonDataSource) {
        self.regionsDataSource = regionsDataSource
    }

    @objc public func cancelOpenConnections() {
        regionsDataSource.cancelOpenConnections()
    }

    deinit {
        regionsDataSource.cancelOpenConnections()
    }

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
        var error: NSError?
        let listWithRangeAndReferences = modelFactory.getRegionsV2(fromJson: json, error: &error)

        if let error = error {
            throw error
        }

        if let regions = listWithRangeAndReferences.values as? [OBARegionV2] {
            return regions
        }
        else {
            throw NSError(domain: OBAErrorDomain, code: Int(OBAErrorCode.badData.rawValue), userInfo: nil)
        }
    }

    private func buildURLRequestForRegions() -> OBAURLRequest {
        let path = "/regions-v3.json"
        return regionsDataSource.buildGETRequest(withPath: path, queryParameters: nil)
    }
}
