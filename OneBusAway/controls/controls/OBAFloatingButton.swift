//
//  OBAFloatingButton.swift
//  org.onebusaway.iphone
//
//  Created by Alan Chu on 1/6/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import UIKit

@IBDesignable
open class OBAFloatingButton: UIButton {
    override open var intrinsicContentSize: CGSize {
        return CGSize(width: 40, height: 40)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    private func configure() {
        self.backgroundColor = OBATheme.color(withRed: 247, green: 245, blue: 247, alpha: 1.0)

        self.showsTouchWhenHighlighted = true
        self.reversesTitleShadowWhenHighlighted = true

        self.layer.cornerRadius = OBATheme.compactPadding()
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize.zero
        self.layer.shadowRadius = 2
        self.layer.shadowOpacity = 0.25
    }
}
