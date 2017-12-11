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

    init(object: Any, URLResponse: HTTPURLResponse) {
        self.object = object
        self.URLResponse = URLResponse
    }
}
