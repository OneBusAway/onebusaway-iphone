//
//  TodayRefreshView.swift
//  OneBusAway Today
//
//  Created by Aaron Brethorst on 3/3/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import SnapKit
import OBAKit

class TodayRefreshView: UIControl {

    // MARK: - UI Components

    private lazy var lastUpdatedLabel: UILabel = {
        let label = UILabel.init()
        label.font = OBATheme.footnoteFont
        return label
    }()

    private lazy var refreshImageView: UIImageView = {
        let imageView = UIImageView.init(image: #imageLiteral(resourceName: "refresh"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var activityView: UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView.init(activityIndicatorStyle: .gray)
        activity.hidesWhenStopped = true
        return activity
    }()

    private lazy var refreshLabel: UILabel = {
        let label = UILabel.init()
        label.text = OBAStrings.refresh
        label.font = OBATheme.footnoteFont
        return label
    }()

    private lazy var stackView: UIStackView = {
        let spacer = UIView.init()
        let stack = UIStackView.init(arrangedSubviews: [lastUpdatedLabel, spacer, refreshImageView, activityView, refreshLabel])
        stack.spacing = OBATheme.minimalPadding
        stack.isUserInteractionEnabled = false
        stack.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(20)
        }

        return stack
    }()

    // MARK: - Last Updated At

    public var lastUpdatedAt: Date? {
        didSet {
            var formattedDate = OBAStrings.never

            defer {
                let formatString = NSLocalizedString("refresh_cell.last_updated_format", comment: "Last updated: {DATE}")
                lastUpdatedLabel.text = String.init(format: formatString, formattedDate)
            }

            guard let lastUpdatedAt = lastUpdatedAt else {
                return
            }

            if (lastUpdatedAt as NSDate).isToday {
                formattedDate = todayFormatter.string(from: lastUpdatedAt)
            }
            else {
                formattedDate = anyDayFormatter.string(from: lastUpdatedAt)
            }
        }
    }

    private lazy var todayFormatter: DateFormatter = {
        let formatter = DateFormatter.init()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private lazy var anyDayFormatter: DateFormatter = {
        let formatter = DateFormatter.init()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.lastUpdatedAt = nil

        self.addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Refresh
extension TodayRefreshView {
    public func beginRefreshing() {
        refreshImageView.isHidden = true
        activityView.startAnimating()
        refreshLabel.text = OBAStrings.updating
    }

    public func stopRefreshing() {
        activityView.stopAnimating()
        refreshImageView.isHidden = false
        refreshLabel.text = OBAStrings.refresh
    }
}
