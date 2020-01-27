//
//  NSKeyedUnarchiver+UnarchiveTopLevelObjectObjC.swift
//  OBAKit
//
//  Created by Alan Chu on 1/18/20.
//  Copyright © 2020 OneBusAway. All rights reserved.
//

import Foundation

extension NSKeyedUnarchiver {
    /// Obj-C compatible method of unarchiving NSCoding objects. Don't use this for NSSecureCoding objects.
    ///
    /// The API for unarchiving top level NSCoding objects in Obj-C was removed in iOS 13, but still exists in Swift.
    /// The purpose of this method is to expose the Swift way of unarchiving top level object just like pre-iOS 13.
    /// The ideal solution would be to upgrade our NSCoding objects into NSSecureCoding, but I am unsure about
    /// backwards compatibility with previous app versions.
    ///
    /// Objective-C replacement: https://developer.apple.com/documentation/foundation/nskeyedunarchiver/1574811-unarchivetoplevelobjectwithdata?language=objc
    /// - parameter data: An object graph previously encoded by NSKeyedArchiver.
    /// - parameter errorPointer: On output, an error encountered during decoding, or nil if no error occurred.
    @objc public class func unarchiveTopLevelObject(for data: Data, error errorPointer: NSErrorPointer) -> Any? {
        do {
            return try self.unarchiveTopLevelObjectWithData(data)
        } catch {
            errorPointer?.pointee = error as NSError
            return nil
        }
    }
}
