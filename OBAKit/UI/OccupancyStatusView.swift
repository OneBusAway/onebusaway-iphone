//
//  OccupancyStatusView.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 12/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit

@objc(OBAOccupancyStatusView)
public class OccupancyStatusView: UIView {

    private let image: UIImage

    @objc public init(image: UIImage) {
        self.image = image

        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var intrinsicContentSize: CGSize {
        return CGSize(width: 12.0 * CGFloat(maxSilhouetteCount), height: 12.0)
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        let background = isHighlighted ? UIColor.clear : UIColor(white: 0.98, alpha: 1.0)
        background.set()
        UIRectFill(rect)

        let imageWidth = Int(rect.width / CGFloat(maxSilhouetteCount))

        for i in 0..<silhouetteCount {
            let imageRect = CGRect(x: i * imageWidth, y: 0, width: imageWidth, height: Int(image.size.height))
            image.draw(in: imageRect)
        }
    }

    private let maxSilhouetteCount = 3

    private var silhouetteCount: Int {
        switch occupancyStatus {
        case .seatsAvailable: return 1
        case .standingAvailable: return 2
        case .full: return 3
        default: return 0
        }
    }

    @objc public var occupancyStatus: OBAOccupancyStatus = .unknown {
        didSet {
            isHidden = (occupancyStatus == .unknown)
            setNeedsDisplay()
        }
    }

    @objc public var isHighlighted = false {
        didSet {
            setNeedsDisplay()
        }
    }
}
