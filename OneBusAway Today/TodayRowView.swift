//
//  TodayRowView.swift
//  OneBusAway Today
//
//  Created by Aaron Brethorst on 3/1/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import OBAKit

enum TodayRowViewState {
    case loading
    case error
    case complete
}

class TodayRowView: UIView {
    // MARK: - State

    var loadingState: TodayRowViewState = .loading

    var departures: [OBAArrivalAndDepartureV2]? {
        didSet {
            updateDepartures()
        }
    }

    public var bookmark: OBABookmarkV2? {
        didSet {
            titleLabel.text = bookmark?.title
        }
    }

    // MARK: - UI

    private lazy var hairline: UIView = {
        let view = UIView.oba_autolayoutNew()
        view.backgroundColor = UIColor.init(white: 1.0, alpha: 0.25)
        view.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
        }
        return view
    }()

    private lazy var outerStack: UIStackView = {
        let stack = UIStackView.init(arrangedSubviews: [hairline, outerLabelStack])
        stack.axis = .vertical

        return stack
    }()

    private lazy var outerLabelStack: UIStackView = {
        let leftStackWrapper = titleLabelStack.oba_embedInWrapper()
        let departuresStackWrapper = departuresStack.oba_embedInWrapper()
        let stack = UIStackView.init(arrangedSubviews: [leftStackWrapper, departuresStackWrapper])
        stack.axis = .horizontal
        stack.spacing = OBATheme.compactPadding

        return stack
    }()

    // MARK: - Title Info Labels
    private lazy var titleLabelStack: UIStackView = {
        let stack = UIStackView.init(arrangedSubviews: [titleLabel, nextDepartureLabel])
        stack.axis = .vertical
        stack.spacing = OBATheme.minimalPadding

        return stack
    }()

    private lazy var titleLabel: UILabel = {
        let label = TodayRowView.buildInfoLabel(font: OBATheme.boldFootnoteFont)
        return label
    }()

    private lazy var nextDepartureLabel: UILabel = {
        let label = TodayRowView.buildInfoLabel(font: OBATheme.footnoteFont)
        label.text = NSLocalizedString("today_screen.tap_for_more_information", comment: "Tap for more information subheading on Today view")

        return label
    }()

    // MARK: - Departure Labels

    private let leadingDepartureLabel = TodayRowView.buildDepartureLabel()
    private let middleDepartureLabel = TodayRowView.buildDepartureLabel()
    private let trailingDepartureLabel = TodayRowView.buildDepartureLabel()

    private lazy var departuresStack: UIStackView = {
        let stack = UIStackView.init(arrangedSubviews: [leadingDepartureLabel, middleDepartureLabel, trailingDepartureLabel])
        stack.axis = .horizontal
        stack.spacing = OBATheme.compactPadding
        stack.isUserInteractionEnabled = false

        return stack
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(outerStack)
        outerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Private Helpers
extension TodayRowView {
    private static func buildInfoLabel(font: UIFont) -> UILabel {
        let label = UILabel.oba_autolayoutNew()
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.font = font
        label.minimumScaleFactor = 0.8
        return label
    }

    private static func buildDepartureLabel() -> UILabel {
        let label = UILabel.oba_autolayoutNew()
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.font = OBATheme.boldFootnoteFont
        return label
    }
}

// MARK: - Departures
extension TodayRowView {
    fileprivate func updateDepartures() {
        let formatString = NSLocalizedString("today_screen.no_departures_in_next_n_minutes_format", comment: "No departures in the next {MINUTES} minutes")
        let nextDepartureText = String.init(format: formatString, String(kMinutes))
        nextDepartureLabel.text = nextDepartureText
        leadingDepartureLabel.text = nil
        middleDepartureLabel.text = nil
        trailingDepartureLabel.text = nil

        guard let departures = departures else {
            return
        }

        if departures.isEmpty {
            return
        }

        nextDepartureLabel.text = OBADepartureCellHelpers.statusText(forArrivalAndDeparture: departures[0])

        applyUpcomingDeparture(at: 0, to: leadingDepartureLabel)
        applyUpcomingDeparture(at: 1, to: middleDepartureLabel)
        applyUpcomingDeparture(at: 2, to: trailingDepartureLabel)
    }

    private func applyUpcomingDeparture(at index: Int, to label: UILabel) {
        guard let departures = departures else {
            return
        }

        if departures.count <= index {
            return
        }

        let dep = departures[index]
        label.accessibilityLabel = OBADateHelpers.formatAccessibilityLabelMinutes(until: dep.bestArrivalDepartureDate)
        label.text = OBADateHelpers.formatMinutes(until: dep.bestArrivalDepartureDate)
        label.textColor = OBADepartureCellHelpers.color(for: dep.departureStatus)
    }
}
