//
//  AlertPresenterView.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 9/23/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import UIKit
import SwiftMessages
import SnapKit

class AlertPresenterView: MessageView {

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.titleLabel = UILabel.init()
        self.titleLabel?.numberOfLines = 0
        self.titleLabel?.font = OBATheme.largeTitleFont

        self.bodyLabel = UILabel.init()
        self.bodyLabel?.numberOfLines = 0
        self.bodyLabel?.font = OBATheme.bodyFont

        self.button = UIButton(type: .system)
        self.button?.titleLabel?.font = OBATheme.boldBodyFont
        self.button?.layer.cornerRadius = 0
        self.button?.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(30)
        }

        let labelStack = UIStackView.init(arrangedSubviews: [self.titleLabel!, self.bodyLabel!])
        labelStack.spacing = OBATheme.defaultPadding
        labelStack.axis = .vertical

        let labelStackWrapper = UIView.init()
        labelStackWrapper.addSubview(labelStack)
        labelStack.snp.makeConstraints { (make) in
            let inset = UIEdgeInsets(top: OBATheme.defaultMargin, left: OBATheme.defaultMargin, bottom: 0, right: OBATheme.defaultMargin)
            make.edges.equalToSuperview().inset(inset)
        }

        let spacer = UIView.init()
        spacer.snp.makeConstraints { (make) in
            make.height.equalTo(OBATheme.defaultPadding)
        }

        let outerStack = UIStackView.init(arrangedSubviews: [labelStackWrapper, spacer, self.button!])
        outerStack.axis = .vertical
        self.addSubview(outerStack)
        outerStack.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    public func configureTheme(_ theme: Theme) {
        super.configureTheme(theme, iconStyle: .default)

        if theme == .error {
            self.backgroundColor = OBATheme.color(withRed: 255, green: 90, blue: 69, alpha: 0.8)
        }

        if let button = self.button {
            button.backgroundColor = self.backgroundColor
            button.setTitleColor(self.titleLabel?.textColor, for: .normal)

            button.contentEdgeInsets = UIEdgeInsets(top: 7.0, left: 7.0, bottom: 7.0, right: 7.0)
            button.contentEdgeInsets = .zero
            button.layer.cornerRadius = 0
        }

        self.configureDropShadow()
    }
}
