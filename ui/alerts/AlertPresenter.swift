//
//  AlertPresenter.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/28/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import UIKit
import SwiftMessages

@objc public class AlertPresenter: NSObject {

    public class func showWarning(title: String, body: String) {

        var config = SwiftMessages.Config()
        config.presentationContext = .Window(windowLevel: UIWindowLevelStatusBar)
        config.duration = .Seconds(seconds: 5)
        config.dimMode = .Gray(interactive: true)
        config.interactiveHide = true
        config.preferredStatusBarStyle = .LightContent

        // Instantiate a message view from the provided card view layout. SwiftMessages searches for nib
        // files in the main bundle first, so you can easily copy them into your project and make changes.
        let view = MessageView.viewFromNib(layout: .CardView)
        view.button?.hidden = true
        view.configureTheme(.Warning)
        view.configureDropShadow()
        view.configureContent(title: title, body: body)

        // Show the message.
        SwiftMessages.show(config: config, view: view)
    }
}
