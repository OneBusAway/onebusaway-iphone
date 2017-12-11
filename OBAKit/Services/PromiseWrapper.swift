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

    @objc init(request: URLRequest) {
        self.cancellablePromise = CancellablePromise.go(request: request)
        self.promise = cancellablePromise.then { response -> NetworkResponse in
            let obj = try! JSONSerialization.jsonObject(with: (response.object as! Data), options: [])
            return NetworkResponse.init(object: obj, URLResponse: response.URLResponse)
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

    public class func go(request: URLRequest) -> CancellablePromise {
        var fulfill: ((NetworkResponse) -> Void)?
        var reject: ((Error) -> Void)?

        let promise = CancellablePromise { f, r in
            fulfill = f
            reject  = r
        }

        promise.fulfill = fulfill
        promise.reject  = reject

        promise.task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                // Ostensibly the request was cancelled?
                return
            }

            if let error = error {
                if (error as NSError).code == NSURLErrorCancelled {
                    return
                }

                if httpResponse.statusCode == 404 {
                    promise.reject?(OBAErrorMessages.stopNotFoundError)
                }
                else if httpResponse.statusCode >= 300 && httpResponse.statusCode <= 399 {
                    promise.reject?(OBAErrorMessages.connectionError(httpResponse))
                }
                else {
                    promise.reject?(error)
                }

                return
            }

            guard let data = data else {
                promise.reject?(NSError(domain: "no-data", code: 0, userInfo: nil))
                return
            }

            let response = NetworkResponse.init(object: data, URLResponse: response as! HTTPURLResponse)
            promise.fulfill?(response)
        }
        promise.task?.resume()

        return promise
    }
}
