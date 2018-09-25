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

@objc(OBARegionalAlertsViewController)
class RegionalAlertsViewController: OBAStaticTableViewController {

    private var agencyAlerts: [AgencyAlert] = []

    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl.init()
        refresh.addTarget(self, action: #selector(reloadServerData), for: .valueChanged)
        return refresh
    }()

    private let application: OBAApplication

    private let language = "en" // abxoxo - todo FIXME

    @objc init(application: OBAApplication) {
        self.application = application

        super.init(nibName: nil, bundle: nil)

        hidesBottomBarWhenPushed = true
        let spacer = UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let markReadButton = UIBarButtonItem.init(title: NSLocalizedString("regional_alerts_controller.mark_all_as_read", comment: "Mark All as Read toolbar button title"), style: .plain, target: self, action: #selector(markAllAsRead))
        toolbarItems = [spacer, markReadButton]
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.addSubview(refreshControl)

        emptyDataSetDescription = NSLocalizedString("regional_alerts_controller.empty_description", comment: "Empty data set description for regional alerts controller")

        if let regionName = application.modelDao.currentRegion?.regionName {
            let titleFormat = NSLocalizedString("regional_alerts_controller.title_format", comment: "Alerts for <REGION NAME>")
            title = String.init(format: titleFormat, regionName)
        }

        reloadServerData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }

    // MARK: - Actions

    private func presentAlert(_ alert: AgencyAlert) {
        application.modelDao.markAlert(asRead: alert)

        if let url = alert.url(language: language) {
            let safari = SFSafariViewController.init(url: url)
            present(safari, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController.init(title: alert.title(language: language), message: alert.body(language: language), preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: OBAStrings.dismiss, style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }

        self.reloadData()
    }

    @objc private func markAllAsRead() {
        for alert in agencyAlerts {
            application.modelDao.markAlert(asRead: alert)
        }
        reloadData()
    }

    // MARK: - Data Loading

    @objc private func reloadServerData() {
        application.modelService.requestRegionalAlerts().then { alerts -> Void in
            self.agencyAlerts = alerts
            self.reloadData()
        }.catch { [weak self] error in
            AlertPresenter.showError(error as NSError, presentingController: self)
            print("error \(error)")
        }
    }

    @objc private func reloadData() {
        let rows = agencyAlerts.map { alert -> OBAMessageRow in
            let tableRow = OBAMessageRow.init { _ in self.presentAlert(alert) }
            tableRow.accessoryType = .disclosureIndicator
            if let name = alert.agency?.agency?.name {
                tableRow.sender = name
            }
            if let subject = alert.title(language: language) {
                tableRow.subject = subject
            }

            tableRow.unread = application.modelDao.isAlertUnread(alert)

            return tableRow
        }

        let section = OBATableSection.init(title: nil, rows: rows)
        self.sections = [section]
        self.refreshControl.endRefreshing()
        self.tableView.reloadData()
    }
}
