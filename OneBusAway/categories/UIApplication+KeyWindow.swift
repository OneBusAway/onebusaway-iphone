//
//  UIApplication+KeyWindow.swift
//  OneBusAway
//
//  Created by Alan Chu on 1/15/20.
//  Copyright © 2020 OneBusAway. All rights reserved.
//

import Foundation

extension UIApplication {
    /// For iOS 13 compatibility. Using this is not recommended if we start supporting multiple windows.
    @objc var keyWindowFromWindows: UIWindow? {
        if #available(iOS 13, *) {
            return self.windows.filter { $0.isKeyWindow }.first
        } else {
            return self.keyWindow
        }
    }
}
