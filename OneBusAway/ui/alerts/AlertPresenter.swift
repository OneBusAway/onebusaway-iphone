//
//  AlertPresenter.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/28/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import OBAKit
import UIKit
import SwiftMessages

@objc open class AlertPresenter: NSObject {

    /// Displays an alert on screen at the status bar level indicating a successful operation.
    ///
    /// - parameter title: The title of the alert
    /// - parameter body:  The body of the alert
    open class func showSuccess(_ title: String, body: String) {
        self.showMessage(withTheme: .success, title: title, body: body)
    }

    /// Displays an alert on screen at the status bar level indicating an unsuccessful operation.
    ///
    /// - parameter title: The title of the alert
    /// - parameter body:  The body of the alert
    open class func showWarning(_ title: String, body: String) {
        self.showMessage(withTheme: .warning, title: title, body: body)
    }

    /// Displays an alert on screen at the status bar level indicating an error.
    ///
    /// - parameter title: The title of the alert
    /// - parameter body:  The body of the alert
    open class func showError(_ title: String, body: String) {
        self.showMessage(withTheme: .error, title: title, body: body)
    }

    /// Displays an error alert on screen generated from an error object.
    ///
    /// - Parameter error: The error object from which the alert is generated.
    open class func showError(_ error: NSError) {
        Crashlytics.sharedInstance().recordError(error)
        self.showError(OBAStrings.error, body: errorMessage(from: error))
    }

    open class func showMessage(withTheme theme: Theme, title: String, body: String) {
        var config = SwiftMessages.Config()
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        config.duration = theme == .error ? .forever : .seconds(seconds: 5)
        config.dimMode = .gray(interactive: true)
        config.interactiveHide = true
        config.preferredStatusBarStyle = .lightContent

        // Instantiate a message view from the provided card view layout. SwiftMessages searches for nib
        // files in the main bundle first, so you can easily copy them into your project and make changes.
        let view = MessageView.viewFromNib(layout: .CardView)
        view.configureContent(title: title, body: body, iconImage: nil, iconText: nil, buttonImage: nil, buttonTitle: NSLocalizedString("msg_close", comment: "close"), buttonTapHandler: { _ in
            SwiftMessages.hide()
        })
        view.configureTheme(theme)
        view.configureDropShadow()

        // Show the message.
        SwiftMessages.show(config: config, view: view)
    }

    private class func errorMessage(from error: NSError) -> String {
        let wifiName = OBAReachability.wifiNetworkName

        if (errorPotentiallyFromWifiCaptivePortal(error) && wifiName != nil) {
            return NSLocalizedString("alert_presenter.captive_wifi_portal_error_message", comment: "Error message displayed when the user is connecting to a Wi-Fi captive portal landing page.")
        }
        else {
            return error.localizedDescription
        }
    }

    private class func errorPotentiallyFromWifiCaptivePortal(_ error: NSError) -> Bool {
        if error.domain == NSCocoaErrorDomain && error.code == 3840 {
            return true
        }

        if error.domain == (kCFErrorDomainCFNetwork as String) && error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
            return true
        }

        return false
    }
}
