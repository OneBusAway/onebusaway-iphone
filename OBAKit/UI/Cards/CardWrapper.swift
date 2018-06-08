//
//  CardWrapper.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 5/23/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import SnapKit

@objc(OBACardWrapper)
public class CardWrapper: UIView {

    @objc public let contentView = UIView.init()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = OBATheme.compactCornerRadius
        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = 1.0
        layer.shadowOpacity = 0.2
    }

    public required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()

        layer.shadowPath = UIBezierPath.init(roundedRect: bounds, cornerRadius: OBATheme.compactCornerRadius).cgPath
    }
}
