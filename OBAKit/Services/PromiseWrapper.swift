//
//  PromiseWrapper.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 12/9/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

// swiftlint:disable force_cast

import Foundation
import PromiseKit

@objc public class PromiseWrapper: NSObject {

    public enum DataDecodingStrategy {
        case noStrategy, parseJSON
    }
    public private(set) var dataDecodingStrategy: DataDecodingStrategy

    private let cancellablePromise: CancellablePromise
    public var promise: Promise<NetworkResponse>

    @objc convenience init(request: OBAURLRequest) {
        self.init(request: request, dataDecodingStrategy: .parseJSON)
    }

    init(request: OBAURLRequest, dataDecodingStrategy: DataDecodingStrategy) {
        self.dataDecodingStrategy = dataDecodingStrategy
        self.cancellablePromise = CancellablePromise.go(request: request)
        self.promise = self.cancellablePromise.then { response -> NetworkResponse in
            var jsonObject: AnyObject?
            let checkCode = response.urlRequest.checkStatusCodeInBody
            var httpResponse = response.URLResponse

            if dataDecodingStrategy == .parseJSON {
                jsonObject = try PromiseWrapper.parseJSON(response: response)

                if checkCode,
                   let outerJSON = jsonObject,
                   outerJSON.responds(to: #selector(self.value(forKey:))) {
                     let statusCode = (outerJSON.value(forKey: "code") as! NSNumber).intValue
                     httpResponse = HTTPURLResponse.init(url: httpResponse.url!, statusCode: statusCode, httpVersion: nil, headerFields: httpResponse.allHeaderFields as? [String: String])!
                     jsonObject = outerJSON.value(forKey: "data") as AnyObject
                }

                // post-munge
                if let error = OBAErrorMessages.error(fromHttpResponse: httpResponse) {
                    throw error
                }
            }

            return NetworkResponse.init(object: jsonObject ?? response.object, URLResponse: httpResponse, urlRequest: response.urlRequest)
        }
    }

    private static func parseJSON(response: NetworkResponse) throws -> AnyObject {
        var jsonObject: AnyObject

        do {
            jsonObject = try JSONSerialization.jsonObject(with: (response.object as! Data), options: []) as AnyObject
        }
        catch {
            DDLogError("Unable to parse response body for request: \(response.urlRequest)")
            throw OBAErrorMessages.error(fromHttpResponse: response.URLResponse) ?? OBAErrorMessages.unknownError(from: response.URLResponse)
        }

        // pre-munge
        if let error = OBAErrorMessages.error(fromHttpResponse: response.URLResponse) {
            throw error
        }

        return jsonObject
    }

    // MARK: - Public Helpers

    @objc public var anyPromise: AnyPromise {
        return AnyPromise(self.promise)
    }

    @objc public func cancel() {
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
