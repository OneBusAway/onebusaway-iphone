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

class RegionalAlertSectionController: ListSectionController {

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
}

class RegionalAlertCell: SelfSizingCollectionCell {
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

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
