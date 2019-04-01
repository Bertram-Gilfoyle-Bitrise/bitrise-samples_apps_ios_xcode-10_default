//
//  Memory.swift
//  Xcode-10_default
//
//  Created by Akos Birmacher on 2019. 04. 01..
//  Copyright © 2019. Bitrise. All rights reserved.
//

import Foundation

func reportMemory() -> String {
    var taskInfo = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    
    if kerr == KERN_SUCCESS {
        return "Memory used: \(taskInfo.resident_size/1048576)"
    }
    else {
        return ("Error with task_info(): " +
            (String(cString: mach_error_string(kerr), encoding: String.Encoding.ascii) ?? "unknown error"))
    }
}
