//
//  RegionListViewController.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/14/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import UIKit
import CoreLocation
import OBAKit
import PromiseKit
import PMKCoreLocation
import SVProgressHUD

@objc protocol RegionListDelegate {
    func regionSelected()
}

class RegionListViewController: OBAStaticTableViewController, RegionBuilderDelegate {
    var currentLocation: CLLocation?
    var regions: [OBARegionV2]?
    weak var delegate: RegionListDelegate?

    lazy var modelDAO: OBAModelDAO = OBAApplication.shared().modelDao
    lazy var modelService: OBAModelService = OBAModelService.init()

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(addCustomAPI))

        self.updateData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(selectedRegionDidChange), name: NSNotification.Name.OBARegionDidUpdate, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.OBARegionDidUpdate, object: nil)
    }

    // MARK: - Region Builder

    func addCustomAPI() {
        self.buildRegion(nil)
    }

    func buildRegion(_ region: OBARegionV2?) {
        let builder = RegionBuilderViewController.init()
        if region != nil {
            builder.region = region!
        }
        builder.delegate = self
        let nav = UINavigationController.init(rootViewController: builder)
        self.present(nav, animated: true, completion: nil)
    }

    func regionBuilderDidCreateRegion(_ region: OBARegionV2) {
        // If the user is editing an existing region, then we
        // can ensure that it is properly updated by removing
        // it and then re-adding it.
        self.modelDAO.removeCustomRegion(region)
        self.modelDAO.addCustomRegion(region)

        self.modelDAO.automaticallySelectRegion = false
        self.modelDAO.currentRegion = region

        self.loadData()
    }

    // MARK: - Notifications

    func selectedRegionDidChange(_ note: Notification) {
        SVProgressHUD.dismiss()
        self.loadData()
    }

    // MARK: - Table View Editing/Deletion

    func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
        guard let region = self.row(at: indexPath)!.model else {
            return false
        }

        // Only custom regions can be edited or deleted.
        return region.custom
    }

    func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteRow(at: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [UITableViewRowAction]? {
        let row = self.row(at: indexPath)
        guard let region = row!.model as? OBARegionV2 else {
            return nil
        }

        // Only regions that were created in-app can be edited.
        if !region.custom {
            return nil;
        }

        let edit = UITableViewRowAction.init(style: .normal, title: OBAStrings.edit()) { (action, indexPath) in
            self.buildRegion(region)
        }

        let delete = UITableViewRowAction.init(style: .destructive, title: OBAStrings.delete()) { (action, indexPath) in
            self.deleteRow(at: indexPath)
        }

        return [edit, delete]
    }

    // MARK: - Data Loading

    func updateData() {

        SVProgressHUD.show()

        CLLocationManager.promise().recover { error -> CLLocation in
            return CLLocation.init(latitude: 0, longitude: 0)
        }.then { location -> Void in
            self.currentLocation = location as CLLocation
        }.then { _ in
            OBAApplication.shared().modelService.requestRegions()
        }.then { regions in
            self.regions = regions as? [OBARegionV2]
        }.then { _ in
            self.loadData()
        }.always {
            SVProgressHUD.dismiss()
        }.catch { error in
            AlertPresenter.showWarning(NSLocalizedString("Unable to Load Regions", comment: ""), body: (error as NSError).localizedDescription)
        }
    }

    /**
     Builds a list of sections and rows from available region and location data.
     */
    func loadData() {
        guard let regions = self.regions else {
            return
        }

        let customRows = tableRowsFromRegions(self.modelDAO.customRegions())
        let activeRows = tableRowsFromRegions(regions.filter { $0.active && !$0.experimental })
        let experimentalRows = tableRowsFromRegions(regions.filter { $0.experimental })

        let autoSelectRow = OBASwitchRow.init(title: NSLocalizedString("Automatically Select Region", comment: ""), action: { row in
            self.modelDAO.automaticallySelectRegion = !self.modelDAO.automaticallySelectRegion

            if (self.modelDAO.automaticallySelectRegion) {
                OBAApplication.shared().regionHelper.updateNearestRegion()
                SVProgressHUD.show()
            }
            else {
                self.loadData()
            }
        }, switchValue: self.modelDAO.automaticallySelectRegion)

        var sections = [OBATableSection]()

        sections.append(OBATableSection.init(title: nil, rows: [autoSelectRow]))

        if customRows.count > 0 {
            sections.append(OBATableSection.init(title: NSLocalizedString("Custom Regions", comment: ""), rows: customRows))
        }

        sections.append(OBATableSection.init(title: NSLocalizedString("Active Regions", comment: ""), rows: activeRows))

        if experimentalRows.count > 0 {
            sections.append(OBATableSection.init(title: NSLocalizedString("Newest Regions", comment: ""), rows: experimentalRows))
        }

        self.sections = sections
        self.tableView.reloadData()
    }

    /**
     Builds a sorted array of `OBATableRow` objects from an array of `OBARegionV2` objects.
     
     - Parameter regions: The array of regions that will be used to build an array of rows
     
     - Returns: an array of `OBATableRow`
    */
    func tableRowsFromRegions(_ regions: [OBARegionV2]) -> [OBATableRow] {
        return regions.sorted { r1, r2 -> Bool in
            r1.regionName < r2.regionName
        }.map { region in
            let autoSelect = self.modelDAO.automaticallySelectRegion

            let action: (() -> Void)? = autoSelect ? nil : {
                self.modelDAO.currentRegion = region
                self.loadData()

                if let delegate = self.delegate {
                    delegate.regionSelected()
                }
            }

            let row: OBATableRow = OBATableRow.init(title: region.regionName, action: action)

            row.model = region
            row.deleteModel = { row in
                let alert = UIAlertController.init(title: NSLocalizedString("Are you sure you want to delete this region?", comment: ""), message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: OBAStrings.cancel(), style: .cancel, handler: nil))
                alert.addAction(UIAlertAction.init(title: OBAStrings.delete(), style: .destructive, handler: { action in
                    self.modelDAO.removeCustomRegion(region)
                }))
                self.present(alert, animated: true, completion: nil)
            }

            if (autoSelect) {
                row.titleColor = OBATheme.darkDisabledColor()
                row.selectionStyle = .none
            }

            if (self.modelDAO.currentRegion == region) {
                row.accessoryType = .checkmark
            }

            return row
        }
    }
}
