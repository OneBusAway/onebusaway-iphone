//
//  RegionalAlertSection.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 6/4/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import Foundation
import IGListKit
import OBAKit
import SafariServices
import SwipeCellKit

class RegionalAlert: NSObject, ListDiffable {
    let alertIdentifier: String
    let title: String?
    let summary: String?
    let url: URL?

    init(alertIdentifier: String, title: String?, summary: String?, url: URL?) {
        self.alertIdentifier = alertIdentifier
        self.title = title
        self.summary = summary
        self.url = url
    }

    // MARK: - ListDiffable

    func diffIdentifier() -> NSObjectProtocol {
        return alertIdentifier as NSObjectProtocol
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let alert = object as? RegionalAlert else {
            return false
        }

        return alertIdentifier == alert.alertIdentifier
            && title == alert.title
            && summary == alert.summary
            && url == alert.url
    }
}

class RegionalAlertSectionController: ListSectionController, SwipeCollectionViewCellDelegate {

    // MARK: - Data
    var data: RegionalAlert?

    override func didUpdate(to object: Any) {
        precondition(object is RegionalAlert)
        data = object as? RegionalAlert
    }

    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: collectionContext!.containerSize.width, height: 55)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard
            let ctx = collectionContext,
            let data = data,
            let cell = ctx.dequeueReusableCell(of: RegionalAlertCell.self, for: self, at: index) as? RegionalAlertCell
        else {
            fatalError()
        }

        cell.delegate = self
        cell.alertTitleLabel.text = data.title
        cell.summaryLabel.text = data.summary

        return cell
    }

    override func didSelectItem(at index: Int) {
        guard
            let url = data?.url,
            let viewController = viewController
            else {
                return
        }

        let safariController = SFSafariViewController.init(url: url)
        viewController.navigationController?.present(safariController, animated: true, completion: nil)
    }

    // MARK: - Swipe Cell Delegate

    func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }

        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { _, _ in
            // handle action by updating model with deletion
        }

        // customize the action appearance
        deleteAction.image = UIImage(named: "close")

        return [deleteAction]
    }

    func collectionView(_ collectionView: UICollectionView, editActionsOptionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        let options = SwipeOptions()
//        options.expansionStyle = orientation == .left ? .selection : .destructive
//        options.transitionStyle = defaultOptions.transitionStyle
//
//        switch buttonStyle {
//        case .backgroundColor:
//            options.buttonSpacing = 11
//        case .circular:
//            options.buttonSpacing = 4
//            options.backgroundColor = #colorLiteral(red: 0.9467939734, green: 0.9468161464, blue: 0.9468042254, alpha: 1)
//        }

        return options
    }
}

class RegionalAlertCell: SwipeCollectionViewCell {
    let alertTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.font = OBATheme.boldSubheadFont
        return label
    }()

    let summaryLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 3
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.font = OBATheme.footnoteFont
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = OBATheme.mapTableBackgroundColor

        clipsToBounds = true

        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.clipsToBounds = true

        let labelStack = UIStackView(arrangedSubviews: [alertTitleLabel, summaryLabel])
        labelStack.axis = .vertical
        let labelStackWrapper = labelStack.oba_embedInWrapperView(withConstraints: false)
        labelStackWrapper.backgroundColor = .white
        labelStack.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(RegionalAlertCell.leftRightInsets)
        }

        let cardWrapper = labelStackWrapper.oba_embedInCardWrapper()
        contentView.addSubview(cardWrapper)
        cardWrapper.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: OBATheme.defaultPadding, left: OBATheme.defaultPadding, bottom: OBATheme.defaultPadding, right: OBATheme.defaultPadding))
        }

        contentView.addSubview(cardWrapper)
    }

    // MARK: - Copied and pasted from SelfSizingCollectionCell

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
        var newFrame = layoutAttributes.frame
        // note: don't change the width
        newFrame.size.height = ceil(size.height)
        layoutAttributes.frame = newFrame
        return layoutAttributes
    }

    public required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public static let insets = UIEdgeInsets.zero

    public static let leftRightInsets = UIEdgeInsets(top: 0, left: OBATheme.defaultPadding, bottom: 0, right: OBATheme.defaultPadding)
}
