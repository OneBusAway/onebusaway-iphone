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
        mapPulley.defaultCollapsedHeight = 120.0
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
}

// MARK: - OBAApplicationUI
extension DrawerApplicationUI: OBAApplicationUI {
    private static let kOBASelectedTabIndexDefaultsKey = "OBASelectedTabIndexDefaultsKey"

    public var rootViewController: UIViewController {
        return tabBarController
    }

    func performAction(for shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        var navigationTargetType: OBANavigationTargetType = .undefined
        var parameters: [AnyHashable: Any]? = nil

        if shortcutItem.type == kApplicationShortcutMap {
            navigationTargetType = .map
        }
        else if shortcutItem.type == kApplicationShortcutBookmarks {
            navigationTargetType = .bookmarks
        }
        else if shortcutItem.type == kApplicationShortcutRecents {
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
        let selectedIndex = application.userDefaults.object(forKey: DrawerApplicationUI.kOBASelectedTabIndexDefaultsKey) as? Int ?? 0

        tabBarController.selectedIndex = selectedIndex

        let startingTab = [0: "OBAMapViewController",
                           1: "OBARecentStopsViewController",
                           2: "OBABookmarksViewController",
                           3: "OBAInfoViewController"][selectedIndex] ?? "Unknown"

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

        let oldIndex = controllers.index(of: selectedController)
        let newIndex = controllers.index(of: viewController)

        if newIndex == 0 && oldIndex == 0 {
            mapController.recenterMap()
        }

        return true
    }
}
