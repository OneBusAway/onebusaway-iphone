//
//  VehicleDisambiguationViewController.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 7/12/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit

@objc(OBAVehicleDisambiguationDelegate) protocol VehicleDisambiguationDelegate {
    func disambiguator(_ viewController: VehicleDisambiguationViewController, didSelect matchingVehicle: MatchingAgencyVehicle)
}

@objc(OBAVehicleDisambiguationViewController)
final class VehicleDisambiguationViewController: OBAStaticTableViewController {

    private let matchingVehicles: [MatchingAgencyVehicle]
    private weak var delegate: VehicleDisambiguationDelegate?

    @objc(initWithMatchingVehicles:delegate:)
    init(with matchingVehicles: [MatchingAgencyVehicle], delegate: VehicleDisambiguationDelegate) {
        self.matchingVehicles = matchingVehicles
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("vehicle_disambiguator.title", comment: "Title of the Vehicle Search disambiguator view controller")

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))

        let rows = matchingVehicles.map { agencyVehicle -> OBATableRow in
            let row = OBATableRow(title: agencyVehicle.userFriendlyVehicleID) { _ in
                self.delegate?.disambiguator(self, didSelect: agencyVehicle)
            }
            row.accessoryType = .disclosureIndicator
            row.style = .subtitle
            row.subtitle = "\(agencyVehicle.name) (\(agencyVehicle.vehicleID))"
            return row
        }

        let section = OBATableSection(title: nil, rows: rows)
        self.sections = [section]
    }

    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }
}
