//
//  OBAHandoff.swift
//  OBAKit
//
//  Created by Alan Chu on 1/6/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import Foundation

@objc public class OBAHandoff: NSObject {
    @objc static let activityTypeStop = "org.onebusaway.iphone.handoff.stop"
    @objc static let activityTypeTripURL = "org.onebusaway.iphone.handoff.tripurl"
    @objc static let stopIDKey = "stopID"
    @objc static let regionIDKey = "regionID"

    @objc
    public class func createUserActivity(name: String, stopID: String, regionID: Int) -> NSUserActivity {
        let activity = NSUserActivity(activityType: OBAHandoff.activityTypeStop)
        activity.title = name
        activity.isEligibleForHandoff = true

        // Per WWDC 2018 Session "Intro to Siri Shortcuts", this must be set to `true`
        // for `isEligibleForPrediction` to have any effect. Timecode: 8:30
        activity.isEligibleForSearch = true

        if #available(iOS 12.0, *) {
            activity.isEligibleForPrediction = true
        }

        activity.requiredUserInfoKeys = [OBAHandoff.stopIDKey, OBAHandoff.regionIDKey]
        activity.userInfo = [OBAHandoff.stopIDKey: stopID, OBAHandoff.regionIDKey: regionID]

        let deepLinkRouter = DeepLinkRouter(baseURL: URL(string: OBADeepLinkServerAddress)!)
        activity.webpageURL = deepLinkRouter.deepLinkURL(stopID: stopID, regionID: regionID)

        return activity
    }

    @objc
    public class func createUserActivityForTrip(name: String, URL: URL) -> NSUserActivity {
        let activity = NSUserActivity(activityType: OBAHandoff.activityTypeTripURL)
        activity.title = name
        activity.isEligibleForHandoff = true

        activity.webpageURL = URL

        return activity
    }
}
