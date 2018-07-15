//
//  UserDefaultsBrowserViewController.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 4/10/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import UIKit
import OBAKit

// swiftlint:disable force_cast

class UserDefaultsBrowserViewController: OBAStaticTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("user_defaults_browser_controller.title", comment: "Title for the user defaults browser")

        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .refresh, target: self, action: #selector(reloadData))

        self.reloadData()
    }

    @objc func reloadData() {
        let section = OBATableSection.init(title: nil)

        let dictionaryRep = OBAApplication.shared().userDefaults.dictionaryRepresentation()
        section.rows = dictionaryRep.keys.sorted().map { key -> OBATableRow in
            let value = dictionaryRep[key]
            let row = OBATableRow.init(title: key) { _ in
                self.visualizeKey(key, value: value)
            }
            row.subtitle = (value as! NSObject).description
            row.style = .subtitle

            return row
        }

        self.sections = [section]
        self.tableView.reloadData()
    }

    private func visualizeKey(_ key: String, value: Any?) {
        guard let value = value else {
            return
        }

        if value is Data {
            let unarchiver = NSKeyedUnarchiver.init(forReadingWith: value as! Data)
            let obj = unarchiver.decodeObject(forKey: key)
            unarchiver.finishDecoding()

            let msg = (obj as! NSObject).description

            self.showAlert(title: key, message: msg)
        }
        else {
            self.showAlert(title: key, message: (value as! NSObject).description)
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: OBAStrings.dismiss, style: .default, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
}
