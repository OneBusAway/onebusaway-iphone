//
//  MapTypePickerController.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 9/15/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import MapKit
import OBAKit

class MapTypePickerController: PickerViewController {

    private let application: OBAApplication

    public init(application: OBAApplication) {
        self.application = application

        super.init(nibName: nil, bundle: nil)

        let standardRow = OBATableRow(title: NSLocalizedString("map_controller.standard_map_type_title", comment: "Title for Standard Map toggle option.")) { [weak self] _ in
            self?.updateDefaults(to: .standard)
        }

        let hybridRow = OBATableRow(title: NSLocalizedString("map_controller.hybrid_map_type_title", comment: "Title for Hybrid Map toggle option.")) { [weak self] _ in
            self?.updateDefaults(to: .hybrid)
        }

        switch currentMapType {
        case .standard:
            standardRow.accessoryType = .checkmark
        default:
            hybridRow.accessoryType = .checkmark
        }

        self.sections = [OBATableSection(title: nil, rows: [standardRow, hybridRow])]
    }

    private var currentMapType: MKMapType {
        let rawMapType = UInt(bitPattern: application.userDefaults.integer(forKey: OBAMapSelectedTypeDefaultsKey))
        return MKMapType(rawValue: rawMapType)!
    }

    private func updateDefaults(to value: MKMapType) {
        let rawValue = Int(bitPattern: value.rawValue)
        application.userDefaults.set(rawValue, forKey: OBAMapSelectedTypeDefaultsKey)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
