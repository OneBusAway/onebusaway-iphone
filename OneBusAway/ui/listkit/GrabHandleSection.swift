//
//  GrabHandleSection.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 8/27/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import IGListKit
import SnapKit

class GrabHandleSection: NSObject, ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        return self
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return object is GrabHandleSection
    }
}

class GrabHandleCell: SelfSizingCollectionCell {
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = OBATheme.mapTableBackgroundColor

        let grabHandle = GrabHandle.oba_autolayoutNew()

        contentView.addSubview(grabHandle)
        grabHandle.snp.makeConstraints { (make) in
            make.height.equalTo(4)
            make.edges.equalToSuperview().inset(OBATheme.defaultEdgeInsets)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class GrabHandleSectionController: ListSectionController {
    var data: GrabHandleSection?

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
            let cell = ctx.dequeueReusableCell(of: GrabHandleCell.self, for: self, at: index) as? GrabHandleCell
            else {
                fatalError()
        }
        return cell
    }
}
