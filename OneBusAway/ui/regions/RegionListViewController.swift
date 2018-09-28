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

@objc(OBARegionListViewController)
class RegionListViewController: OBAStaticTableViewController, RegionBuilderDelegate {
    @objc weak var delegate: RegionListDelegate?

    private let application: OBAApplication

    @objc init(application: OBAApplication) {
        self.application = application
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("msg_pick_your_location", comment: "Title of the Region List Controller")
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(addCustomAPI))
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - UIViewController
extension RegionListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        updateData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(selectedRegionDidChange), name: NSNotification.Name.OBARegionDidUpdate, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.OBARegionDidUpdate, object: nil)
    }
}

// MARK: - Region Builder
extension RegionListViewController {
    @objc func addCustomAPI() {
        buildRegion(nil)
    }

    func buildRegion(_ region: OBARegionV2?) {
        let builder = RegionBuilderViewController.init()
        if region != nil {
            builder.region = region!
        }
        builder.delegate = self
        let nav = UINavigationController.init(rootViewController: builder)
        present(nav, animated: true, completion: nil)
    }

    func regionBuilderDidCreateRegion(_ region: OBARegionV2) {
        // If the user is editing an existing region, then we
        // can ensure that it is properly updated by removing
        // it and then re-adding it.
        application.modelDao.removeCustomRegion(region)
        application.modelDao.addCustomRegion(region)

        application.modelDao.automaticallySelectRegion = false
        application.modelDao.currentRegion = region

        loadData()
    }
}

// MARK: - Notifications
extension RegionListViewController {
    @objc func selectedRegionDidChange(_ note: Notification) {
        SVProgressHUD.dismiss()
        loadData()
    }
}

// MARK: - Table View
extension RegionListViewController {
    func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
        guard
            let row = row(at: indexPath),
            let region = row.model as? OBARegionV2
        else {
            return false
        }

        // Only custom regions can be edited or deleted.
        return region.custom
    }

    func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCell.EditingStyle, forRowAtIndexPath indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteRow(at: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard
            let row = row(at: indexPath),
            let region = row.model as? OBARegionV2
        else {
            return nil
        }

        // Only regions that were created in-app can be edited.
        if !region.custom {
            return nil
        }

        let edit = UITableViewRowAction.init(style: .normal, title: OBAStrings.edit) { _, _ in
            self.buildRegion(region)
        }

        let delete = UITableViewRowAction.init(style: .destructive, title: OBAStrings.delete) { (_, indexPath) in
            self.deleteRow(at: indexPath)
        }

        return [edit, delete]
    }
}

// MARK: - Data Loading
extension RegionListViewController {
    func updateData() {
        guard let promise = application.regionHelper.refreshData() else {
            AlertPresenter.showError("unable to load data", body: "TBD")
            return
        }

        promise.then { _ in
            self.loadData()
        }.catch { error in
            AlertPresenter.showWarning(NSLocalizedString("msg_unable_load_regions", comment: ""), body: (error as NSError).localizedDescription)
        }
    }

    /**
     Builds a list of sections and rows from available region and location data.
     */
    func loadData() {
        let regions = application.regionHelper.regions

        let acceptableRegions = regions.filter { $0.active && $0.supportsObaRealtimeApis }

        let customRows = tableRowsFromRegions(application.modelDao.customRegions())
        let activeRows = tableRowsFromRegions(acceptableRegions.filter { !$0.experimental })
        let experimentalRows = tableRowsFromRegions(acceptableRegions.filter { $0.experimental })

        let autoSelectRow = buildAutoSelectRow()

        var sections = [OBATableSection]()

        sections.append(OBATableSection.init(title: nil, rows: [autoSelectRow]))

        if customRows.count > 0 {
            sections.append(OBATableSection.init(title: NSLocalizedString("msg_custom_regions", comment: ""), rows: customRows))
        }

        sections.append(OBATableSection.init(title: NSLocalizedString("msg_active_regions", comment: ""), rows: activeRows))

        if experimentalRows.count > 0 && OBACommon.debugMode {
            sections.append(OBATableSection.init(title: NSLocalizedString("region_list_controller.experimental_section_title", comment: ""), rows: experimentalRows))
        }

        self.sections = sections
        tableView.reloadData()
    }

    private func buildAutoSelectRow() -> OBASwitchRow {
        let autoSelectRow = OBASwitchRow.init(title: NSLocalizedString("msg_automatically_select_region", comment: ""), action: { _ in
            self.application.modelDao.automaticallySelectRegion = !self.application.modelDao.automaticallySelectRegion

            if self.application.modelDao.automaticallySelectRegion {
                if let refresh = self.application.regionHelper.refreshData() {
                    SVProgressHUD.show()
                    refresh.then { _ -> Void in
                        // no-op?
                    }.always {
                        SVProgressHUD.dismiss()
                    }
                }
            }
            else {
                self.loadData()
            }
        }, switchValue: application.modelDao.automaticallySelectRegion)

        return autoSelectRow
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
            let autoSelect = application.modelDao.automaticallySelectRegion
            let row = OBATableRow.init(title: region.regionName) { _ in
                if autoSelect {
                    return
                }
                self.application.modelDao.currentRegion = region
                self.loadData()

                if let delegate = self.delegate {
                    delegate.regionSelected()
                }
            }

            row.model = region
            row.deleteModel = { row in
                let alert = UIAlertController.init(title: NSLocalizedString("msg_ask_delete_region", comment: ""), message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: OBAStrings.cancel, style: .cancel, handler: nil))
                alert.addAction(UIAlertAction.init(title: OBAStrings.delete, style: .destructive, handler: { _ in
                    self.application.modelDao.removeCustomRegion(region)
                }))
                self.present(alert, animated: true, completion: nil)
            }

            if autoSelect {
                row.titleColor = OBATheme.darkDisabledColor
                row.selectionStyle = .none
            }

            if application.modelDao.currentRegion?.identifier == region.identifier {
                row.accessoryType = .checkmark
            }

            return row
        }
    }
}
