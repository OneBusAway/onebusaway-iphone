//
//  DrawerApplicationUI.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 2/17/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import OBAKit

@objc class DrawerApplicationUI: NSObject {
    var application: OBAApplication
    let tabBarController = UITabBarController.init()

    // MARK: - Map Tab
    var mapTableController: MapTableViewController
    var mapPulley: PulleyViewController
    let mapPulleyNav: UINavigationController
    var mapController: OBAMapViewController
    let drawerNavigation: UINavigationController

    // MARK: - Recents Tab
    let recentsController = OBARecentStopsViewController.init()
    lazy var recentsNavigation: UINavigationController = {
        return UINavigationController.init(rootViewController: recentsController)
    }()

    // MARK: - Bookmarks Tab
    let bookmarksController = OBABookmarksViewController.init()
    lazy var bookmarksNavigation: UINavigationController = {
        return UINavigationController.init(rootViewController: bookmarksController)
    }()

    // MARK: - Info Tab
    let infoController = OBAInfoViewController.init()
    lazy var infoNavigation: UINavigationController = {
        return UINavigationController.init(rootViewController: infoController)
    }()

    // MARK: - Init
    required init(application: OBAApplication) {
        self.application = application

        let useStopDrawer = application.userDefaults.bool(forKey: OBAUseStopDrawerDefaultsKey)

        mapTableController = MapTableViewController.init(application: application)
        drawerNavigation = UINavigationController(rootViewController: mapTableController)
        drawerNavigation.setNavigationBarHidden(true, animated: false)

        mapController = OBAMapViewController(application: application)
        mapController.standaloneMode = !useStopDrawer
        mapController.delegate = mapTableController

        mapPulley = PulleyViewController(contentViewController: mapController, drawerViewController: drawerNavigation)
        mapPulley.defaultCollapsedHeight = DrawerApplicationUI.calculateCollapsedHeightForCurrentDevice()
        mapPulley.initialDrawerPosition = .collapsed

        mapPulley.title = mapTableController.title
        mapPulley.tabBarItem.image = mapTableController.tabBarItem.image
        mapPulley.tabBarItem.selectedImage = mapTableController.tabBarItem.selectedImage

        mapPulleyNav = UINavigationController(rootViewController: mapPulley)

        super.init()

        mapPulley.delegate = self

        tabBarController.viewControllers = [mapPulleyNav, recentsNavigation, bookmarksNavigation, infoNavigation]
        tabBarController.delegate = self
    }
}

// MARK: - Pulley Delegate
extension DrawerApplicationUI: PulleyDelegate {
    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        mapTableController.collectionView.isScrollEnabled = drawer.drawerPosition == .open
    }

    private static func calculateCollapsedHeightForCurrentDevice() -> CGFloat {
        let height = UIScreen.main.bounds.height

        var totalDrawerHeight: CGFloat

        if #available(iOS 11.0, *) {
            totalDrawerHeight = 0.0
        }
        else {
            // PulleyLib seems to have a few layout bugs on iOS 10.
            // Given the very small number of users on this platform, I am not
            // super-excited about the prospect of debugging this issue and am
            // choosing instead to just work around it.
            totalDrawerHeight = 40.0
        }

        if height >= 812.0 { // X, Xs, iPad, etc.
            totalDrawerHeight += 200.0
        }
        else if height >= 736.0 { // Plus
            totalDrawerHeight += 150.0
        }
        else if height >= 667.0 { // 6, 7, 8
            totalDrawerHeight += 150.0
        }
        else { // iPhone SE, etc.
            totalDrawerHeight += 120.0
        }

        return totalDrawerHeight
    }
}

// MARK: - OBAApplicationUI
extension DrawerApplicationUI: OBAApplicationUI {
    private static let kOBASelectedTabIndexDefaultsKey = "OBASelectedTabIndexDefaultsKey"

    public var rootViewController: UIViewController {
        return tabBarController
    }

