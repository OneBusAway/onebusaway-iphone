//
//  PromiseWrapper.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 12/9/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import Foundation
import PromiseKit

@objc public class PromiseWrapper: NSObject {
    private let cancellablePromise: CancellablePromise
    public var promise: Promise<NetworkResponse>

    @objc init(request: OBAURLRequest) {
        self.cancellablePromise = CancellablePromise.go(request: request)
        self.promise = self.cancellablePromise.then { response -> NetworkResponse in
            let checkCode = response.urlRequest.checkStatusCodeInBody // abxoxo - can all this stuff be replaced with request.checkStatusCodeInBody?
            var jsonObject = try! JSONSerialization.jsonObject(with: (response.object as! Data), options: []) as AnyObject
            var httpResponse = response.URLResponse

            if checkCode && jsonObject.responds(to: #selector(self.value(forKey:))) {
                let statusCode = (jsonObject.value(forKey: "code") as! NSNumber).intValue
                httpResponse = HTTPURLResponse.init(url: httpResponse.url!, statusCode: statusCode, httpVersion: nil, headerFields: httpResponse.allHeaderFields as? [String : String])!
                jsonObject = jsonObject.value(forKey: "data") as AnyObject
            }

            if let error = OBAErrorMessages.error(fromHttpResponse: httpResponse) {
                throw error
            }

            return NetworkResponse.init(object: jsonObject, URLResponse: httpResponse, urlRequest: response.urlRequest)
        }
    }

    @objc func anyPromise() -> AnyPromise {
        return AnyPromise(self.promise)
    }

    @objc func cancel() {
        cancellablePromise.cancel()
    }
}

class CancellablePromise: Promise<NetworkResponse> {
    private var task: URLSessionDataTask?
    private var fulfill: ((NetworkResponse) -> Void)?
    private var reject: ((Error) -> Void)?
    public private(set) var urlRequest: OBAURLRequest?

    required public init(resolvers: (@escaping (NetworkResponse) -> Swift.Void, @escaping (Error) -> Swift.Void) throws -> Swift.Void) {
        super.init(resolvers: resolvers)
    }

    required init(error: Error) {
        fatalError("init(error:) has not been implemented")
    }

    required init(value: NetworkResponse) {
        fatalError("init(value:) has not been implemented")
    }

    public func cancel() {
        guard !self.isRejected else { return }
        self.task?.cancel()
        self.reject?(NSError.cancelledError())
    }

    public class func go(request: OBAURLRequest) -> CancellablePromise {
        var fulfill: ((NetworkResponse) -> Void)?
        var reject: ((Error) -> Void)?

        let promise = CancellablePromise { f, r in
            fulfill = f
            reject  = r
        }

        promise.urlRequest = request

        promise.fulfill = fulfill
        promise.reject  = reject

        promise.task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                // Ostensibly the request was cancelled?
                return
            }

            if let error = error {
                if (error as NSError).code == NSURLErrorCancelled {
                    return
                }

                let error = OBAErrorMessages.error(fromHttpResponse: httpResponse) ?? error
                promise.reject?(error)

                return
            }

            guard let data = data else {
                promise.reject?(NSError(domain: "no-data", code: 0, userInfo: nil))
                return
            }

            let response = NetworkResponse.init(object: data, URLResponse: response as! HTTPURLResponse, urlRequest: request)
            promise.fulfill?(response)
        }
        promise.task?.resume()

        return promise
    }
}
