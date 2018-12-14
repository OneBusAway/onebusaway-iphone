//
//  OccupancyStatusView.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 12/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import SnapKit

@objc(OBAOccupancyStatusView)
public class OccupancyStatusView: UIView {
    private let leftImageView = OccupancyStatusView.buildImageView()
    private let centerImageView = OccupancyStatusView.buildImageView()
    private let rightImageView = OccupancyStatusView.buildImageView()
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [leftImageView, centerImageView, rightImageView])
        stack.axis = .horizontal

        return stack
    }()

    public init(image: UIImage) {
        super.init(frame: .zero)

        accessibilityElementsHidden = true

        backgroundColor = UIColor(white: 0.98, alpha: 1.0)

        leftImageView.image = image
        centerImageView.image = image
        rightImageView.image = image

        addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    public required init?(coder aDecoder: NSCoder) { fatalError() }

    private static func buildImageView() -> UIImageView {
        let imageView = UIImageView.oba_autolayoutNew()
        imageView.tintColor = .darkGray
        return imageView
    }

    public var occupancyStatus: OBAOccupancyStatus = .unknown {
        didSet {
            if occupancyStatus == .unknown {
                isHidden = true
                return
            }

            leftImageView.isHidden = true
            centerImageView.isHidden = true
            rightImageView.isHidden = true
            isHidden = false

            switch occupancyStatus {
            case .full:
                leftImageView.isHidden = false
                centerImageView.isHidden = false
                rightImageView.isHidden = false
            case .standingAvailable:
                leftImageView.isHidden = false
                centerImageView.isHidden = false
            case .seatsAvailable:
                leftImageView.isHidden = false
            default: break
            }
        }
    }
}
