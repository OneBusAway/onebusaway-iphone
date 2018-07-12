//
//  NetworkResponse.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 12/10/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import Foundation

@objc public class NetworkResponse: NSObject {
    @objc public var object: Any
    @objc public var URLResponse: HTTPURLResponse
    @objc public var urlRequest: OBAURLRequest

    init(object: Any, URLResponse: HTTPURLResponse, urlRequest: OBAURLRequest) {
        self.object = object
        self.URLResponse = URLResponse
        self.urlRequest = urlRequest
    }

    convenience init(object: Any, response: NetworkResponse) {
        self.init(object: object, URLResponse: response.URLResponse, urlRequest: response.urlRequest)
    }
}
