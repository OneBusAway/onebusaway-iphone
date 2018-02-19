//
//  TodayViewController.swift
//  OneBusAway Today
//
//  Created by Aaron Brethorst on 10/5/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import UIKit
import NotificationCenter
import OBAKit
import Fabric
import Crashlytics

let kMinutes: UInt = 60

class TodayViewController: OBAStaticTableViewController {
    let app = OBAApplication.init()
    let deepLinkRouter = OBADeepLinkRouter.init(deepLinkBaseURL: URL.init(string: OBADeepLinkServerAddress)!)
    var group: OBABookmarkGroup = OBABookmarkGroup.init(bookmarkGroupType: .todayWidget)
    var lastUpdateRow: OBABaseRow?

    // MARK: - Init/View Controller Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Fabric.with([Crashlytics.self])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded

        self.emptyDataSetVerticalOffset = 0
        self.emptyDataSetTitle = NSLocalizedString("today_screen.no_data_title", comment: "No Bookmarks - empty data set title.")
        self.emptyDataSetDescription = NSLocalizedString("today_screen.no_data_description", comment: "Add bookmarks to Today Screen Bookmarks to see them here. - empty data set description.")

        let configuration = OBAApplicationConfiguration.init()
        configuration.extensionMode = true
        app.start(with: configuration)
    }
}

// MARK: - Widget Protocol
extension TodayViewController: NCWidgetProviding {

    func updateData(completionHandler: ((NCUpdateResult) -> Void)?) {
        self.group = app.modelDao.todayBookmarkGroup

        if (self.group.bookmarks.count == 0) {
            completionHandler?(NCUpdateResult.noData)
            return
        }

        self.sections = [buildLastUpdatedSection(), buildTableSection(group: self.group)]
        self.tableView.reloadData()

        let promises: [Promise<Any>] = self.group.bookmarks.flatMap { self.promiseStop(bookmark: $0) }
        _ = when(resolved: promises).then { _ -> Void in
            self.lastUpdatedAt = Date.init()
            completionHandler?(NCUpdateResult.newData)
        }
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        self.group = app.modelDao.todayBookmarkGroup

        if (self.group.bookmarks.count == 0) {
            completionHandler(NCUpdateResult.noData)
            return
        }

        self.sections = [buildLastUpdatedSection(), buildTableSection(group: self.group)]
        self.tableView.reloadData()

        updateData(completionHandler: completionHandler)
    }

    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .expanded {
            // abxoxo - todo: calculate real height of table!
            preferredContentSize = CGSize(width: 0, height: maxSize.height)
        }
        else {
            preferredContentSize = maxSize
        }
    }
}

// MARK: - Last Updated Section
extension TodayViewController {

