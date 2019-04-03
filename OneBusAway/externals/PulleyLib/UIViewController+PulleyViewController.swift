//
//  UIViewController+PulleyViewController.swift
//  Pulley
//
//  Created by Guilherme Souza on 4/28/18.
//  Copyright © 2018 52inc. All rights reserved.
//

@objc public extension UIViewController {

    /// If this viewController references to a PulleyViewController, return it.
    var pulleyViewController: PulleyViewController? {
        var parentVC = parent
        while parentVC != nil {
            if let pulleyViewController = parentVC as? PulleyViewController {
                return pulleyViewController
            }
            parentVC = parentVC?.parent
        }
        return nil
    }
}
