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
        if Sweep.hasSafeAreaInsets {
            return CGFloat(92.0)
        }
        else {
            return CGFloat(64.0) // abxoxo - todo come up with a better value for this.
        }
    }

    public static var collectionViewContentInset: CGFloat {
        if Sweep.hasSafeAreaInsets {
            let anotherRandomConstant = CGFloat(200.0)
            return anotherRandomConstant
        }
        else {
            let abxoxoRandomConstant = CGFloat(160.0) /// abxoxo - change this
            return abxoxoRandomConstant
        }
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

    /// Returns true when running on iPhone X-like devices... i.e. ones without home buttons.
    private class var hasSafeAreaInsets: Bool {
        if #available(iOS 11.0, tvOS 11.0, *) {
            return UIApplication.shared.delegate?.window??.safeAreaInsets != .zero
        }
        return false
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
