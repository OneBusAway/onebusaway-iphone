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
import SVProgressHUD

@objc protocol RegionListDelegate {
    func regionSelected()
}

class RegionListViewController: OBAStaticTableViewController, RegionBuilderDelegate {
    var currentLocation: CLLocation?
    var regions: [OBARegionV2]?
    weak var delegate: RegionListDelegate?

    lazy var modelDAO: OBAModelDAO = OBAApplication.sharedApplication().modelDao
    lazy var modelService: OBAModelService = OBAModelService.init()

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .Add, target: self, action: #selector(addCustomAPI))

        self.updateData()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(selectedRegionDidChange), name: OBARegionDidUpdateNotification, object: nil)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: OBARegionDidUpdateNotification, object: nil)
    }

    // MARK: - Region Builder

    func addCustomAPI() {
        self.buildRegion(nil)
    }

    func buildRegion(region: OBARegionV2?) {
        let builder = RegionBuilderViewController.init()
        if region != nil {
            builder.region = region!
        }
        builder.delegate = self
        let nav = UINavigationController.init(rootViewController: builder)
        self.presentViewController(nav, animated: true, completion: nil)
    }

    func regionBuilderDidCreateRegion(region: OBARegionV2) {
        // If the user is editing an existing region, then we
        // can ensure that it is properly updated by removing
        // it and then re-adding it.
        self.modelDAO.removeCustomRegion(region)
        self.modelDAO.addCustomRegion(region)

        self.modelDAO.automaticallySelectRegion = false
        self.modelDAO.currentRegion = region
        OBAApplication.sharedApplication().refreshSettings()

        self.loadData()
    }

    // MARK: - Notifications

    func selectedRegionDidChange(note: NSNotification) {
        SVProgressHUD.dismiss()
        self.loadData()
    }

    // MARK: - Table View Editing/Deletion

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        guard let region = self.rowAtIndexPath(indexPath).model else {
            return false
        }

        // Only custom regions can be edited or deleted.
        return region.custom
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            self.deleteRowAtIndexPath(indexPath)
        }
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let row = self.rowAtIndexPath(indexPath)
        guard let region = row.model as? OBARegionV2 else {
            return nil
        }

        // Only regions that were created in-app can be edited.
        if !region.custom {
            return nil;
        }

        let edit = UITableViewRowAction.init(style: .Normal, title: OBAStrings.edit()) { (action, indexPath) in
            self.buildRegion(region)
        }

        let delete = UITableViewRowAction.init(style: .Destructive, title: OBAStrings.delete()) { (action, indexPath) in
            self.deleteRowAtIndexPath(indexPath)
        }

        return [edit, delete]
    }

    // MARK: - Data Loading

    func updateData() {
        SVProgressHUD.show()

        firstly {
            return Promise { fulfill, reject in
                CLLocationManager.promise().then { location in
                    fulfill(location)
                }.error { error in
                    fulfill(nil)
                }
            }
        }.then { location in
            self.currentLocation = location as? CLLocation
            return OBAApplication.sharedApplication().modelService.requestRegions()
        }.then { regions -> Void in
            self.regions = regions as? [OBARegionV2]
            self.loadData()
        }.always {
            SVProgressHUD.dismiss()
        }.error { error in
            AlertPresenter.showWarning(NSLocalizedString("Unable to Load Regions", comment: ""), body: (error as NSError).localizedDescription)
        }
    }

    /**
     Builds a list of sections and rows from available region and location data.
     */
    func loadData() {
        let regions = self.regions!
        let customRows = tableRowsFromRegions(self.modelDAO.customRegions())
        let activeRows = tableRowsFromRegions(regions.filter { $0.active })
        let experimentalRows = tableRowsFromRegions(regions.filter { $0.experimental })

        let autoSelectRow = OBASwitchRow.init(title: NSLocalizedString("Automatically Select Region", comment: ""), action: { row in
            self.modelDAO.automaticallySelectRegion = !self.modelDAO.automaticallySelectRegion

            if (self.modelDAO.automaticallySelectRegion) {
                OBAApplication.sharedApplication().regionHelper.updateNearestRegion()
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
            sections.append(OBATableSection.init(title: NSLocalizedString("Experimental Regions", comment: ""), rows: experimentalRows))
        }

        self.sections = sections
        self.tableView.reloadData()
    }

    /**
     Builds a sorted array of `OBATableRow` objects from an array of `OBARegionV2` objects.
     
     - Parameter regions: The array of regions that will be used to build an array of rows
     
     - Returns: an array of `OBATableRow`
    */
    func tableRowsFromRegions(regions: [OBARegionV2]) -> [OBATableRow] {
        return regions.sort { r1, r2 -> Bool in
            r1.regionName < r2.regionName
        }.map { region in
            let autoSelect = self.modelDAO.automaticallySelectRegion

            let action: (() -> Void)? = autoSelect ? nil : {
                self.modelDAO.currentRegion = region
                OBAApplication.sharedApplication().refreshSettings()
                self.loadData()
            }

            let row: OBATableRow = OBATableRow.init(title: region.regionName, action: action)

            row.model = region
            row.deleteModel = {
                let alert = UIAlertController.init(title: NSLocalizedString("Are you sure you want to delete this region?", comment: ""), message: nil, preferredStyle: .Alert)
                alert.addAction(UIAlertAction.init(title: OBAStrings.cancel(), style: .Cancel, handler: nil))
                alert.addAction(UIAlertAction.init(title: OBAStrings.delete(), style: .Destructive, handler: { action in
                    self.modelDAO.removeCustomRegion(region)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            }

            if (autoSelect) {
                row.titleColor = OBATheme.darkDisabledColor()
                row.selectionStyle = .None
            }

            if (self.modelDAO.currentRegion == region) {
                row.accessoryType = .Checkmark
            }

            return row
        }
    }
}
