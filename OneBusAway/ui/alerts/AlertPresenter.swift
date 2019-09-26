//
//  AlertPresenter.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/28/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import OBAKit
import UIKit
import SwiftEntryKit
import SafariServices
import Hue

public enum Theme {
    case success, warning, error
}

@objc open class AlertPresenter: NSObject {

    /// Displays an alert on screen at the status bar level indicating a successful operation.
    ///
    /// - parameter title: The title of the alert
    /// - parameter body:  The body of the alert
    @objc open class func showSuccess(_ title: String, body: String) {
        showMessage(withTheme: .success, title: title, body: body)
    }

    /// Displays an alert on screen at the status bar level indicating an unsuccessful operation.
    ///
    /// - parameter title: The title of the alert
    /// - parameter body:  The body of the alert
    @objc open class func showWarning(_ title: String, body: String) {
        showMessage(withTheme: .warning, title: title, body: body)
    }

    /// Displays an alert on screen at the status bar level indicating an error.
    ///
    /// - parameter title: The title of the alert
    /// - parameter body:  The body of the alert
    @objc open class func showError(_ title: String, body: String) {
        showMessage(withTheme: .error, title: title, body: body)
    }

    /// Displays an error alert on screen generated from an error object.
    ///
    /// - Parameters:
    ///   - error: The error object from which the alert is generated.
    ///   - presentingController: The view controller from which a modal view controller should be presented if this error requires action on the user's part.
    @objc open class func showError(_ error: NSError, presentingController: UIViewController?) {
        guard
            let presentingController = presentingController,
            shouldDisplayErrorUrlInController(error),
            let urlString = error.userInfo[NSURLErrorFailingURLStringErrorKey] as? String,
            let url = URL.init(string: urlString)
        else {
            showMessage(from: error)
            return
        }

        let safari = SFSafariViewController.init(url: url)
        presentingController.present(safari, animated: true, completion: nil)
    }

    private class func showMessage(from error: NSError) {
        var userInfo: [String: Any] = [:]
        var referenceID: String?
        if let url = error.userInfo[NSURLErrorFailingURLStringErrorKey] as? NSString,
            let substr = url.oba_SHA1?.prefix(10) {
            referenceID = String(describing: substr)
            userInfo["reference"] = referenceID
        }
        Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: userInfo)
        showError(OBAStrings.error, body: errorMessage(from: error, referenceID: referenceID))
    }

    open class func showMessage(withTheme theme: Theme, title: String, body: String) {
        let attributes = buildTopEntryAttributes(theme: theme)

        let boldFont = OBATheme.boldBodyFont
        let font = OBATheme.bodyFont
        let textColor = UIColor.white

        let titleContent = EKProperty.LabelContent(text: title, style: .init(font: boldFont, color: textColor))
        let description = EKProperty.LabelContent(text: body, style: .init(font: font, color: textColor))
        let message = EKSimpleMessage(image: nil, title: titleContent, description: description)

		
        let labelStyle = EKProperty.LabelStyle(font: boldFont, color: .white)
		let closeButton = EKProperty.ButtonContent(label: EKProperty.LabelContent(text: OBAStrings.dismiss, style: labelStyle), backgroundColor: UIColor(white: 0.25, alpha: 0.25), highlightedBackgroundColor: UIColor(white: 0, alpha: 0.4), contentEdgeInset: 0) {
            SwiftEntryKit.dismiss()
        }
        let buttons = EKProperty.ButtonBarContent(with: closeButton, separatorColor: UIColor(white: 0.9, alpha: 0.4), expandAnimatedly: false)

        let alertMessage = EKAlertMessage(simpleMessage: message, buttonBarContent: buttons)
        let contentView = EKAlertMessageView(with: alertMessage)

        SwiftEntryKit.display(entry: contentView, using: attributes)
    }

    private class func errorMessage(from error: NSError, referenceID: String?) -> String {
        let wifiName = OBAReachability.wifiNetworkName

        var message: String
        if errorPotentiallyFromWifiCaptivePortal(error) && wifiName != nil {
            message = NSLocalizedString("alert_presenter.captive_wifi_portal_error_message", comment: "Error message displayed when the user is connecting to a Wi-Fi captive portal landing page.")
        }
        else {
            message = error.localizedDescription
        }

        // If the error includes an URL, append the SHA-1 hash
        // value of that URL to the error for legibility's sake.
        if let referenceID = referenceID {
            let formatString = NSLocalizedString("alerts.reference_format", comment: "ID: {Reference ID Number}")
            let referenceLine = String.init(format: formatString, referenceID)
            message = "\(message)\r\n\r\n\(referenceLine)"
        }

        return message
    }

    /// Returns true if the value of error.userInfo[NSURLErrorFailingURLStringErrorKey] should be displayed in a
    /// modal Safari view controller, and false if it shouldn't be. Currently only looks for cases where the user
    /// is on what appears to be a captive portal wifi network.
    ///
    /// - Parameter error: The error in question
    /// - Returns: true if a modal safari controller should be displayed and false otherwise.
    private class func shouldDisplayErrorUrlInController(_ error: NSError) -> Bool {
        if error.domain != NSURLErrorDomain && error.domain != (kCFErrorDomainCFNetwork as String) {
            return false
        }

        if error.code != NSURLErrorAppTransportSecurityRequiresSecureConnection {
            return false
        }

        return error.userInfo[NSURLErrorFailingURLStringErrorKey] != nil
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

extension AlertPresenter {
    private class func buildTopEntryAttributes(theme: Theme) -> EKAttributes {
        var attributes = EKAttributes.topFloat
        attributes.displayDuration = 2.0
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .easeOut)
        attributes.statusBar = .dark
        attributes.entryBackground = entryBackgroundStyle(theme: theme)
        attributes.shadow = .active(with: EKAttributes.Shadow.Value(color: .black, opacity: 0.5, radius: 2, offset: .zero))
        attributes.roundCorners = .all(radius: OBATheme.defaultCornerRadius)

        return attributes
    }

    private class func entryBackgroundStyle(theme: Theme) -> EKAttributes.BackgroundStyle {
        let themeColor: UIColor
        switch theme {
        case .success:
            themeColor = OBATheme.obaGreen
        case .error:
            themeColor = .red
        case .warning:
            themeColor = .orange
        }

		let colors = [themeColor, themeColor.add(hue: 0.0, saturation: 0.0, brightness: -0.20, alpha: 0.0)]
        return .gradient(gradient: EKAttributes.BackgroundStyle.Gradient(colors: colors, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: 1)))
    }
}
