//
//  GrabHandle.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 8/27/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit

@objc(OBAGrabHandle)
public class GrabHandle: UIView {
    override public var intrinsicContentSize: CGSize {
        let sz = super.intrinsicContentSize
        return CGSize(width: sz.width, height: 4)
    }

    private let handleLayer: CAShapeLayer = {
        let handle = CAShapeLayer()
        handle.bounds = CGRect(x: 0, y: 0, width: 30, height: 4)
        handle.fillColor = UIColor.lightGray.cgColor
        handle.path = UIBezierPath.init(roundedRect: handle.bounds, cornerRadius: 4.0).cgPath

        return handle
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.addSublayer(handleLayer)
    }

    required public init?(coder aDecoder: NSCoder) { fatalError() }

    override public func layoutSubviews() {
        super.layoutSubviews()
        let x = (frame.width / 2.0) - (handleLayer.frame.width / 2.0)
        let y = (frame.height / 2.0) - (handleLayer.frame.height / 2.0)
        handleLayer.frame = CGRect(x: x, y: y, width: handleLayer.frame.width, height: handleLayer.frame.height)
    }
}
