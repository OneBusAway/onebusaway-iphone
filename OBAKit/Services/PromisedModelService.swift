//
//  PromisedModelService.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 11/5/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import Foundation
import PromiseKit

@objc public class PromisedModelService: OBAModelService {

    /// Retrieves a list of alert messages for the specified `region` since `date`.
    ///
    /// - Parameters:
    ///   - region: The region from which alerts are desired
    ///   - sinceDate: The last date that alerts were requested. Specify nil for all time.
    /// - Returns: A promise that resolves to [OBARegionalAlert]
    public func regionalAlerts(region: OBARegionV2, sinceDate: Date?) -> Promise<[OBARegionalAlert]> {
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
}
