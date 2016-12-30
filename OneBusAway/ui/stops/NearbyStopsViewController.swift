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
    var stop: OBAStopV2
    lazy var modelService: OBAModelService = {
        return OBAApplication.shared().modelService
    }()

    init(withStop stop: OBAStopV2) {
        self.stop = stop
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

        self.loadData()
    }

    // MARK: - Data Loading

    func loadData() {
        SVProgressHUD.show()

        self.modelService.requestStopsNear(self.stop.coordinate).then { stops in
            self.populateTable(stops as! [OBAStopV2])
        }.always {
            SVProgressHUD.dismiss()
        }.catch { error in
            AlertPresenter.showWarning(OBAStrings.error(), body: error.localizedDescription)
        }
    }

    func populateTable(_ stops: [OBAStopV2]) {
        var sections: [OBATableSection] = []
        let filteredStops = stops.filter { $0 != self.stop }
        let grouped: [String: [OBAStopV2]] = filteredStops.categorize { $0.direction }

        for (direction, stopsForDirection) in grouped {
            let section = OBATableSection.init(title: cardinalDirectionFromAbbreviation(direction))
            section.rows = stopsForDirection.sorted(by: { (s1, s2) -> Bool in
                let distance1 = OBAMapHelpers.getDistanceFrom(s1.coordinate, to: self.stop.coordinate)
                let distance2 = OBAMapHelpers.getDistanceFrom(s2.coordinate, to: self.stop.coordinate)
                return distance1 < distance2
            }).map { stop in
                let row = OBATableRow.init(title: stop.name, action: {
                    let stopController = OBAStopViewController.init(stopID: stop.stopId)
                    self.navigationController?.pushViewController(stopController, animated: true)
                })
                row.subtitle = String.localizedStringWithFormat(NSLocalizedString("text_only_routes_colon_param", comment: "e.g. Routes: 10, 12, 43"), stop.routeNamesAsString())
                row.style = .subtitle
                row.accessoryType = .disclosureIndicator
                return row
            }
            sections.append(section)
        }

        self.sections = sections
        self.tableView.reloadData()
    }

    // MARK: - Private

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
