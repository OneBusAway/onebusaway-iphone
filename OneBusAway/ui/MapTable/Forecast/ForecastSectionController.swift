//
//  ForecastSectionController.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 5/21/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import IGListKit
import UIKit

class ForecastSectionController: ListSectionController {
    var data: WeatherForecast?

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
            let cell = ctx.dequeueReusableCell(of: ForecastCell.self, for: self, at: index) as? ForecastCell
            else {
                fatalError()
        }
        cell.forecast = data

        return cell
    }

    override func didUpdate(to object: Any) {
        precondition(object is WeatherForecast)
        data = object as? WeatherForecast
    }
}
