//
//  DrawerNavigationBar.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 8/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import SnapKit

@objc(OBADrawerNavigationBar)
public class DrawerNavigationBar: UIView {
    @objc public private(set)
    lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "close_circle"), for: .normal)
        button.accessibilityLabel = OBAStrings.close

        return button
    }()

    private lazy var closeButtonWrapper: UIView = {
        let wrapper = closeButton.oba_embedInWrapperView(withConstraints: false)
        wrapper.clipsToBounds = true
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(35)
            make.leading.top.trailing.equalToSuperview()
        }
        return wrapper
    }()

    @objc public private(set)
    lazy var titleLabel: UILabel = {
        let label = UILabel.oba_autolayoutNew()
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.font = OBATheme.headlineFont

        return label
    }()

    @objc public private(set)
    lazy var subtitleLabel: UILabel = {
        let label = UILabel.oba_autolayoutNew()
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.font = OBATheme.subheadFont
        return label
    }()

    private lazy var grabHandle: GrabHandle = {
        let handle = GrabHandle.oba_autolayoutNew()
        handle.snp.makeConstraints { $0.height.equalTo(4) }
        return handle
    }()

    private let kUseDebugColors = false

    public override init(frame: CGRect) {
        super.init(frame: frame)

        layer.shadowRadius = 1.0
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3

        let labelStack = UIStackView.oba_verticalStack(withArrangedSubviews: [titleLabel, subtitleLabel])
        let labelStackWrapper = labelStack.oba_embedInWrapper()

        let horizStack = UIStackView.oba_horizontalStack(withArrangedSubviews: [labelStackWrapper, closeButtonWrapper])
        let horizWrapper = horizStack.oba_embedInWrapper()

        let outerStack = UIStackView.oba_verticalStack(withArrangedSubviews: [grabHandle, horizWrapper])
        outerStack.spacing = OBATheme.compactPadding
        addSubview(outerStack)
        outerStack.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(OBATheme.defaultEdgeInsets)
        }

        if kUseDebugColors {
            backgroundColor = .yellow
            titleLabel.backgroundColor = .magenta
            subtitleLabel.backgroundColor = .purple
            grabHandle.backgroundColor = .green
        }
    }

    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// Drop Shadow
extension DrawerNavigationBar {
    @objc public func hideDrawerNavigationBarShadow() {
        layer.shadowOpacity = 0.0
    }

    @objc public func showDrawerNavigationBarShadow() {
        layer.shadowOpacity = 0.3
    }
}
