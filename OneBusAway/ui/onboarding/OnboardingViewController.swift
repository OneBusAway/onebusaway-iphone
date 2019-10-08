//
//  OnboardingViewController.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 4/3/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import UIKit
import SnapKit

@objc protocol OnboardingDelegate {
    func onboardingControllerRequestedAuthorization(_ onboardingController: OnboardingViewController)
}

@objc class OnboardingViewController: UIViewController {
    let stackView = UIStackView.init()
    @objc weak var delegate: OnboardingDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("onboarding_controller.title", comment: "Title of the Onboarding Controller. 'Welcome to OneBusAway!'")

        self.stackView.axis = .vertical
        self.stackView.spacing = OBATheme.defaultPadding

        let imageView = UIImageView.init(image: #imageLiteral(resourceName: "infoheader"))
        imageView.contentMode = .scaleAspectFit
        let topView = UIView.init()
        self.stackView.addArrangedSubview(topView)
        topView.backgroundColor = OBATheme.obaGreen
        topView.clipsToBounds = true
        topView.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-OBATheme.defaultPadding)
        }

        topView.snp.makeConstraints { make in
            make.height.equalTo(160)
        }

        let titleLabel = UILabel.init()
        titleLabel.textAlignment = .center
        titleLabel.text = self.title
        titleLabel.font = OBATheme.subtitleFont
        self.stackView.addArrangedSubview(titleLabel)

        let bodyTextView = UITextView.init()
        self.stackView.addArrangedSubview(bodyTextView)
        bodyTextView.text = NSLocalizedString("onboarding_controller.body_text", comment: "Body text of the Onboarding Controller.")
        bodyTextView.isSelectable = false
        bodyTextView.isEditable = false
        bodyTextView.textAlignment = .left
        bodyTextView.font = OBATheme.bodyFont
        bodyTextView.snp.makeConstraints { make in
            make.left.equalTo(OBATheme.defaultMargin)
            make.right.equalTo(-OBATheme.defaultMargin)
        }

        let button = UIButton.init()
        button.setTitleColor(OBATheme.obaGreen, for: .normal)
        button.addTarget(self, action: #selector(showLocationPrompt), for: .touchUpInside)
        self.stackView.addArrangedSubview(button)
        button.setTitle(NSLocalizedString("onboarding_controller.request_location_permissions_button", comment: "Bottom button on the Onboarding Controller"), for: .normal)
        button.titleLabel?.font = OBATheme.titleFont
        button.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
            make.width.equalToSuperview()
        }

        self.view.addSubview(self.stackView)
        self.stackView.snp.makeConstraints { make in
            make.top.right.left.equalToSuperview()
            make.bottom.equalToSuperview().offset(-60)
        }
    }

    @objc func showLocationPrompt() {
        self.delegate?.onboardingControllerRequestedAuthorization(self)
    }
}
