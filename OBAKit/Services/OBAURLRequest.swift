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

        if let lastModified = OBAURLRequest.cachedLastModifiedValue(for: request) {
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }

        if let etag = OBAURLRequest.cachedEtagValue(for: request) {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.httpMethod = httpMethod

        return request
    }

    private static func cachedLastModifiedValue(for request: OBAURLRequest) -> String? {
        guard
            let cachedResponse = URLCache.shared.cachedResponse(for: request as URLRequest),
            let httpResponse = cachedResponse.response as? HTTPURLResponse,
            let lastModified = httpResponse.allHeaderFields["Last-Modified"] as? String
        else {
            return nil
        }

        return lastModified
    }

    private static func cachedEtagValue(for request: OBAURLRequest) -> String? {
        guard
            let cachedResponse = URLCache.shared.cachedResponse(for: request as URLRequest),
            let httpResponse = cachedResponse.response as? HTTPURLResponse
            else {
                return nil
        }

        if let etag = httpResponse.allHeaderFields["ETag"] as? String {
            return etag
        }

        // It appears that there are occasions where the string "ETag"
        // is miscapitalized in response headers to us in contravention
        // of RFC 7232: https://tools.ietf.org/html/rfc7232#section-2.3
        if let etag = httpResponse.allHeaderFields["Etag"] as? String {
            return etag
        }

        return nil
    }
}
