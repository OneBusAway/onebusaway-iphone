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

typealias RegionalAlertCallback = (_ alert: RegionalAlert) -> Void

class RegionalAlert: NSObject, ListDiffable {
    let alertIdentifier: String
    let title: String?
    let summary: String?
    let url: URL?
    let date: Date?
    let markAlertAsRead: RegionalAlertCallback

    init(alertIdentifier: String, title: String?, summary: String?, url: URL?, date: Date?, markAlertAsRead: @escaping RegionalAlertCallback) {
        self.alertIdentifier = alertIdentifier
        self.title = title
        self.summary = summary
        self.url = url
        self.date = date
        self.markAlertAsRead = markAlertAsRead
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
            && date == alert.date
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
        cell.timeLabel.text = OBADateHelpers.formatDate(forMessageStyle: data.date)

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

        let deleteAction = SwipeAction(style: .default, title: OBAStrings.dismiss) { _, _ in
            if let data = self.data {
                data.markAlertAsRead(data)
            }
        }
        deleteAction.textColor = .black

        // customize the action appearance
        deleteAction.image = UIImage(named: "Delete")

        return [deleteAction]
    }

    func collectionView(_ collectionView: UICollectionView, editActionsOptionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.transitionStyle = .reveal

        return options
    }
}

class RegionalAlertCell: SwipeCollectionViewCell {
    fileprivate let alertTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.font = OBATheme.boldSubheadFont
        return label
    }()

    fileprivate let summaryLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 3
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.font = OBATheme.footnoteFont
        return label
    }()

    fileprivate let timeLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.font = OBATheme.footnoteFont
        label.textColor = UIColor.darkGray
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = OBATheme.mapTableBackgroundColor

        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let titleStack = UIStackView.oba_horizontalStack(withArrangedSubviews: [alertTitleLabel, timeLabel])
        let titleStackWrapper = titleStack.oba_embedInWrapper()

        let labelStack = UIStackView(arrangedSubviews: [titleStackWrapper, summaryLabel])
        labelStack.axis = .vertical

        let labelStackWrapper = labelStack.oba_embedInWrapperView(withConstraints: false)
		if #available(iOS 13, *) {
			labelStackWrapper.backgroundColor = .systemBackground
		} else {
			labelStackWrapper.backgroundColor = .white
		}

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
