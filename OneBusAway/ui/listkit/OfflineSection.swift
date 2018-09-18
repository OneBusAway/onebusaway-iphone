//
//  OfflineSection.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 5/28/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import IGListKit

class OfflineSection: NSObject, ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        return self
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return object is OfflineSection
    }
}

class OfflineCell: SelfSizingCollectionCell {
    private let titleLabel: UILabel = {
        let label = UILabel.oba_autolayoutNew()
        label.font = OBATheme.titleFont
        label.text = OBAStrings.offline
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()
    private let detailLabel: UILabel = {
        let label = UILabel.oba_autolayoutNew()
        label.text = NSLocalizedString("map_table.offline_explanation", comment: "Explanation for when the app is offline.")
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    private let offlineImageView: UIImageView = {
        let imageView = UIImageView.oba_autolayoutNew()
        imageView.image = UIImage(named: "offline")
        imageView.contentMode = .scaleAspectFit

        return imageView
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)

        let spacer = UIView()
        spacer.backgroundColor = .magenta

        let labelStack = UIStackView.oba_verticalStack(withArrangedSubviews: [titleLabel, detailLabel, UIView()])
        let labelStackWrapper = labelStack.oba_embedInWrapper()

        let outerStack = UIStackView.oba_horizontalStack(withArrangedSubviews: [offlineImageView, labelStackWrapper])
        outerStack.spacing = 2.0 * OBATheme.defaultPadding

        contentView.addSubview(outerStack)
        outerStack.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: OBATheme.defaultMargin, bottom: 0, right: OBATheme.defaultMargin))
        }

        offlineImageView.snp.makeConstraints { (make) in
            make.width.equalTo(48.0)
            make.height.greaterThanOrEqualTo(48.0)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class OfflineSectionController: ListSectionController {
    var data: OfflineSection?

    override init() {
        super.init()
        inset = .zero
    }

    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: collectionContext!.containerSize.width, height: 55)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard
            let ctx = collectionContext,
            let cell = ctx.dequeueReusableCell(of: OfflineCell.self, for: self, at: index) as? OfflineCell
            else {
                fatalError()
        }
        return cell
    }
}
