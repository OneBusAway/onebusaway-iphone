//
//  TableRowController.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 9/12/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import IGListKit
import OBAKit
import UIKit

class TableRowCell: ChevronCardCell {
    var tableRow: TableRowModel? {
        didSet {
            guard let tableRow = tableRow else {
                return
            }

            titleLabel.text = tableRow.title
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        titleLabel.text = nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentWrapper.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(OBATheme.defaultEdgeInsets)
        }

        contentWrapper.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(44.0).priority(.medium)
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Properties

    private let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()
}

class TableRowModel: NSObject, ListDiffable {
    let title: String
    let action: (() -> Void)?

    init(title: String, action: (() -> Void)?) {
        self.title = title
        self.action = action
    }

    // MARK: - ListDiffable

    func diffIdentifier() -> NSObjectProtocol {
        return "tablerow_\(title)" as NSObjectProtocol
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard self !== object else { return true }
        guard let object = object as? TableRowModel else { return false }
        return title == object.title
    }
}

class TableRowController: ListSectionController {
    var data: TableRowModel?

    override init() {
        super.init()
        inset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
    }

    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: collectionContext!.containerSize.width, height: 55)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard
            let ctx = collectionContext,
            let data = data,
            let cell = ctx.dequeueReusableCell(of: TableRowCell.self, for: self, at: index) as? TableRowCell
            else {
                fatalError()
        }
        cell.tableRow = data

        return cell
    }

    override func didUpdate(to object: Any) {
        precondition(object is TableRowModel)
        data = object as? TableRowModel
    }

    override func didSelectItem(at index: Int) {
        data?.action?()
    }
}
