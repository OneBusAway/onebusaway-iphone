//
//  StopCell.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 5/23/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import OBAKit
import SnapKit

class StopCell: SelfSizingCollectionCell {
    var stopViewModel: StopViewModel? {
        didSet {
            guard let stop = stopViewModel else {
                return
            }
            nameLabel.text = stop.nameWithDirection
            routesLabel.text = stop.routeNames

            if let image = stop.image {
                imageView.image = image
                imageView.snp.updateConstraints { (make) in
                    make.width.equalTo(16.0)
                }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.image = nil
        imageView.snp.updateConstraints { (make) in
            make.width.equalTo(0.0)
        }

        nameLabel.text = nil
        routesLabel.text = nil
    }

    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.setContentHuggingPriority(.defaultHigh, for: .vertical)
        lbl.setContentCompressionResistancePriority(.required, for: .vertical)

        return lbl
    }()

    private let routesLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = OBATheme.footnoteFont
        lbl.setContentHuggingPriority(.defaultHigh, for: .vertical)
        lbl.setContentCompressionResistancePriority(.required, for: .vertical)

        return lbl
    }()

    private lazy var labelStack: UIStackView = {
        let stack = UIStackView.init(arrangedSubviews: [nameLabel, routesLabel])
        stack.axis = .vertical
        return stack
    }()

    private lazy var labelStackWrapper: UIView = {
        let plainWrapper = labelStack.oba_embedInWrapperView(withConstraints: false)
        if #available(iOS 13.0, *) {
          plainWrapper.backgroundColor = .secondarySystemGroupedBackground
        } else {
          plainWrapper.backgroundColor = .white
        }

        labelStack.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(44)
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: OBATheme.defaultPadding, bottom: OBATheme.defaultPadding, right: OBATheme.defaultPadding))
        }

        return plainWrapper
    }()

    private let chevronWrapper: UIView = {
        let chevronImage = UIImageView(image: #imageLiteral(resourceName: "chevron"))
        if #available(iOS 13.0, *) {
            chevronImage.tintColor = .systemGray2
        } else {
            chevronImage.tintColor = .darkGray
        }

        let chevronWrapper = chevronImage.oba_embedInWrapperView(withConstraints: false)
      
        if #available(iOS 13.0, *) {
            chevronWrapper.backgroundColor = .secondarySystemGroupedBackground
        } else {
            chevronWrapper.backgroundColor = .white
        }

        chevronImage.snp.makeConstraints { make in
            make.height.equalTo(14)
            make.width.equalTo(8)
            make.leading.trailing.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: OBATheme.defaultPadding))
            make.centerY.equalToSuperview()
        }
        return chevronWrapper
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit

		if #available(iOS 13.0, *) { imageView.tintColor = .label }

        return imageView
    }()

    private let separator: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor(red: 200 / 255.0, green: 199 / 255.0, blue: 204 / 255.0, alpha: 1).cgColor
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = OBATheme.mapTableBackgroundColor

        let imageViewWrapper = imageView.oba_embedInWrapperView(withConstraints: false)

		if #available(iOS 13.0, *) {
			imageViewWrapper.backgroundColor = .secondarySystemGroupedBackground
		} else {
			imageViewWrapper.backgroundColor = .white
		}

        imageView.snp.remakeConstraints { make in
            make.width.equalTo(0.0)
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: OBATheme.defaultPadding, bottom: 0, right: 0))
        }

        let outerStack = UIStackView.oba_horizontalStack(withArrangedSubviews: [imageViewWrapper, labelStackWrapper, chevronWrapper])

        let cardWrapper = outerStack.oba_embedInCardWrapper()
        contentView.addSubview(cardWrapper)
        cardWrapper.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(StopCell.leftRightInsets)
        }

        contentView.layer.addSublayer(separator)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = contentView.bounds
        let height: CGFloat = 0.5
        let sideInset = OBATheme.defaultEdgeInsets.left
        separator.frame = CGRect(x: sideInset, y: bounds.height - height, width: bounds.width - (2 * sideInset), height: height)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
