//
//  TodayViewController.swift
//  OneBusAway Today
//
//  Created by Aaron Brethorst on 10/5/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import UIKit
import NotificationCenter
import OBAKit
import Fabric
import Crashlytics
import SnapKit

let kMinutes: UInt = 60

class TodayViewController: UIViewController {
    let app = OBAApplication.init()
    let deepLinkRouter = DeepLinkRouter(baseURL: URL(string: OBAInAppDeepLinkSchemeAddress)!)
    var group: OBABookmarkGroup = OBABookmarkGroup.init(bookmarkGroupType: .todayWidget)

    var bookmarkViewsMap: [OBABookmarkV2: TodayRowView] = [:]

    private let outerStackView: UIStackView = TodayViewController.buildStackView()

    private lazy var frontMatterStack: UIStackView = {
        let stack = TodayViewController.buildStackView()
        stack.addArrangedSubview(refreshControl)
        stack.addArrangedSubview(errorTitleLabel)
        stack.addArrangedSubview(errorDescriptionLabel)
        return stack
    }()

    private lazy var frontMatterWrapper: UIView = {
        return frontMatterStack.oba_embedInWrapper()
    }()

    private let bookmarkStackView: UIStackView = TodayViewController.buildStackView()
    private lazy var bookmarkWrapper: UIView = {
        return bookmarkStackView.oba_embedInWrapper()
    }()

    private lazy var errorTitleLabel: UILabel = {
        let label = UILabel.oba_autolayoutNew()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = OBATheme.boldBodyFont
        label.text = OBAStrings.error
        label.isHidden = true
        return label
    }()

    private lazy var errorDescriptionLabel: UILabel = {
        let label = UILabel.oba_autolayoutNew()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = OBATheme.bodyFont
        label.text = OBAStrings.inexplicableErrorPleaseContactUs
        label.isHidden = true
        return label
    }()

    private lazy var refreshControl: TodayRefreshView = {
        let refresh = TodayRefreshView.oba_autolayoutNew()
        refresh.lastUpdatedAt = lastUpdatedAt
        refresh.addTarget(self, action: #selector(beginRefreshing), for: .touchUpInside)
        return refresh
    }()

    private lazy var spacerView: UIView = {
        let spacer = UIView.oba_autolayoutNew()
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return spacer
    }()

    // MARK: - Init/View Controller Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Fabric.with([Crashlytics.self])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        extensionContext?.widgetLargestAvailableDisplayMode = .expanded

        outerStackView.addArrangedSubview(frontMatterWrapper)
        outerStackView.addArrangedSubview(bookmarkWrapper)
        outerStackView.addArrangedSubview(spacerView)

        self.view.addSubview(outerStackView)
        outerStackView.snp.makeConstraints { (make) in
            let inset = UIEdgeInsets(top: OBATheme.compactPadding, left: 10, bottom: OBATheme.compactPadding, right: 10)
            make.leading.top.trailing.equalToSuperview().inset(inset)
        }

        let configuration = OBAApplicationConfiguration.init()
        configuration.extensionMode = true
        app.start(with: configuration)

        rebuildUI()
    }
}

// MARK: - UI Construction
extension TodayViewController {
    private func rebuildUI() {
        group = app.modelDao.todayBookmarkGroup

        for v in bookmarkStackView.arrangedSubviews {
            bookmarkStackView.removeArrangedSubview(v)
            v.removeFromSuperview()
        }

        bookmarkViewsMap.removeAll()

        displayErrorMessagesIfAppropriate()

        for (idx, bm) in group.bookmarks.enumerated() {
            let view = viewForBookmark(bm, index: idx)
            bookmarkStackView.addArrangedSubview(view)
            bookmarkViewsMap[bm] = view
        }
    }

