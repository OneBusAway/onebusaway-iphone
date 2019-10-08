//
//  ChevronCardCell.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 9/12/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import OBAKit
import SnapKit

class ChevronCardCell: SelfSizingCollectionCell {

    override open func prepareForReuse() {
        super.prepareForReuse()

        imageView.image = nil
        contentStack.removeArrangedSubview(imageView)
        imageView.removeFromSuperview()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = OBATheme.mapTableBackgroundColor

        let imageViewWrapper = imageView.oba_embedInWrapperView(withConstraints: false)
        imageViewWrapper.backgroundColor = .white
        imageView.snp.remakeConstraints { make in
            make.width.equalTo(16.0)
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: OBATheme.defaultPadding, bottom: 0, right: 0))
        }

        let cardWrapper = contentStack.oba_embedInCardWrapper()
        contentView.addSubview(cardWrapper)
        cardWrapper.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(SelfSizingCollectionCell.leftRightInsets)
        }

        contentView.layer.addSublayer(separator)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = contentView.bounds
        let height: CGFloat = 0.5
        let sideInset = OBATheme.defaultEdgeInsets.left
        separator.frame = CGRect(x: sideInset, y: bounds.height - height, width: bounds.width - (2 * sideInset), height: height)
    }

    // MARK: - Properties

    private lazy var contentStack: UIStackView = {
        return UIStackView.oba_horizontalStack(withArrangedSubviews: [imageView, contentWrapper, chevronWrapper])
    }()

    public let contentWrapper: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
		if #available(iOS 13, *) {
			view.backgroundColor = .systemBackground
		} else {
			view.backgroundColor = .white
		}
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
		if #available(iOS 13, *) {
			imageView.backgroundColor = .systemBackground
		} else {
			imageView.backgroundColor = .white
		}
		
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let separator: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor(red: 200 / 255.0, green: 199 / 255.0, blue: 204 / 255.0, alpha: 1).cgColor
        return layer
    }()

    private let chevronWrapper: UIView = {
        let chevronImage = UIImageView(image: #imageLiteral(resourceName: "chevron"))
        chevronImage.tintColor = .darkGray
        let chevronWrapper = chevronImage.oba_embedInWrapperView(withConstraints: false)
        chevronImage.snp.makeConstraints { make in
            make.height.equalTo(14)
            make.width.equalTo(8)
            make.leading.trailing.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: OBATheme.defaultPadding))
            make.centerY.equalToSuperview()
        }
		
		if #available(iOS 13, *) {
			chevronWrapper.backgroundColor = .systemBackground
		} else {
			chevronWrapper.backgroundColor = .white
		}
		
        return chevronWrapper
    }()
}
