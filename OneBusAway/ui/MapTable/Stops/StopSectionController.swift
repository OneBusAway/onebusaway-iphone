//
//  StopSectionController.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 5/23/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import IGListKit
import OBAKit

class StopSectionController: ListSectionController {
    var data: StopViewModel?

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
            let cell = ctx.dequeueReusableCell(of: StopCell.self, for: self, at: index) as? StopCell
            else {
                fatalError()
        }
        cell.stopViewModel = data

        return cell
    }

    override func didUpdate(to object: Any) {
        precondition(object is StopViewModel)
        data = object as? StopViewModel
    }

    override func didSelectItem(at index: Int) {
        guard
            let data = data,
            let viewController = viewController
        else {
            return
        }

        let stopController = StopViewController(stopID: data.stopID)
        viewController.navigationController?.pushViewController(stopController, animated: true)
    }
}
