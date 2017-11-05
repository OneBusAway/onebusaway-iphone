//
//  RegionalAlertsManager.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 3/16/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import Foundation
import CocoaLumberjack
import CocoaLumberjackSwift

/*
 1. There needs to be a way to separately broadcast information about high priority alerts.
 2. [DONE] Alerts need to have idea of priority. High priority (HPA) and normal.
 3. [DONE] Alerts need to have idea of read/unread state.
 4. HPAs should be displayed immediately upon receipt.
 5. HPAs should only be displayed once. This can probably be accomplished by 3.
 6. [DONE] Read/unread state should not be overwritten as new data is downloaded from the server.
 */

@objc public class RegionalAlertsManager: NSObject {
    private let lastUpdateKey = "OBALastRegionalAlertsUpdateKey"
    @objc private(set) public var regionalAlerts: [OBARegionalAlert] = []
    private let alertsUpdateQueue = DispatchQueue(label: "regional-alerts-manager-update")

    @objc public var region: OBARegionV2? {
        didSet {
            self.regionalAlerts = self.loadDefaultData() ?? []
        }
    }

    lazy var modelService: PromisedModelService = {
        return OBAApplication.shared().modelService
    }()

    @objc public var unreadCount: UInt {
        return UInt(self.regionalAlerts.filter({ $0.unread }).count)
    }

    // MARK: - Mark Read

    public func markRead(_ alert: OBARegionalAlert) {
        self.markRead(alert, synchronous: true)
    }

    private func markRead(_ alert: OBARegionalAlert, synchronous: Bool) {
        let op = {
            var alerts = self.regionalAlerts
            guard let idx = alerts.index(of: alert) else {
                return
            }
            let canonicalAlert = alerts[idx]
            canonicalAlert.unread = false
            alerts[idx] = canonicalAlert

            self.regionalAlerts = alerts
            _ = self.writeDefaultData(alerts)
        }

        if synchronous {
            self.alertsUpdateQueue.sync(execute: op)
        }
        else {
            op()
        }
    }

    public func markAllAsRead() {
        self.alertsUpdateQueue.sync {
            let alerts = self.regionalAlerts
            alerts.forEach { $0.unread = false }
            self.regionalAlerts = alerts
            _ = self.writeDefaultData(alerts)
        }
    }

    // MARK: - Remote Data Updating

    private let updateLock = NSLock.init()

    /// Loads alerts for the currently selected region.
    @objc public func update() {
        guard let region = self.region else {
            return
        }

        // Protect access to the update() method.
        if !self.updateLock.try() {
            return
        }

        let lastUpdate = self.regionalAlerts.count == 0 ? nil : OBAApplication.shared().userDefaults.object(forKey: lastUpdateKey) as? Date

        self.modelService.regionalAlerts(region: region, sinceDate: lastUpdate).then { alerts -> Void in
            self.alertsUpdateQueue.sync {
                if alerts.count > 0 {
                    self.regionalAlerts = RegionalAlertsManager.merge(models: self.regionalAlerts, withNewModels: alerts)
                    if self.writeDefaultData(self.regionalAlerts) {
                        OBAApplication.shared().userDefaults.set(NSDate(), forKey: self.lastUpdateKey)
                        self.broadcastUpdateNotification()
                    }
                    self.postNotificationForHighPriorityAlerts(alerts)
                }
            }
        }.catch { error in
            DDLogError("Unable to retrieve regional alerts: \(error)")
        }.always {
            self.updateLock.unlock()
        }
    }

    static func merge(models: [OBARegionalAlert], withNewModels newModels: [OBARegionalAlert]) -> [OBARegionalAlert] {
        var mergedModels: [OBARegionalAlert] = []

        var modelMap: [String: OBARegionalAlert] = models.reduce([String: OBARegionalAlert]()) { acc, alert in
            var ret = acc
            ret[String(alert.identifier)] = alert
            return ret
        }

        newModels.forEach { alert in
            if let match = modelMap[String(alert.identifier)] {
                // exists; merge.
                match.mergeValuesForKeys(from: alert)
            }
            else {
                // doesn't exist. just add it.
                mergedModels.append(alert)
            }
        }

        mergedModels.append(contentsOf: modelMap.values)

        mergedModels.sort { (alert1, alert2) -> Bool in
            let date1 = alert1.publishedAt ?? Date()
            let date2 = alert2.publishedAt ?? Date()

            return date1 >= date2
        }

        return mergedModels
    }

    // MARK: - Notifications

    @objc public static let regionalAlertsUpdatedNotification = NSNotification.Name("regionalAlertsUpdatedNotification")
    @objc public static let highPriorityRegionalAlertReceivedNotification = NSNotification.Name("highPriorityRegionalAlertReceivedNotification")
    @objc public static let highPriorityRegionalAlertUserInfoKey = "HighPriorityRegionalAlertUserInfoKey"

    private func broadcastUpdateNotification() {
        NotificationCenter.default.post(name: RegionalAlertsManager.regionalAlertsUpdatedNotification, object: self)
    }

    private func postNotificationForHighPriorityAlerts(_ alerts: [OBARegionalAlert]) {
        let matches = alerts.filter { (alert: OBARegionalAlert) in
            return alert.priority == .high && alert.unread
        }

        guard let alert = matches.first else {
            return
        }

        self.markRead(alert, synchronous: false)

        self.broadcastHighPriorityNotification(for: alert)
    }

    private func broadcastHighPriorityNotification(for alert: OBARegionalAlert) {
        NotificationCenter.default.post(name: RegionalAlertsManager.highPriorityRegionalAlertReceivedNotification, object: self, userInfo: [RegionalAlertsManager.highPriorityRegionalAlertUserInfoKey: alert])
    }

    // MARK: - Local/Default Data

    private func loadDefaultData() -> [OBARegionalAlert]? {
        guard let path = self.defaultDataFilePathForCurrentRegion(),
              let defaultData = FileManager.default.contents(atPath: path),
              let jsonObject = try? JSONSerialization.jsonObject(with: defaultData, options: []),
              let models = try? MTLJSONAdapter.models(of: OBARegionalAlert.self, fromJSONArray: jsonObject as! [Any])
        else {
            return nil
        }

        return models as? [OBARegionalAlert]
    }

    private func writeDefaultData(_ alerts: [OBARegionalAlert]) -> Bool {
        do {
            let JSONArray = try MTLJSONAdapter.jsonArray(fromModels: regionalAlerts)
            let data = try JSONSerialization.data(withJSONObject: JSONArray, options: [])
            guard let filePath = self.defaultDataFilePathForCurrentRegion() else {
                return false
            }

            return (data as NSData).write(toFile: filePath, atomically: true)
        }
        catch {
            DDLogError("Caught an error while writing regional alert data to disk: \(error)")
            return false
        }
    }

    private func defaultDataFilePathForCurrentRegion() -> String? {
        guard let region = self.region else {
            return nil
        }

        return FileHelpers.pathTo(fileName: "region_alerts_\(region.identifier).json", inDirectory: .cachesDirectory)
    }
}
