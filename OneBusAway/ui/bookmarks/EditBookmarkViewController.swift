//
//  EditBookmarkViewController.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 8/4/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import OBAKit

@objc(OBAEditBookmarkViewController)
public class EditBookmarkViewController: OBAStaticTableViewController {

    // MARK: - Model Data
    let modelDAO: OBAModelDAO
    let bookmark: OBABookmarkV2
    var selectedGroup: OBABookmarkGroup? {
        willSet {
            guard let selection = selectedGroup,
                  let indexPath = indexPath(forModel: selection),
                  let cell = tableView.cellForRow(at: indexPath)
            else {
                deselectNoGroupCell()
                return
            }

            cell.accessoryType = .none
        }

        didSet {
            guard let selection = selectedGroup,
                let indexPath = indexPath(forModel: selection),
                let cell = tableView.cellForRow(at: indexPath)
            else {
                return
            }

            cell.accessoryType = .checkmark
        }
    }

    var noGroupRow: OBATableRow?

    // MARK: - Table Data

    let textFieldData = NSMutableDictionary()
    let textFieldRow: OBATextFieldRow = {
        let text = NSLocalizedString("edit_bookmark.bookmark_name_label", comment: "Label for the Bookmark Name text field")
        let row = OBATextFieldRow.init(labelText: text, textFieldText: nil)
        row.dataKey = "name"
        return row
    }()

    // MARK: - Init

    @objc public init(bookmark: OBABookmarkV2, modelDAO: OBAModelDAO) {
        self.bookmark = bookmark
        self.selectedGroup = self.bookmark.group

        self.modelDAO = modelDAO

        self.textFieldRow.textFieldText = bookmark.name
        self.textFieldRow.model = self.textFieldData

        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Data
extension EditBookmarkViewController {
    private func reloadData() {
        let nameSection = OBATableSection(title: nil, rows: [textFieldRow])
        let groupsSection = buildGroupsSection()
        let addGroupSection = buildAddGroupSection()

        sections = [nameSection, groupsSection, addGroupSection]

        tableView.reloadData()
    }

    private func buildAddGroupSection() -> OBATableSection {
        let text = NSLocalizedString("edit_bookmark.add_bookmark_group_label", comment: "Label for the Add Bookmark Group section")
        let addGroupRow = OBAButtonRow(title: text) { _ in
            let alert = OBAAlerts.buildAddBookmarkGroupAlert(with: self.modelDAO) {
                self.reloadData()
            }
            self.present(alert, animated: true, completion: nil)
        }
        addGroupRow.buttonColor = OBATheme.obaDarkGreen

        return OBATableSection(title: nil, rows: [addGroupRow])
    }

    private func buildGroupsSection() -> OBATableSection {
        var groups = modelDAO.bookmarkGroups.map { group -> OBATableRow in
            let row = OBATableRow(title: group.name) { r in
                self.selectedGroup = r.model as? OBABookmarkGroup
            }
            row.model = group
            row.accessoryType = selectedGroup == group ? .checkmark : .none
            return row
        }

        let text = NSLocalizedString("edit_bookmark.no_group_label", comment: "Label for the 'No Group' table row")
        let noGroupRow = OBATableRow(title: text) { _ in
            self.selectedGroup = nil
        }

        noGroupRow.titleFont = OBATheme.italicBodyFont
        noGroupRow.accessoryType = selectedGroup == nil ? .checkmark : .none

        groups.append(noGroupRow)
        self.noGroupRow = noGroupRow

        let groupsSectionTitle = NSLocalizedString("edit_bookmark.bookmark_group_header", comment: "Bookmark Group section header")
        let groupsSection = OBATableSection(title: groupsSectionTitle, rows: groups)

        return groupsSection
    }

    private func deselectNoGroupCell() {
        guard let row = self.noGroupRow,
              let indexPath = indexPath(for: row),
              let cell = tableView.cellForRow(at: indexPath)
        else {
            return
        }

        cell.accessoryType = .none
    }
}

// MARK: - UIViewController
extension EditBookmarkViewController {
    override public func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("edit_bookmark.title", comment: "OBABookmarkEditExisting")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))

        reloadData()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let indexPath = indexPath(for: self.textFieldRow),
              let cell = tableView.cellForRow(at: indexPath) as? OBATextFieldCell
        else {
            return
        }

        cell.textField.becomeFirstResponder()
    }
}

// MARK: - UITableView
extension EditBookmarkViewController {
    public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard self.row(at: indexPath) is OBAButtonRow else {
            return
        }

        cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width / 2.0, bottom: 0, right: tableView.bounds.width / 2.0)
    }
}

// MARK: - Actions
extension EditBookmarkViewController {
    @objc private func cancel() {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }

    @objc private func save() {
        view.endEditing(true)

        if let text = textFieldData["name"] as? String {
            bookmark.name = text
        }

        guard bookmark.isValidModel() else {
            let title = NSLocalizedString("msg_cant_create_bookmark", comment: "Title of the alert shown when a bookmark can't be created")
            let body = NSLocalizedString("msg_alert_bookmarks_must_have_name", comment: "Body of the alert shown when a bookmark can't be created.")
            AlertPresenter.showWarning(title, body: body)
            return
        }

        if bookmark.group == nil && selectedGroup == nil {
            modelDAO.saveBookmark(bookmark)
        }
        else {
            modelDAO.moveBookmark(bookmark, to: selectedGroup)
        }

        dismiss(animated: true, completion: nil)
    }
}
