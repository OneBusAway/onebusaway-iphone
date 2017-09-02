//
//  FileHelpers.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 3/17/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import Foundation

class FileHelpers: NSObject {
    /// Retrieves the file path to the specified file in the specified directory.
    /// Success of this method does not guarantee that the
    /// file actually exists!
    ///
    /// - Parameters:
    ///   - fileName: Name of file, including extenion
    ///   - inDirectory: The search path directory enum value
    /// - Returns: The full, absolute path to the specified file, whether or not it exists
    @objc public class func pathTo(fileName: String, inDirectory: FileManager.SearchPathDirectory) -> String? {
        let fileManager = FileManager.init()
        guard let directory = try? fileManager.url(for: inDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            return nil
        }

        let filePath: NSURL = directory.appendingPathComponent(fileName) as NSURL
        return filePath.filePathURL?.path
    }
}
