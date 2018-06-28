//
//  AgencyAlert.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 6/12/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import Foundation

@objc(OBAAgencyAlert) public class AgencyAlert: NSObject {
    private let alert: TransitRealtime_Alert

    @objc public let id: String

    // MARK: - Agency

    @objc public let agencyID: String

    private static func findAgencyInList(list: [TransitRealtime_EntitySelector]) -> TransitRealtime_EntitySelector? {
        for sel in list {
            if sel.hasAgencyID {
                return sel
            }
        }
        return nil
    }

    @objc public let agency: OBAAgencyWithCoverageV2?

    // MARK: - Translation Properties

    private lazy var urlTranslations: [String: String] = {
        return alert.url.translation.reduce(into: [:]) { (acc, translation) in
            acc[translation.language] = translation.text
        }
    }()

    private lazy var titleTranslations: [String: String] = {
        return alert.headerText.translation.reduce(into: [:]) { (acc, translation) in
            acc[translation.language] = translation.text
        }
    }()

    private lazy var bodyTranslations: [String: String] = {
        return alert.descriptionText.translation.reduce(into: [:]) { (acc, translation) in
            acc[translation.language] = translation.text
        }
    }()

    // MARK: - Initialization

    init(feedEntity: TransitRealtime_FeedEntity, agencies: [OBAAgencyWithCoverageV2]) throws {
        guard
            feedEntity.hasAlert,
            AgencyAlert.isAgencyWideAlert(alert: feedEntity.alert),
            let gtfsAgency = AgencyAlert.findAgencyInList(list: feedEntity.alert.informedEntity),
            gtfsAgency.hasAgencyID
        else {
            throw AlertError.invalidAlert
        }
        self.alert = feedEntity.alert
        self.id = feedEntity.id
        self.agencyID = gtfsAgency.agencyID
        self.agency = agencies.first { $0.agencyId == gtfsAgency.agencyID }
    }
}

// MARK: - Errors
extension AgencyAlert {
    enum AlertError: Error {
        case invalidAlert
    }
}

// MARK: - Timeframes
extension AgencyAlert {
    @objc public var startDate: Date? {
        guard
            let period = alert.activePeriod.first,
            period.hasStart
        else {
            return nil
        }

        return Date(timeIntervalSince1970: TimeInterval(period.start))
    }

    @objc public var endDate: Date? {
        guard
            let period = alert.activePeriod.first,
            period.hasEnd
            else {
                return nil
        }

        return Date(timeIntervalSince1970: TimeInterval(period.end))
    }
}

// MARK: - Translated Text
extension AgencyAlert {
    @objc public func url(language: String) -> URL? {
        guard
            alert.hasURL,
            let urlString = translation(key: language, from: urlTranslations)
        else {
            return nil
        }

        return URL(string: urlString)
    }

    @objc public func title(language: String) -> String? {
        guard alert.hasHeaderText else {
            return nil
        }

        return translation(key: language, from: titleTranslations)
    }

    @objc public func body(language: String) -> String? {
        guard alert.hasDescriptionText else {
            return nil
        }

        return translation(key: language, from: bodyTranslations)
    }

    private func translation(key: String, from map: [String: String]) -> String? {
        if let translation = map[key] {
            return translation
        }

        // If we don't have the desired translation, first check
        // to see if we have a default translation language value
        // present. For now this is English.
        if let translation = map["en"] {
            return translation
        }

        // If that doesn't work out and we don't have our
        // desired language or default language, then just
        // return whatever we can get our hands on.
        if let key = map.keys.first {
            return map[key]
        }
        else {
            return nil
        }
    }
}

// MARK: - Static Helpers
extension AgencyAlert {
    static func isAgencyWideAlert(alert: TransitRealtime_Alert) -> Bool {
        for sel in alert.informedEntity {
            if sel.hasAgencyID {
                return true
            }
        }

        return false
    }
}
