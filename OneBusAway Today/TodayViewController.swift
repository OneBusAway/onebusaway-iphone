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

let kMinutes: UInt = 60

class TodayViewController: OBAStaticTableViewController {
    let app = OBAApplication.init()
    var group: OBABookmarkGroup = OBABookmarkGroup.init(bookmarkGroupType: .todayWidget)

    override func viewDidLoad() {
        super.viewDidLoad()

        let configuration = OBAApplicationConfiguration.init()
        configuration.extensionMode = true
        app.start(with: configuration)
    }
}

extension TodayViewController: NCWidgetProviding {
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        self.group = app.modelDao.todayBookmarkGroup
        self.sections = [buildTableSection(group: self.group)]
        self.tableView.reloadData()

        let promises: [Promise<Void>] = self.group.bookmarks.flatMap { self.promiseStop(bookmark: $0) }
        _ = when(resolved: promises).then { _ in completionHandler(NCUpdateResult.newData) }
    }
}

// MARK: - UI Construction
extension TodayViewController {
    func buildTableSection(group: OBABookmarkGroup) -> OBATableSection {
        let tableSection = OBATableSection.init()

        for bookmark in self.group.bookmarks {
            let row = OBABookmarkedRouteRow.init(bookmark: bookmark, action: nil)
            row.model = bookmark
            tableSection.addRow(row)
        }

        return tableSection
    }

    func populateRow(_ row: OBABookmarkedRouteRow, routeName: String, departures: [OBAArrivalAndDepartureV2]) {
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
    }
}

// MARK: - Data Loading
extension TodayViewController {
    func promiseStop(bookmark: OBABookmarkV2) -> Promise<Void>? {
        guard let indexPath = self.indexPath(forModel: bookmark) else {
            return nil
        }

        let row = self.row(at: indexPath) as! OBABookmarkedRouteRow

        let promise = self.app.modelService.stop(withID: bookmark.stopId, minutesBefore: 0, minutesAfter: kMinutes).then { response -> Void in
            let matchingDepartures: [OBAArrivalAndDepartureV2] = bookmark.matchingArrivalsAndDepartures(forStop: response)

            self.populateRow(row, routeName: bookmark.routeShortName, departures: matchingDepartures)
            row.state = .complete
        }.catch { error in
            row.upcomingDepartures = nil
            row.state = .error
            row.supplementaryMessage = error.localizedDescription
        }.always {
            self.replaceRow(at: indexPath, with: row)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }

        return promise
    }
}
