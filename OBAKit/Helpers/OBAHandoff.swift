//
//  OBAHandoff.swift
//  OBAKit
//
//  Created by Alan Chu on 1/6/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import Foundation

@objc public class OBAHandoff: NSObject {
    @objc static let shared = OBAHandoff()
    @objc static let activityType = "org.onebusaway.iphone.handoff"
    @objc static let stopIDKey = "stop_ID"
    @objc static let regionIDKey = "region_id"
    
    open internal(set) var activity: NSUserActivity! {
        didSet {
            activity.title = "OneBusAway"
            activity.isEligibleForHandoff = true
            activity.requiredUserInfoKeys = [OBAHandoff.stopIDKey, OBAHandoff.regionIDKey]
        }
    }
    
    override init() {
        activity = NSUserActivity(activityType: OBAHandoff.activityType)
    }
    
    /// Begin broadcasting the specified URL
    /// - parameter URL: URL to broadcast, if `nil`,
    /// this will stop broadcasting
    @objc open func broadcast(_ URL: URL?) {
        activity.webpageURL = URL
        activity.becomeCurrent()
    }
    
    /// Begin broadcasting the specified stop using its stop ID
    ///
    /// - Parameters:
    ///   - stop: Stop ID to broadcast
    ///   - region: The OBARegionV2 object associated with the specified stopID
    @objc open func broadcast(stopID stop: String, withRegion region: OBARegionV2) {
        let userInfo: [AnyHashable: Any] = [
            OBAHandoff.stopIDKey: stop,
            OBAHandoff.regionIDKey: region.identifier
        ]
        activity.userInfo = userInfo
        activity.becomeCurrent()
    }
    
    /// Stop broadcasting to other devices.
    @objc open func stopBroadcasting() {
        activity.userInfo = nil
        activity.webpageURL = nil
        activity.resignCurrent()
    }
}