    private func viewForBookmark(_ bookmark: OBABookmarkV2, index: Int) -> TodayRowView {
        let v = TodayRowView.oba_autolayoutNew()
        v.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(TodayViewController.bookmarkTapped(sender:))))
        v.bookmark = bookmark
        v.setContentHuggingPriority(.defaultHigh, for: .vertical)
        v.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        let inCompactMode = extensionContext?.widgetActiveDisplayMode == .compact
        v.isHidden = inCompactMode && index > 1

        return v
    }

    private func displayErrorMessagesIfAppropriate() {
        if group.bookmarks.isEmpty {
            showErrorMessage(title: NSLocalizedString("today_screen.no_data_title", comment: "No Bookmarks - empty data set title."), description: NSLocalizedString("today_screen.no_data_description", comment: "Add bookmarks to Today View Bookmarks to see them here. - empty data set description."))
        }
        else if app.modelDao.currentRegion == nil {
            showErrorMessage(title: OBAStrings.error, description: NSLocalizedString("today_screen.no_region_description", comment: "We don't know where you're located. Please choose a region in OneBusAway."))
        }
        else {
            errorTitleLabel.isHidden = true
            errorDescriptionLabel.isHidden = true
        }
    }

    private func showErrorMessage(title: String, description: String) {
        errorTitleLabel.isHidden = false
        errorDescriptionLabel.isHidden = false

        errorTitleLabel.text = title
        errorDescriptionLabel.text = description
    }

    @objc func bookmarkTapped(sender: UITapGestureRecognizer?) {
        guard let sender = sender,
              let rowView = sender.view as? TodayRowView,
              let bookmark = rowView.bookmark else {
            return
        }

        let url = deepLinkRouter.deepLinkURL(stopID: bookmark.stopId, regionID: bookmark.regionIdentifier) ?? URL.init(string: OBAInAppDeepLinkSchemeAddress)!
        extensionContext?.open(url, completionHandler: nil)
    }

    private static func buildStackView() -> UIStackView {
        let stack = UIStackView.init()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = OBATheme.compactPadding

        return stack
    }
}

// MARK: - Widget Protocol
extension TodayViewController: NCWidgetProviding {
    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        rebuildUI()
        reloadData(completionHandler)
    }

    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        let isCompact = activeDisplayMode == .compact
        for (idx, v) in bookmarkStackView.arrangedSubviews.enumerated() {
            v.isHidden = isCompact && idx > 1
        }

        let frontMatterSize = self.frontMatterWrapper.systemLayoutSizeFitting(maxSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultHigh)

        let bookmarkSize = self.bookmarkWrapper.systemLayoutSizeFitting(maxSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultHigh)

        let extra = OBATheme.defaultPadding

        self.preferredContentSize = CGSize.init(width: frontMatterSize.width, height: frontMatterSize.height + bookmarkSize.height + extra)
    }
}

// MARK: - Refresh Control UI
extension TodayViewController {
    @objc private func beginRefreshing() {
        reloadData(nil)
    }

    private func reloadData(_ completionHandler: ((NCUpdateResult) -> Void)?) {
        if group.bookmarks.isEmpty {
            completionHandler?(NCUpdateResult.noData)
            return
        }

        refreshControl.beginRefreshing()

        let promises: [Promise<Any>] = group.bookmarks.compactMap { self.promiseStop(bookmark: $0) }
        _ = when(resolved: promises).then { _ -> Void in
            self.lastUpdatedAt = Date.init()
            self.refreshControl.stopRefreshing()
            completionHandler?(NCUpdateResult.newData)
        }
    }
}

// MARK: - Last Updated Section
extension TodayViewController {
    private static let lastUpdatedAtUserDefaultsKey = "lastUpdatedAtUserDefaultsKey"
    var lastUpdatedAt: Date? {
        get {
            guard let defaultsDate = self.app.userDefaults.value(forKey: TodayViewController.lastUpdatedAtUserDefaultsKey) else {
                return nil
            }

            return defaultsDate as? Date
        }
        set(val) {
            self.app.userDefaults.setValue(val, forKey: TodayViewController.lastUpdatedAtUserDefaultsKey)
            refreshControl.lastUpdatedAt = val
        }
    }
}

// MARK: - Data Loading
extension TodayViewController {
    func promiseStop(bookmark: OBABookmarkV2) -> Promise<Any>? {
        if bookmark.bookmarkVersion == .version252 {
            // whole stop bookmark, and nothing to retrieve from server.
            return Promise.init(value: true)
        }

        return loadBookmarkedRoute(bookmark)
    }

    func loadBookmarkedRoute(_ bookmark: OBABookmarkV2) -> Promise<Any>? {
        guard
            let view = self.bookmarkViewsMap[bookmark],
            let modelService = app.modelService
        else {
            // abxoxo todo: is this the best way to bail immediately?
            // maybe throw an error?
            return Promise.init(value: false)
        }

        let promiseWrapper = modelService.requestStopArrivalsAndDepartures(withID: bookmark.stopId, minutesBefore: 0, minutesAfter: kMinutes)
        return promiseWrapper.promise.then { networkResponse -> Void in
            // swiftlint:disable force_cast
            let departures: [OBAArrivalAndDepartureV2] = bookmark.matchingArrivalsAndDepartures(forStop: networkResponse.object as! OBAArrivalsAndDeparturesForStopV2)
            view.departures = departures
            view.loadingState = .complete
            // swiftlint:enable force_cast
        }.catch { error in
            DDLogError("Error loading data: \(error)")
        }.always {
            view.loadingState = .complete
        }
    }
}
