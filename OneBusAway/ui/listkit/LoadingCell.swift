//
//  LoadingCell.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 5/28/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import IGListKit

class LoadingSection: NSObject, ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        return self
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return object is LoadingSection
    }
}

class LoadingCell: SelfSizingCollectionCell {
    fileprivate let shimmeringView = FBShimmeringView()
    fileprivate let placeholderView = OBAPlaceholderView(numberOfLines: 3)

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .magenta

        contentView.addSubview(shimmeringView)
        shimmeringView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(OBATheme.defaultEdgeInsets)
        }

        shimmeringView.contentView = placeholderView
        placeholderView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        shimmeringView.isShimmering = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


final class LoadingSectionController: ListSectionController {
    var data: LoadingSection?

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
            let cell = ctx.dequeueReusableCell(of: LoadingCell.self, for: self, at: index) as? LoadingCell
            else {
                fatalError()
        }
        return cell
    }
}
