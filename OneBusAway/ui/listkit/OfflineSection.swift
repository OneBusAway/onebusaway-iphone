//
//  OfflineSection.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 5/28/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import IGListKit

class OfflineSection: NSObject, ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        return self
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return object is OfflineSection
    }
}

class OfflineCell: SelfSizingCollectionCell {
    fileprivate let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .magenta

        contentView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(OBATheme.defaultEdgeInsets)
        }

        label.text = "you're offline!"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


final class OfflineSectionController: ListSectionController {
    var data: OfflineSection?

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
            let cell = ctx.dequeueReusableCell(of: OfflineCell.self, for: self, at: index) as? OfflineCell
            else {
                fatalError()
        }
        return cell
    }
}
