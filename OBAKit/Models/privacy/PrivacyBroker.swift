//
//  PrivacyBroker.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/2/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import UIKit

@objc public protocol PrivacyBrokerDelegate {
    func addPersonBool(_ value: Bool, withKey: String)
    func addPersonNumber(_ value: NSNumber, withKey: String)
    func addPersonString(_ value: String, withKey: String)
    func removePersonKey(_ key: String)
}

let RegionNameKey = "region_name"
let RegionIdentifierKey = "region_identifier"
let RegionURLKey = "region_base_api_url"

/// PrivacyBroker is responsible for determining what data the
/// application is allowed to share for support purposes.
public class PrivacyBroker: NSObject {
    let modelDAO: OBAModelDAO
    let locationManager: OBALocationManager

    public init(modelDAO: OBAModelDAO, locationManager: OBALocationManager) {
        self.modelDAO = modelDAO
        self.locationManager = locationManager
    }

    // MARK: - Region Information

    public var canShareRegionInformation: Bool {
        get {
            return self.modelDAO.shareRegionPII
        }
    }

    public func toggleShareRegionInformation() {
        self.modelDAO.shareRegionPII = !self.modelDAO.shareRegionPII
    }

    // TODO: this is gross and prone to error.
    // Clean it up to have only a single return statement.
    public func shareableRegionInformation() -> [String: String] {
        if !self.canShareRegionInformation {
            return [
                RegionNameKey: "",
                RegionIdentifierKey: "",
                RegionURLKey: ""
            ]
        }

        guard let currentRegion = self.modelDAO.currentRegion else {
            return [
                RegionNameKey: "",
                RegionIdentifierKey: "",
                RegionURLKey: ""
            ]
        }

        return [
            RegionNameKey: currentRegion.regionName,
            RegionIdentifierKey: String(currentRegion.identifier),
            RegionURLKey: currentRegion.baseURL!.absoluteString
        ]
    }

    // MARK: - Location Information

    public var canShareLocationInformation: Bool {
        get {
            return self.modelDAO.shareLocationPII
        }
    }

    public var shareableLocationInformation: String? {
        get {
            if !self.canShareLocationInformation {
                return nil
            }

            guard let loc = self.locationManager.currentLocation else {
                return nil
            }

            return "(\(loc.coordinate.latitude), \(loc.coordinate.longitude))"
        }
    }

    public func toggleShareLocationInformation() {
        self.modelDAO.shareLocationPII = !self.modelDAO.shareLocationPII
    }

    // MARK: - User Data

    public weak var delegate: PrivacyBrokerDelegate?

    public func reportUserData(notificationsStatus: Bool) {
        // Information that cannot be used to uniquely identify the user is shared automatically.
        self.reportNonPIIData(notificationsStatus)

        // Information that can be used to uniquely identify the user is not shared automatically.
        self.reportPIIData()
    }

    /// Information that cannot be used to uniquely identify the user is shared automatically.
    private func reportNonPIIData(_ notificationsStatus: Bool) {
        self.delegate?.addPersonBool(self.modelDAO.automaticallySelectRegion, withKey: "Automatically Select Region")
        self.delegate?.addPersonBool(self.modelDAO.currentRegion != nil, withKey: "Region Selected")
        self.delegate?.addPersonString(locationAuthorizationStatusToString(self.locationManager.authorizationStatus), withKey: "Location Auth Status")
        self.delegate?.addPersonBool(notificationsStatus, withKey: "Registered for Notifications")

        self.delegate?.addPersonNumber(NSNumber.init(value: self.modelDAO.bookmarksForCurrentRegion.count), withKey: "Bookmarks (Region)")
        self.delegate?.addPersonNumber(NSNumber.init(value: self.modelDAO.allBookmarksCount), withKey: "Bookmarks (All)")
    }


    /// Information that can be used to uniquely identify the user is not shared automatically.
    private func reportPIIData() {
        if let location = self.shareableLocationInformation {
            self.delegate?.addPersonString(location, withKey: "Location")
        }
        else {
            self.delegate?.removePersonKey("Location")
        }

        let regionInfo = self.shareableRegionInformation()
        for (key, value) in regionInfo {
            if self.canShareRegionInformation {
                self.delegate?.addPersonString(value, withKey: key)
            }
            else {
                self.delegate?.removePersonKey(key)
            }
        }
    }

    // MARK: - Logging Information

    public var canShareLogs: Bool {
        get {
            return self.modelDAO.shareLogsPII
        }
    }

    public var shareableLogData: [Data] {
        get {
            if !self.canShareLogs {
                return []
            }

            return OBAApplication.shared().logFileData
        }
    }

    public func toggleShareLogs() {
        self.modelDAO.shareLogsPII = !self.modelDAO.shareLogsPII
    }
}
