//
//  MapSearchViewController.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/22/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import UIKit
import OBAKit

@objc protocol MapSearchDelegate {
    func mapSearch(_ mapSearch: MapSearchViewController, selectedNavigationTarget target: OBANavigationTarget)
}

class MapSearchViewController: OBAStaticTableViewController, UISearchResultsUpdating {

    @objc public weak var delegate: MapSearchDelegate?

    // MARK: Lazy Properties
    public var modelDAO: OBAModelDAO = {
        return OBAApplication.shared().modelDao
    }()

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        let image = UIImage(named: "search_placeholder")
        self.emptyDataSetVerticalOffset = -125.0
        self.emptyDataSetImage = image
        self.emptyDataSetTitle = NSLocalizedString("map_search.empty_data_set_description", comment: "The empty data set description for the search controller")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.fixTabBarUnderlapIssue()
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        self.loadData(searchText: searchController.searchBar.text)
    }

    // MARK: - Data

    public func loadData(searchText: String?) {
        var trimmed: String
        if searchText == nil {
            trimmed = ""
        }
        else {
            trimmed = searchText!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        var sections: [OBATableSection] = []

        if trimmed.count == 0 {
            sections = []
        }
        else {
            sections = searchSections(searchText: trimmed)
        }

        self.sections = sections
        self.tableView.reloadData()
    }

    private func searchSections(searchText: String) -> [OBATableSection] {
        var sections: [OBATableSection] = []

        sections.append(self.buildQuickLookupSection(searchText: searchText))

        if let bookmarksSection = self.buildBookmarksSection(searchText: searchText) {
            sections.append(bookmarksSection)
        }

        if let recentsSection = self.buildRecentsSection(searchText: searchText) {
            sections.append(recentsSection)
        }

        return sections
    }

    private static func quickLookupRowText(title: String, searchText: String) -> NSAttributedString {
        let str = NSMutableAttributedString.init()

        let attributedTitle = NSAttributedString.init(string: title, attributes: [NSAttributedStringKey.foregroundColor: UIColor.darkGray])
        str.append(attributedTitle)

        // Needs a space tokeepwordsfromrunningtogether
        str.append(NSAttributedString.init(string: " "))

        let attributedSearchText = NSAttributedString.init(string: searchText, attributes: [NSAttributedStringKey.font: OBATheme.boldBodyFont])
        str.append(attributedSearchText)

        return str
    }

    private func buildQuickLookupSection(searchText: String) -> OBATableSection {

        let routeText = MapSearchViewController.quickLookupRowText(title: NSLocalizedString("map_search.search_for_route", comment: "Route Number: <ROUTE NUMBER>"), searchText: searchText)
        let routeRow = OBATableRow.init(attributedTitle: routeText) { _ in
            let target = OBANavigationTarget(forSearchRoute: searchText)
            self.delegate?.mapSearch(self, selectedNavigationTarget: target)
        }
        routeRow.accessoryType = .disclosureIndicator

        // Address Row
        let searchAddressText = MapSearchViewController.quickLookupRowText(title: NSLocalizedString("map_search.search_for_address", comment: "Address: <ADDRESS>"), searchText: searchText)
        let addressRow = OBATableRow.init(attributedTitle: searchAddressText) { _ in
            let target = OBANavigationTarget(forSearchAddress: searchText)
            self.delegate?.mapSearch(self, selectedNavigationTarget: target)
        }
        addressRow.accessoryType = .disclosureIndicator

        // Stop Number Row
        let stopNumberText = MapSearchViewController.quickLookupRowText(title: NSLocalizedString("map_search.search_for_stop_number", comment: "Stop Number: <STOP NUMBER>"), searchText: searchText)
        let stopNumberRow = OBATableRow.init(attributedTitle: stopNumberText) { _ in
            let target = OBANavigationTarget(forStopID: searchText)
            self.delegate?.mapSearch(self, selectedNavigationTarget: target)
        }
        stopNumberRow.accessoryType = .disclosureIndicator

        return OBATableSection.init(title: NSLocalizedString("map_search.quick_lookup_section_title", comment: "Map Search: Quick Lookup Table Section"), rows: [routeRow, addressRow, stopNumberRow])
    }

    private func buildRecentsSection(searchText: String) -> OBATableSection? {
        let rows = self.modelDAO.recentStops(matching: searchText)

        if rows.count == 0 {
            return nil
        }

        let tableRows = rows.map { evt -> OBATableRow in
            let tableRow = OBATableRow.init(title: evt.title, action: { _ in
                let target = OBANavigationTarget(forStopID: evt.stopID)
                self.delegate?.mapSearch(self, selectedNavigationTarget: target)
            })
            tableRow.subtitle = evt.subtitle
            tableRow.accessoryType = .disclosureIndicator
            tableRow.style = .subtitle
            return tableRow
        }
        return OBATableSection.init(title: NSLocalizedString("map_search.recent_stops_section_title", comment: "Map Search: Recent Stops section title"), rows: tableRows)
    }

    private func buildBookmarksSection(searchText: String) -> OBATableSection? {
        let bookmarks = self.modelDAO.mappableBookmarks(matching: searchText)

        if bookmarks.count == 0 {
            return nil
        }

        let rows = bookmarks.map { bm -> OBATableRow in
            let tableRow = OBATableRow.init(title: bm.name, action: { _ in
                let target = OBANavigationTarget(forStopID: bm.stopId)
                self.delegate?.mapSearch(self, selectedNavigationTarget: target)
            })
            tableRow.accessoryType = .disclosureIndicator
            tableRow.subtitle = bm.routeShortName
            tableRow.style = .subtitle
            return tableRow
        }

        return OBATableSection.init(title: NSLocalizedString("map_search.bookmarks_section_title", comment: "Map Search: Bookmarks section title"), rows: rows)
    }

    // MARK: - Misc Private

    private func fixTabBarUnderlapIssue() {
        // TODO: Improve me. I'm not sure of the best way to programmatically
        // retrieve this value, so I'll just include it as a lame constant instead.

        let tabBarHeight: CGFloat = 49
        self.tableView.contentInset.bottom = tabBarHeight
        self.tableView.scrollIndicatorInsets.bottom = tabBarHeight
    }
}
