//
//  OBAHandoff.swift
//  OBAKit
//
//  Created by Alan Chu on 1/6/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import Foundation

class OBAHandoff: NSObject {
    static let shared = OBAHandoff()
    static let activityType = "org.onebusaway.iphone.handoff"
    static let stopIDKey = "stop_ID"
    static let regionIDKey = "region_id"
    
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
    /// - parameter url: URL to broadcast, if `nil`, 
    /// this will stop broadcasting
    open func broadcast(url link: URL?) {
        activity.webpageURL = link
        activity.becomeCurrent()
    }
    
    /// Begin broadcasting the specified stop using its stop ID
    /// - parameter stop: Stop ID to broadcast
    /// - parameter region: `OBARegionV2` associated with the specified `stopID`
    open func broadcast(stopID stop: String, withRegion region: OBARegionV2) {
        let userInfo: [AnyHashable: Any] = [
            OBAHandoff.stopIDKey: stop,
            OBAHandoff.regionIDKey: region.identifier
        ]
        activity.userInfo = userInfo
        activity.becomeCurrent()
    }
    
    /// Stop broadcasting to other devices.
    open func stopBroadcasting() {
        activity.userInfo = nil
        activity.webpageURL = nil
        activity.resignCurrent()
    }
}
