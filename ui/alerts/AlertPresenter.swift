//
//  AlertPresenter.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/28/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import UIKit
import SwiftMessages

@objc open class AlertPresenter: NSObject {

    /// Displays an alert on screen at the status bar level indicating a successful operation.
    ///
    /// - parameter title: The title of the alert
    /// - parameter body:  The body of the alert
    open class func showSuccess(_ title: String, body: String) {
        self.showMessage(.success, title: title, body: body)
    }

    /// Displays an alert on screen at the status bar level indicating an unsuccessful operation.
    ///
    /// - parameter title: The title of the alert
    /// - parameter body:  The body of the alert
    open class func showWarning(_ title: String, body: String) {
        self.showMessage(.warning, title: title, body: body)
    }

    open class func showMessage(_ theme: Theme, title: String, body: String) {
        var config = SwiftMessages.Config()
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        config.duration = .seconds(seconds: 5)
        config.dimMode = .gray(interactive: true)
        config.interactiveHide = true
        config.preferredStatusBarStyle = .lightContent

        // Instantiate a message view from the provided card view layout. SwiftMessages searches for nib
        // files in the main bundle first, so you can easily copy them into your project and make changes.
        let view = MessageView.viewFromNib(layout: .CardView)
        view.button?.isHidden = true
        view.configureTheme(.success)
        view.configureDropShadow()
        view.configureContent(title: title, body: body)

        // Show the message.
        SwiftMessages.show(config: config, view: view)
    }
}
