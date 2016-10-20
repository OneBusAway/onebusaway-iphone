//
//  RegionBuilderViewController.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/24/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import Foundation
import UIKit
import OBAKit
import SVProgressHUD

@objc protocol RegionBuilderDelegate {
    func regionBuilderDidCreateRegion(_ region: OBARegionV2)
}

class RegionBuilderViewController: OBAStaticTableViewController {

    var modelService: OBAModelService?

    weak var delegate: RegionBuilderDelegate?

    /*
     This sidecar userDataModel object is required in order to shuttle data
     between the cells and this controller because the data rows used to
     create the cells are copied around as opposed to being strongly
     referenced. This is generally an advantageous approach except when
     you really do want shared mutable state. In order to minimize the
     amount of shared mutable state, we maintain this dictionary.
     */
    var userDataModel = NSMutableDictionary.init(capacity: 12)

    lazy var region: OBARegionV2 = {
        let r = OBARegionV2.init()
        // give the region a random identifier that shouldn't conflict with
        // any real OBA region for a long time to come.
        r.identifier = Int(arc4random_uniform(32768) + 100)
        r.custom = true
        return r
    }()

    lazy var baseURLRow: OBATextFieldRow = {
        let row = OBATextFieldRow.init(labelText: NSLocalizedString("Base URL", comment: ""), textFieldText: self.region.baseURL?.absoluteString)
        row.keyboardType = .URL
        RegionBuilderViewController.applyPropertiesToTextRow(row, model: self.userDataModel)
        return row
    }()

    lazy var nameRow: OBATextFieldRow = {
        let row = OBATextFieldRow.init(labelText: NSLocalizedString("Name", comment: ""), textFieldText: self.region.regionName)
        RegionBuilderViewController.applyPropertiesToTextRow(row, model: self.userDataModel)
        return row
    }()

    lazy var obaRealTimeRow: OBASwitchRow = {
        let row = OBASwitchRow.init(title: NSLocalizedString("Supports OBA Realtime APIs", comment: ""), action: nil)
        row.switchValue = self.region.supportsObaRealtimeApis
        row.dataKey = row.title
        row.model = self.userDataModel
        return row
    }()

    lazy var isActiveRow: OBASwitchRow = {
        let row = OBASwitchRow.init(title: NSLocalizedString("Is Active", comment: ""), action: nil)
        row.switchValue = self.region.active
        row.dataKey = row.title
        row.model = self.userDataModel
        return row
    }()

    lazy var contactEmailRow: OBATextFieldRow = {
        let row = OBATextFieldRow.init(labelText: NSLocalizedString("Contact Email", comment: ""), textFieldText: self.region.contactEmail)
        row.keyboardType = .emailAddress
        row.autocapitalizationType = .none
        RegionBuilderViewController.applyPropertiesToTextRow(row, model: self.userDataModel)
        return row
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Add Region", comment: "")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: OBAStrings.cancel(), style: .plain, target: self, action: #selector(cancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: OBAStrings.save(), style: .done, target: self, action: #selector(save))

        let requiredSection = OBATableSection.init(title: NSLocalizedString("Required", comment: ""))

        requiredSection.addRow(self.baseURLRow)
        requiredSection.addRow(self.nameRow)

        let optionalSection = OBATableSection.init(title: NSLocalizedString("Optional", comment: ""))

        optionalSection.addRow(self.obaRealTimeRow)
        optionalSection.addRow(self.isActiveRow)
        optionalSection.addRow(self.contactEmailRow)

        self.sections = [requiredSection, optionalSection]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let indexPath = self.indexPath(for: self.baseURLRow)
        if let cell: OBATextFieldCell = self.tableView.cellForRow(at: indexPath!) as! OBATextFieldCell? {
            cell.textField.becomeFirstResponder()
        }
    }

    // MARK: - Actions

    func cancel() {
        self.dismiss(animated: true, completion: nil)
    }

    func save() {

        self.view.endEditing(true)

        self.loadDataIntoRegion()

        guard self.region.isValidModel() else {
            let alert = UIAlertController.init(title: NSLocalizedString("Invalid Region", comment: ""), message: NSLocalizedString("The region you have specified is not valid. Please specify at least a base URL and a name.", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: OBAStrings.dismiss(), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }

        SVProgressHUD.show()

        self.modelService = OBAModelService(baseURL: self.region.baseURL!)
        let URL = self.modelService!.obaJsonDataSource.config.constructURL(OBAAgenciesWithCoverageAPIPath, withArgs: nil)

        self.modelService!.requestAgenciesWithCoverage().then { agencies -> Void in
            for agency in (agencies as! [OBAAgencyWithCoverageV2]) {
                if let bounds = agency.regionBounds {
                    self.region.addBound(bounds)
                }
            }

            if let delegate = self.delegate {
                delegate.regionBuilderDidCreateRegion(self.region)
            }

            self.dismiss(animated: true, completion: nil)
        }.always {
            SVProgressHUD.dismiss()
        }.catch { error in
            let msg = String(format: NSLocalizedString("Unable to load data from %@. Please check the URL and try again.\r\n\r\n%@", comment: ""), URL!.absoluteString, (error as NSError).localizedDescription)
            let alert = UIAlertController.init(title: NSLocalizedString("Invalid Region Base URL", comment: ""), message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: OBAStrings.dismiss(), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - Private

    /**
        Common configuration for lazily loaded properties.
     */
    fileprivate class func applyPropertiesToTextRow(_ row: OBATextFieldRow, model: NSMutableDictionary) {
        row.dataKey = row.labelText
        row.model = model
    }

    fileprivate func loadDataIntoRegion() {
        // Required Fields
        if let text = self.userDataModel[self.baseURLRow.dataKey!] {
            self.region.obaBaseUrl = text as! String
        }

        if let text = self.userDataModel[self.nameRow.dataKey!] {
            self.region.regionName = text as! String
        }

        // Optional Fields
        self.region.contactEmail = self.userDataModel[self.contactEmailRow.dataKey!] as? String

        if let val = self.userDataModel[self.obaRealTimeRow.dataKey!] as! Bool? {
            self.region.supportsObaRealtimeApis = val
        }

        if let val = self.userDataModel[self.isActiveRow.dataKey!] as! Bool? {
            self.region.active = val
        }
    }
}