    private static let lastUpdatedAtUserDefaultsKey = "lastUpdatedAtUserDefaultsKey"
    var lastUpdatedAt: Date? {
        get {
            guard let defaultsDate = self.app.userDefaults.value(forKey: TodayViewController.lastUpdatedAtUserDefaultsKey) else {
                return nil
            }

            return defaultsDate as? Date
        }
        set(val) {
            self.app.userDefaults.setValue(val, forKey: TodayViewController.lastUpdatedAtUserDefaultsKey)

            guard let row = self.lastUpdateRow,
                  let indexPath = self.indexPath(for: row) else {
                return
            }
            self.replaceRow(at: indexPath, with: buildLastUpdateRow())
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    func buildLastUpdateRow() -> OBABaseRow {
        let row = OBARefreshRow.init(date: lastUpdatedAt) { _ in
            self.updateData(completionHandler: nil)
        }

        return row
    }

    func buildLastUpdatedSection() -> OBATableSection {
        let tableSection = OBATableSection.init()
        let tableRow = buildLastUpdateRow()

        tableSection.addRow(tableRow)
        self.lastUpdateRow = tableRow

        return tableSection
    }
}

// MARK: - Dynamic UI Construction
extension TodayViewController {
    func buildTableSection(group: OBABookmarkGroup) -> OBATableSection {
        let tableSection = OBATableSection.init()

        for bookmark in self.bookmarksInCurrentRegion() {
            let row: OBABaseRow
            if bookmark.bookmarkVersion == .version252 {
                row = OBATableRow.init(title: bookmark.name) { _ in
                    let targetURL = self.deepLinkRouter.deepLinkURL(forStopID: bookmark.stopId, regionIdentifier: bookmark.regionIdentifier) ?? URL.init(string: OBADeepLinkServerAddress)!
                    self.extensionContext?.open(targetURL, completionHandler: nil)
                }
            }
            else {
                let routeRow = OBABookmarkedRouteRow.init(bookmark: bookmark, action: nil)
                routeRow.attributedTopLine = NSAttributedString.init(string: bookmark.name)

                row = routeRow
            }

            row.model = bookmark
            tableSection.addRow(row)
        }

        return tableSection
    }

    func bookmarksInCurrentRegion() -> [OBABookmarkV2] {
        guard let region = self.app.modelDao.currentRegion else {
            return self.group.bookmarks
        }

        return self.group.bookmarks(inRegion: region)
    }

    func populateRow(_ row: OBABookmarkedRouteRow, targetURL: URL, routeName: String, departures: [OBAArrivalAndDepartureV2]) {
        if departures.count > 0 {
            row.errorMessage = nil
            let arrivalDeparture = departures[0]

            row.upcomingDepartures = OBAUpcomingDeparture.upcomingDepartures(fromArrivalsAndDepartures: departures)

            if let statusText = OBADepartureCellHelpers.statusText(forArrivalAndDeparture: arrivalDeparture),
               let upcoming = row.upcomingDepartures?.first {
                row.attributedMiddleLine = OBADepartureCellHelpers.attributedDepartureTime(withStatusText: statusText, upcomingDeparture: upcoming)
            }
        }
        else {
            let noDepartureText = String.init(format: NSLocalizedString("text_no_departure_next_time_minutes_params", comment: ""), routeName, String(kMinutes))
            row.attributedMiddleLine = OBADepartureCellHelpers.attributedDepartureTime(withStatusText: noDepartureText, upcomingDeparture: nil)
        }

        row.action = { _ in
            self.extensionContext?.open(targetURL, completionHandler: nil)
        }
    }
}

// MARK: - Data Loading
extension TodayViewController {
    func promiseStop(bookmark: OBABookmarkV2) -> Promise<Any>? {
        guard let indexPath = self.indexPath(forModel: bookmark) else {
            return nil
        }

        if bookmark.bookmarkVersion == .version252 {
            // whole stop bookmark, and nothing to retrieve from server.
            return Promise.init(value: true)
        }
        else {
            return loadBookmarkedRoute(bookmark, atIndexPath: indexPath)
        }
    }

    func loadBookmarkedRoute(_ bookmark: OBABookmarkV2, atIndexPath indexPath: IndexPath) -> Promise<Any>? {
        let row = self.row(at: indexPath) as! OBABookmarkedRouteRow

        let promiseWrapper = self.app.modelService.requestStopArrivalsAndDepartures(withID: bookmark.stopId, minutesBefore: 0, minutesAfter: kMinutes)
        return promiseWrapper.promise.then { networkResponse -> Void in
            let matchingDepartures: [OBAArrivalAndDepartureV2] = bookmark.matchingArrivalsAndDepartures(forStop: networkResponse.object as! OBAArrivalsAndDeparturesForStopV2)
            let url = self.deepLinkRouter.deepLinkURL(forStopID: bookmark.stopId, regionIdentifier: bookmark.regionIdentifier) ?? URL.init(string: OBADeepLinkServerAddress)!
            self.populateRow(row, targetURL: url, routeName: bookmark.routeShortName, departures: matchingDepartures)
            row.state = .complete
        }.catch { error in
            row.upcomingDepartures = nil
            row.state = .error
            row.errorMessage = error.localizedDescription
        }.always {
            self.replaceRow(at: indexPath, with: row)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}