    func performAction(for shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        var navigationTargetType: OBANavigationTargetType = .undefined
        var parameters: [AnyHashable: Any]?

        if shortcutItem.type == kApplicationShortcutRecents {
            navigationTargetType = .recentStops
            if let stopIDs = shortcutItem.userInfo?["stopIds"] as? NSArray,
               let firstObject = stopIDs.firstObject {
                parameters = [OBAStopIDNavigationTargetParameter: firstObject]
            }
            else if let stopID = shortcutItem.userInfo?["stopID"] as? String {
                parameters = [OBAStopIDNavigationTargetParameter: stopID]
            }
        }

        let target = OBANavigationTarget.init(navigationTargetType, parameters: parameters)
        self.navigate(toTargetInternal: target)
        completionHandler(true)
    }

    func applicationDidBecomeActive() {
        var selectedIndex = application.userDefaults.object(forKey: DrawerApplicationUI.kOBASelectedTabIndexDefaultsKey) as? Int ?? 0

        // Users sometimes email us confused about what happened to their map. There really isn't any value
        // in having the user returned to the info tab when they reopen the app, so let's just stop persisting
        // it as a possible option. Instead, if the user has navigated to the info tab, we'll just default them
        // back to the map.
        // See: https://github.com/OneBusAway/onebusaway-iphone/issues/1410
        if selectedIndex == 3 {
            selectedIndex = 0
        }

        tabBarController.selectedIndex = selectedIndex

        let startingTab = [0: "OBAMapViewController",
                           1: "OBARecentStopsViewController",
                           2: "OBABookmarksViewController"][selectedIndex] ?? "Unknown"

        OBAAnalytics.shared().reportEvent(withCategory: OBAAnalyticsCategoryAppSettings, action: "startup", label: "Startup View: \(startingTab)", value: nil)
        Analytics.logEvent(OBAAnalyticsStartupScreen, parameters: ["startingTab": startingTab])
    }

    func navigate(toTargetInternal navigationTarget: OBANavigationTarget) {
        let viewController: (UIViewController & OBANavigationTargetAware)
        let topController: UIViewController

        switch navigationTarget.target {
        case .map, .searchResults:
            viewController = mapTableController
            topController = mapPulleyNav
        case .recentStops:
            viewController = recentsController
            topController = recentsNavigation
        case .bookmarks:
            viewController = bookmarksController
            topController = bookmarksNavigation
        case .contactUs:
            viewController = infoController
            topController = infoNavigation
        case .undefined:
            // swiftlint:disable no_fallthrough_only fallthrough
            fallthrough
            // swiftlint:enable no_fallthrough_only fallthrough
        default:
            DDLogError("Unhandled target in #file #line: \(navigationTarget.target)")
            return
        }

        tabBarController.selectedViewController = topController
        viewController.setNavigationTarget(navigationTarget)

        if navigationTarget.parameters["stop"] != nil, let stopID = navigationTarget.parameters["stopID"] as? String {
            let vc = StopViewController.init(stopID: stopID)
            let nav = mapPulley.navigationController ?? drawerNavigation
            nav.pushViewController(vc, animated: true)
        }

        // update kOBASelectedTabIndexDefaultsKey, otherwise -applicationDidBecomeActive: will switch us away.
         if let selected = tabBarController.selectedViewController {
            tabBarController(tabBarController, didSelect: selected)
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension DrawerApplicationUI: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        application.userDefaults.set(tabBarController.selectedIndex, forKey: DrawerApplicationUI.kOBASelectedTabIndexDefaultsKey)
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard
            let selectedController = tabBarController.selectedViewController,
            let controllers = tabBarController.viewControllers else {
                return true
        }

        let oldIndex = controllers.firstIndex(of: selectedController)
        let newIndex = controllers.firstIndex(of: viewController)

        if newIndex == 0 && oldIndex == 0 {
            mapController.recenterMap()
        }

        return true
    }
}
