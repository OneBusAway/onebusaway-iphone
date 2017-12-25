//
//  OBAURLRequest.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 12/25/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import Foundation

@objc public class OBAURLRequest: NSMutableURLRequest {
    @objc public var checkStatusCodeInBody: Bool = false

    @objc public class func request(URL: URL, httpMethod: String, checkStatusCodeInBody: Bool) -> OBAURLRequest {
        let request = OBAURLRequest.init(url: URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 15)
        request.checkStatusCodeInBody = checkStatusCodeInBody
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.httpMethod = httpMethod

        return request
    }
}
