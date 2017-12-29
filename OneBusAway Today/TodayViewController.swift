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

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Fabric.with([Crashlytics.self])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.emptyDataSetVerticalOffset = 0
        self.emptyDataSetTitle = NSLocalizedString("today_screen.no_data_title", comment: "No Bookmarks - empty data set title.")
        self.emptyDataSetDescription = NSLocalizedString("today_screen.no_data_description", comment: "Add bookmarks to Today Screen Bookmarks to see them here. - empty data set description.")

        let configuration = OBAApplicationConfiguration.init()
        configuration.extensionMode = true
        app.start(with: configuration)
    }
}

extension TodayViewController: NCWidgetProviding {
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        self.group = app.modelDao.todayBookmarkGroup

        if (self.group.bookmarks.count == 0) {
            completionHandler(NCUpdateResult.noData)
            return
        }

        self.sections = [buildTableSection(group: self.group)]
        self.tableView.reloadData()

        let promises: [Promise<Any>] = self.group.bookmarks.flatMap { self.promiseStop(bookmark: $0) }
        _ = when(resolved: promises).then { _ in completionHandler(NCUpdateResult.newData) }
    }
}

// MARK: - UI Construction
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
                row = OBABookmarkedRouteRow.init(bookmark: bookmark, action: nil)
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
            row.supplementaryMessage = nil
            let arrivalDeparture = departures[0]
            row.routeName = arrivalDeparture.bestAvailableName
            row.destination = arrivalDeparture.tripHeadsign
            
            if let statusText = OBADepartureCellHelpers.statusText(forArrivalAndDeparture: arrivalDeparture) {
                row.statusText = statusText
            }
        }
        else {
            row.supplementaryMessage = String.init(format: NSLocalizedString("text_no_departure_next_time_minutes_params", comment: ""), routeName, String(kMinutes))
        }
        
        row.upcomingDepartures = OBAUpcomingDeparture.upcomingDepartures(fromArrivalsAndDepartures: departures)

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
            row.supplementaryMessage = error.localizedDescription
        }.always {
            self.replaceRow(at: indexPath, with: row)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}
