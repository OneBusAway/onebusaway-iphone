//
//  SectionHeaderCell.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 5/24/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import IGListKit

class SectionHeader: NSObject, ListDiffable {

    let text: String
    init(text: String) {
        self.text = text
    }
    func diffIdentifier() -> NSObjectProtocol {
        return self
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard
            let object = object as? SectionHeader
        else {
            return false
        }

        return self.text == object.text
    }
}

class SectionHeaderCell: SelfSizingCollectionCell {
    fileprivate let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = OBATheme.boldSubheadFont
        return label
    }()

    var text: String? {
        get {
            return label.text
        }
        set {
            label.text = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(OBATheme.defaultEdgeInsets)
        }
        contentView.backgroundColor = OBATheme.mapTableBackgroundColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


final class SectionHeaderSectionController: ListSectionController {
    var data: SectionHeader?

    override init() {
        super.init()
        inset = .zero
    }

    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: collectionContext!.containerSize.width, height: 55)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard
            let ctx = collectionContext,
            let data = data,
            let cell = ctx.dequeueReusableCell(of: SectionHeaderCell.self, for: self, at: index) as? SectionHeaderCell
            else {
                fatalError()
        }

        cell.text = data.text
        return cell
    }

    override func didUpdate(to object: Any) {
        precondition(object is SectionHeader)
        data = object as? SectionHeader
    }
}
