//
//  AlertView.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 4/17/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import UIKit
import SwiftMessages
import SnapKit

typealias AlertViewAction = () -> Void

class AlertView: UIView, Identifiable {

    public class func presentAlert(title: String, body: String, actionTitle: String, action: @escaping () -> Void) {
        var config = SwiftMessages.Config()
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        config.duration = .forever
        config.dimMode = .gray(interactive: true)
        config.interactiveHide = true
        config.preferredStatusBarStyle = .lightContent

        let view = AlertView.init()
        view.titleLabel.text = title
        view.bodyLabel.text = body
        view.actionButton.setTitle(actionTitle, for: .normal)
        view.actionButtonTapped = action

        SwiftMessages.show(config: config, view: view)
    }

    // MARK: - Properties

    let wrapperView = UIView.init()

    public let titleLabel = UILabel.init()
    public let bodyLabel = UILabel.init()

    private let dismissButton = UIButton.init(type: .system)
    public let actionButton = UIButton.init(type: .system)
    private let buttonStack = UIStackView.init()

    private let outerStack = UIStackView.init()

    public var actionButtonTapped: AlertViewAction?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.configureUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Identifiable

    public var id: String {
        get {
            return "AlertView"
        }
    }

    // MARK: - UI Configuration

    private func configureUI() {
        self.wrapperView.layer.cornerRadius = OBATheme.defaultCornerRadius
        self.configureDropShadow()

        self.titleLabel.font = OBATheme.subtitleFont
        self.titleLabel.numberOfLines = 0
        self.outerStack.addArrangedSubview(self.titleLabel)

        self.bodyLabel.numberOfLines = 0
        self.bodyLabel.font = OBATheme.bodyFont
        self.outerStack.addArrangedSubview(self.bodyLabel)

        self.configureButtons()
        self.outerStack.addArrangedSubview(self.buttonStack)

        self.outerStack.axis = .vertical
        self.outerStack.spacing = OBATheme.defaultPadding
        self.wrapperView.addSubview(self.outerStack)

        outerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(OBATheme.defaultPadding)
        }

        self.addSubview(self.wrapperView)
        self.wrapperView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(OBATheme.defaultMargin)
        }
        self.wrapperView.backgroundColor = UIColor.white
    }

    private func configureButtons() {
        self.dismissButton.setTitle(OBAStrings.dismiss, for: .normal)
        self.dismissButton.titleLabel?.font = OBATheme.boldBodyFont
        self.dismissButton.setTitleColor(UIColor.darkText, for: .normal)
        self.dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        self.buttonStack.addArrangedSubview(self.dismissButton)

        self.actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        self.actionButton.titleLabel?.font = OBATheme.boldBodyFont

        self.buttonStack.addArrangedSubview(self.actionButton)
        self.buttonStack.axis = .horizontal
        self.buttonStack.distribution = .fillEqually
        self.buttonStack.spacing = OBATheme.defaultPadding
    }

    @objc private func actionTapped() {
        SwiftMessages.hide(id: self.id)
        self.actionButtonTapped?()
    }

    @objc private func dismissTapped() {
        SwiftMessages.hide(id: self.id)
    }
}

extension AlertView {
    /// A convenience function to configure a default drop shadow effect.
    open func configureDropShadow() {
        let layer = self.wrapperView.layer
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        layer.shadowRadius = 6.0
        layer.shadowOpacity = 0.4
        layer.masksToBounds = false
        updateShadowPath()
    }

    private func updateShadowPath() {
        layer.shadowPath = UIBezierPath(roundedRect: layer.bounds, cornerRadius: layer.cornerRadius).cgPath
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        updateShadowPath()
    }
}
