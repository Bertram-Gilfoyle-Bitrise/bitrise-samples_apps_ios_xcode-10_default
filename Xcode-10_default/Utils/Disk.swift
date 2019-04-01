//
//  Disk.swift
//  Xcode-10_default
//
//  Created by Akos Birmacher on 2019. 04. 01..
//  Copyright © 2019. Bitrise. All rights reserved.
//

import Foundation

func deviceRemainingFreeSpaceInBytes() -> Int64? {
    let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
    guard
        let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: documentDirectory),
        let freeSize = systemAttributes[.systemFreeSize] as? NSNumber
        else {
            // something failed
            return nil
    }
    return freeSize.int64Value
}
