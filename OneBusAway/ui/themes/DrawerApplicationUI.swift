//
//  DrawerApplicationUI.swift
//  OneBusAway
//
//  Created by Aaron Brethorst on 2/17/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import UIKit
import OBAKit

@objc class DrawerApplicationUI: NSObject {
    var application: OBAApplication
    let tabBarController = UITabBarController.init()

    // MARK: - Map Tab
    var mapController: MapTableViewController
    var mapNavigationController: UINavigationController
    var mapPulley: PulleyViewController

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

        mapController = MapTableViewController.init(application: application)
        mapNavigationController = UINavigationController.init(rootViewController: mapController)
        mapPulley = PulleyViewController(contentViewController: mapNavigationController, drawerViewController: UIViewController())
        mapPulley.setDrawerPosition(position: .closed, animated: false)
        mapPulley.defaultCollapsedHeight = 120.0

        mapPulley.title = mapController.title
        mapPulley.tabBarItem.image = mapController.tabBarItem.image
        mapPulley.tabBarItem.selectedImage = mapController.tabBarItem.selectedImage

        super.init()

        tabBarController.viewControllers = [mapPulley, recentsNavigation, bookmarksNavigation, infoNavigation]
        tabBarController.delegate = self
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

        OBAAnalytics.reportEvent(withCategory: OBAAnalyticsCategoryAppSettings, action: "startup", label: "Startup View: \(startingTab)", value: nil)
    }

    func navigate(toTargetInternal navigationTarget: OBANavigationTarget) {
        mapNavigationController.popViewController(animated: false)

        let viewController: (UIViewController & OBANavigationTargetAware)
        let navController: UINavigationController

        switch navigationTarget.target {
        case .map, .searchResults:
            viewController = mapController
            navController = mapNavigationController
        case .recentStops:
            viewController = recentsController
            navController = recentsNavigation
        case .bookmarks:
            viewController = bookmarksController
            navController = bookmarksNavigation
        case .contactUs:
            viewController = infoController
            navController = infoNavigation
        case .undefined:
            // swiftlint:disable no_fallthrough_only fallthrough
            fallthrough
            // swiftlint:enable no_fallthrough_only fallthrough
        default:
            DDLogError("Unhandled target in #file #line: \(navigationTarget.target)")
            return
        }

        tabBarController.selectedViewController = navController
        viewController.setNavigationTarget(navigationTarget)

        if navigationTarget.parameters["stop"] != nil, let stopID = navigationTarget.parameters["stopID"] as? String {
            let vc = StopViewController.init(stopID: stopID)
            mapNavigationController.pushViewController(vc, animated: true)
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
