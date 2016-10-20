//
//  PrivacyBroker.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/2/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import UIKit

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
