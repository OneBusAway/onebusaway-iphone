//
//  PIIViewController.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/1/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import UIKit
import OBAKit

class PIIViewController: OBAStaticTableViewController {

    lazy var privacyBroker: PrivacyBroker = {
        return OBAApplication.shared().privacyBroker
    }()

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("msg_information_for_support", comment: "Title of the PIIViewController")

        self.tableView.tableHeaderView = OBAUIBuilder.footerView(withText: NSLocalizedString("msg_explanatory_information_send_on_submit_request", comment: "The footer label on the PIIViewController"), maximumWidth: self.tableView.frame.width)

        self.reloadData()

//        self.tableFooterView = OBAUIBuilder.footerView(text: NSLocalizedString("This information is only sent to OneBusAway when you submit a support request. You can disable sending us any or all of this data, but it will limit our ability to diagnose and fix problems you are experiencing.", comment: "The footer label on the PIIViewController"), maximumWidth: self.tableView.frame.width)
    }

    // MARK: - Table Sections

    func reloadData() {
        let regionSection = self.buildRegionSection()
        let locationSection = self.buildLocationSection()
        let logsSection = self.buildLogsSection()

        self.sections = [regionSection, locationSection, logsSection]
        self.tableView.reloadData()
    }

    func buildRegionSection() -> OBATableSection {
        let regionSection = OBATableSection.init(title: NSLocalizedString("msg_region", comment: "Region section title on PII controller"))

        regionSection.addRow {
            return OBASwitchRow.init(title: NSLocalizedString("msg_share_current_region", comment: "Region switch row on PII Controller"), action: {
                self.privacyBroker.toggleShareRegionInformation()
                self.reloadData()
            }, switchValue: self.privacyBroker.canShareRegionInformation)
        }

        regionSection.addRow {
            let row: OBATableRow = OBATableRow.init(title: NSLocalizedString("msg_view_data", comment: "View data row on PII controller"), action: {
                self.showData(self.privacyBroker.shareableRegionInformation().description)
            })
            row.accessoryType = .disclosureIndicator

            return row
        }

        return regionSection
    }

    func buildLocationSection() -> OBATableSection {
        let locationSection = OBATableSection.init(title: NSLocalizedString("msg_location", comment: "Location section title on PII controller"))

        locationSection.addRow {
            return OBASwitchRow.init(title: NSLocalizedString("msg_share_location", comment: "Location switch row on PII Controller"), action: {
                self.privacyBroker.toggleShareLocationInformation()
                self.reloadData()
                }, switchValue: self.privacyBroker.canShareLocationInformation)
        }

        locationSection.addRow {
            let row: OBATableRow = OBATableRow.init(title: NSLocalizedString("msg_view_data", comment: "View data row on PII controller"), action: {
                var locationInfo = self.privacyBroker.shareableLocationInformation
                if locationInfo == nil {
                    locationInfo = "NOPE"
                }

                self.showData(locationInfo!)
            })
            row.accessoryType = .disclosureIndicator

            return row
        }

        return locationSection
    }

    func buildLogsSection() -> OBATableSection {
        let shareRow = OBASwitchRow.init(title: NSLocalizedString("msg_share_logs", comment: "Share logs action row title in the PII controller"), action: {
            self.privacyBroker.toggleShareLogs()
            self.reloadData()
        }, switchValue: self.privacyBroker.canShareLogs)

        let viewDataRow = OBATableRow.init(title: NSLocalizedString("msg_view_data", comment: "View data row on PII controller"), action: {
            let logController = PTERootController.init()
            self.navigationController?.pushViewController(logController, animated: true)
        })
        viewDataRow.accessoryType = .disclosureIndicator

        let section = OBATableSection.init(title: NSLocalizedString("msg_logs", comment: "Logs table section in the PII controller"), rows: [shareRow, viewDataRow])
        return section
    }

    // MARK: - Data Display

    func showData(_ data: String) {
        let alert = UIAlertController.init(title: nil, message: data, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: OBAStrings.dismiss(), style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
