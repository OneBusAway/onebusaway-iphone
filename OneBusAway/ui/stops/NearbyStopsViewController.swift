//
//  NearbyStopsViewController.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 11/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import Foundation
import UIKit
import OBAKit
import PromiseKit
import SVProgressHUD

class NearbyStopsViewController: OBAStaticTableViewController {
    var stop: OBAStopV2?
    var searchResult: OBASearchResult?
    var presentedModally = false
    var pushesResultsOntoStack = false
    lazy public var navigator: OBANavigator = {
        let navigator = UIApplication.shared.delegate as! OBAApplicationDelegate
        return navigator
    }()

    lazy var modelService: OBAModelService = {
        return OBAApplication.shared().modelService
    }()

    public var currentCoordinate: CLLocationCoordinate2D?

    init(withStop stop: OBAStopV2) {
        self.stop = stop
        self.currentCoordinate = self.stop?.coordinate
        super.init(nibName: nil, bundle: nil)
    }

    init(_ searchResult: OBASearchResult) {
        self.searchResult = searchResult
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("msg_nearby_stops", comment: "Title of the Nearby Stops view controller")
        self.emptyDataSetTitle = NSLocalizedString("msg_mayus_no_stops_found", comment: "Empty data set title for the Nearby Stops controller")
        self.emptyDataSetDescription = NSLocalizedString("msg_coulnt_find_other_stops_on_radius", comment: "Empty data set description for the Nearby Stops controller")

        if self.presentedModally {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: OBAStrings.close(), style: .plain, target: self, action: #selector(closeButtonTapped))
        }

        self.loadData()
    }

    // MARK: - Data Loading

    func loadData() {
        if let searchResult = self.searchResult {
            self.populateTable(searchResult)
        }
        else if let stop = self.stop {
            SVProgressHUD.show()
            self.modelService.requestStopsNear(stop.coordinate).then { searchResult in
                self.populateTable(searchResult as! OBASearchResult)
            }.always {
                SVProgressHUD.dismiss()
            }.catch { error in
                AlertPresenter.showWarning(OBAStrings.error(), body: error.localizedDescription)
            }
        }
        else {
            AlertPresenter.showError(OBAStrings.error(), body: OBAStrings.inexplicableErrorPleaseContactUs())
        }
    }

    /// Builds a list of table sections, sets the view controller's `sections` property
    /// to that built list, and reloads the table view.
    ///
    /// - Parameter searchResult: The `OBASearchResult` object used to populate the view controller
    func populateTable(_ searchResult: OBASearchResult) {
        var sections: [OBATableSection]

        switch searchResult.searchType {
        case .region, .placemark, .stopId, .stops:
            sections = self.stopSectionsFromSearchResult(searchResult)
        case .route:
            sections = [self.routeSectionFromSearchResult(searchResult)]
        case .address:
            sections = [self.addressSectionFromSearchResult(searchResult)]
        default:
            sections = []
        }

        self.sections = sections
        self.tableView.reloadData()
    }

    /// Creates an array of sections for the provided stops.
    /// Each stop is grouped according to its cardinal direction.
    /// e.g. N: [S1, S2], S: [S3, S4]
    ///
    /// - Parameter searchResult: A search result object containing a list of stops
    /// - Returns: An array of `OBATableSection`s containing stop rows
    func stopSectionsFromSearchResult(_ searchResult: OBASearchResult) -> [OBATableSection] {
        let stops = searchResult.values as! [OBAStopV2]
        var sections: [OBATableSection] = []
        let filteredStops = stops.filter { $0 != self.stop }
        let grouped: [String: [OBAStopV2]] = filteredStops.categorize { $0.direction }

        for (direction, stopsForDirection) in grouped {
            let section = self.stopSectionFrom(direction: direction, stops: stopsForDirection)
            sections.append(section)
        }

        return sections
    }

    func stopSectionFrom(direction: String, stops: [OBAStopV2]) -> OBATableSection {
        let section = OBATableSection.init(title: cardinalDirectionFromAbbreviation(direction))
        var rows: [OBAStopV2]

        if let coordinate = self.currentCoordinate {
            rows = stops.sorted(by: { (s1, s2) -> Bool in
                let distance1 = OBAMapHelpers.getDistanceFrom(s1.coordinate, to: coordinate)
                let distance2 = OBAMapHelpers.getDistanceFrom(s2.coordinate, to: coordinate)
                return distance1 < distance2
            })
        }
        else {
            rows = stops
        }

        section.rows = rows.map { stop in
            let row = OBATableRow.init(title: stop.name, action: {
                let target = OBANavigationTarget(forStopID: stop.stopId)
                self.navigateTo(target)
            })
            row.subtitle = String.localizedStringWithFormat(NSLocalizedString("text_only_routes_colon_param", comment: "e.g. Routes: 10, 12, 43"), stop.routeNamesAsString())
            row.style = .subtitle
            row.accessoryType = .disclosureIndicator
            return row
        }
        return section
    }

    func routeSectionFromSearchResult(_ searchResult: OBASearchResult) -> OBATableSection {
        let routes = searchResult.values as! [OBARouteV2]

        let rows = routes.map { route -> OBATableRow in
            let row = OBATableRow.init(title: route.fullRouteName, action: {
                let target = OBANavigationTarget(forRoute: route)
                self.navigateTo(target)
            })
            row.subtitle = route.agency.name
            row.style = .subtitle

            return row
        }

        return OBATableSection.init(title: NSLocalizedString("nearby_stops.routes_section_title", comment: "The section title on the 'Nearby' controller that says 'Routes'"), rows: rows)
    }

    func addressSectionFromSearchResult(_ searchResult: OBASearchResult) -> OBATableSection {
        let placemarks = searchResult.values as! [OBAPlacemark]
        let rows = placemarks.map { placemark -> OBATableRow in
            let row = OBATableRow.init(title: placemark.title!, action: {
                let target = OBANavigationTarget(forSearch: placemark)
                self.navigateTo(target)
            })
            return row
        }

        return OBATableSection.init(title: nil, rows: rows)
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        self.dismissModal(completion: nil)
    }

    // MARK: - Private

    private func navigateTo(_ target: OBANavigationTarget) {
        if self.pushesResultsOntoStack {
            // abxoxo - make this way better! I should be able to map from
            // an OBANavigationTarget -> UIViewController and push that.
            guard let stopID = target.searchArgument as? String else {
                return
            }
            let stopController = OBAStopViewController.init(stopID: stopID)
            self.navigationController?.pushViewController(stopController, animated: true)
        }
        else {
            self.dismissModal {
                self.navigator.navigate(to: target)
            }
        }
    }

    private func dismissModal(completion: (() -> Swift.Void)? = nil) {
        if self.presentedModally {
            self.dismiss(animated: true, completion: completion)
        }
    }

    func cardinalDirectionFromAbbreviation(_ abbreviation: String) -> String {
        switch abbreviation {
        case "N":
            return NSLocalizedString("msg_northbound", comment: "As in 'going to the north.'")
        case "E":
            return NSLocalizedString("msg_eastbound", comment: "As in 'going to the east.'")
        case "S":
            return NSLocalizedString("msg_southbound", comment: "As in 'going to the south.'")
        case "W":
            return NSLocalizedString("msg_westbound", comment: "As in 'going to the west.'")
        default:
            return "\(abbreviation)-bound"
        }
    }
}
