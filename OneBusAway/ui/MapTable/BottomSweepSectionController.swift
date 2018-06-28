//
//  BottomSweepSectionController.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 5/18/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//


import IGListKit
import OBAKit
import UIKit

final class Sweep: NSObject, ListDiffable {

    public static func defaultHeight(collectionViewBounds: CGRect) -> CGFloat {
        return CGFloat(64.0) // abxoxo - todo come up with a better value for this.
    }

    let height: CGFloat

    convenience init(collectionViewBounds: CGRect) {
        self.init(height: Sweep.defaultHeight(collectionViewBounds: collectionViewBounds))
    }

    init(height: CGFloat) {
        self.height = height
    }

    func diffIdentifier() -> NSObjectProtocol {
        return self
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return self.isEqual(toDiffableObject: object)
    }
}

final class BottomSweepSectionController: ListSectionController {
    private var sweep: Sweep = Sweep(height: 0)

    override func sizeForItem(at index: Int) -> CGSize {
        let width = collectionContext?.containerSize.width ?? 0
        return CGSize(width: width, height: sweep.height)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard
            let ctx = collectionContext
        else {
            fatalError()
        }

        let sweepCell = ctx.dequeueReusableCell(of: UICollectionViewCell.self, for: self, at: index)
        sweepCell.backgroundColor = OBATheme.mapTableBackgroundColor
        return sweepCell
    }

    override func didUpdate(to object: Any) {
        precondition(object is Sweep)
        sweep = object as! Sweep
    }
}
