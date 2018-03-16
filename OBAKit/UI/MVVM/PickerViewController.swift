//
//  PickerViewController.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 1/4/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit

@objc public class PickerViewController: OBAStaticTableViewController {

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.showsLoadingPlaceholderRows = false
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)

        for cell in tableView.visibleCells {
            cell.accessoryType = .none
        }

        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark

        self.dismiss(animated: true, completion: nil)
    }
}
