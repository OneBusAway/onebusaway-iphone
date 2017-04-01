//
//  RegionalAlertsViewController.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/16/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import Foundation
import OBAKit
import SafariServices

class RegionalAlertsViewController: OBAStaticTableViewController {

    var regionalAlertsManager: RegionalAlertsManager

    init(regionalAlertsManager: RegionalAlertsManager) {
        self.regionalAlertsManager = regionalAlertsManager

        super.init(nibName: nil, bundle: nil)
    }

    let refreshControl = UIRefreshControl.init()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.refreshControl.addTarget(self, action: #selector(reloadServerData), for: .valueChanged)
        self.tableView.addSubview(self.refreshControl)

        self.emptyDataSetDescription = NSLocalizedString("regional_alerts_controller.empty_description", comment: "Empty data set description for regional alerts controller")

        if let regionName = self.regionalAlertsManager.region?.regionName {
            let titleFormat = NSLocalizedString("regional_alerts_controller.title_format", comment: "Alerts for <REGION NAME>")
            self.title = String.init(format: titleFormat, regionName)
        }

        self.reloadData()

        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: RegionalAlertsManager.regionalAlertsUpdatedNotification, object: nil)
    }

    // MARK: - Data Loading

    @objc private func reloadServerData() {
        self.regionalAlertsManager.update()
    }

    @objc private func reloadData() {
        let rows = self.regionalAlertsManager.regionalAlerts.map { alert -> OBAMessageRow in
            let tableRow = OBAMessageRow.init(action: { (row) in
                let safari = SFSafariViewController.init(url: alert.url)
                safari.modalPresentationStyle = .overFullScreen
                self.present(safari, animated: true) {
                    self.regionalAlertsManager.markRead(alert)
                    self.reloadData()
                }
            })
            tableRow.accessoryType = .disclosureIndicator
            tableRow.date = alert.publishedAt
            tableRow.sender = alert.feedName
            tableRow.subject = alert.title
            tableRow.unread = alert.unread
            tableRow.highPriority = alert.priority == .high

            return tableRow
        }

        let section = OBATableSection.init(title: nil, rows: rows)
        self.sections = [section]
        self.refreshControl.endRefreshing()
        self.tableView.reloadData()
    }
}
