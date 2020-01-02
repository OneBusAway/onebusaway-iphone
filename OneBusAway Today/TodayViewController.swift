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
      
        layoutBookmarkVisibility()
    }

    private func viewForBookmark(_ bookmark: OBABookmarkV2, index: Int) -> TodayRowView {
        let v = TodayRowView.oba_autolayoutNew()
        v.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(TodayViewController.bookmarkTapped(sender:))))
        v.bookmark = bookmark
        v.setContentHuggingPriority(.defaultHigh, for: .vertical)
        v.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

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
        layoutBookmarkVisibility()
    }
    
    /// Resposible for calculating how many bookmarks can fit into the widget's size.
    func layoutBookmarkVisibility() {
        guard let extensionContext = self.extensionContext else { return }
        let displayMode = extensionContext.widgetActiveDisplayMode
        let maximumSize = extensionContext.widgetMaximumSize(for: displayMode)
        
        // Calculate the number of bookmarks to display given the display mode.
        // This varies depending on the number of lines the bookmark name is using.
        
        let padding = OBATheme.defaultPadding
        let frontMatterSize = self.frontMatterWrapper.systemLayoutSizeFitting(maximumSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultHigh)
        let heightAvailableForBookmarks = maximumSize.height - frontMatterSize.height - padding
        
        var numberOfBookmarksToDisplay: Int = 0
        if displayMode == .compact {
            // Calculate the number of rows we can fit into the height available for bookmarks.
            var usedHeight: CGFloat = 0.0
            for view in bookmarkStackView.arrangedSubviews {
                let layoutSize = view.systemLayoutSizeFitting(maximumSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultHigh)
                
                guard layoutSize.height + usedHeight < heightAvailableForBookmarks else { break }
                numberOfBookmarksToDisplay += 1
                usedHeight += layoutSize.height
            }
        } else {
            // We don't need to calculate how many bookmarks to fit.
            numberOfBookmarksToDisplay = bookmarkStackView.arrangedSubviews.count
        }
        
        // Apply visibility of which bookmarks to display.
        for (index, row) in bookmarkStackView.arrangedSubviews.enumerated() {
            row.isHidden = index >= numberOfBookmarksToDisplay
        }
        
        let bookmarksSize = self.bookmarkWrapper.systemLayoutSizeFitting(maximumSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultHigh)
        
        self.preferredContentSize = CGSize(width: frontMatterSize.width, height: frontMatterSize.height + bookmarksSize.height + padding)
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
            return Promise(value: false)
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
