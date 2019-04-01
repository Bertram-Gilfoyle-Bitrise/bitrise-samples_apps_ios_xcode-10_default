//
//  CPU.swift
//  Xcode-10_default
//
//  Created by Akos Birmacher on 2019. 04. 01..
//  Copyright © 2019. Bitrise. All rights reserved.
//

import Foundation

func hostCPULoadInfo() -> host_cpu_load_info? {
    
    let  HOST_CPU_LOAD_INFO_COUNT = MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride
    
    var size = mach_msg_type_number_t(HOST_CPU_LOAD_INFO_COUNT)
    let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
    
    let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: HOST_CPU_LOAD_INFO_COUNT) {
        host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
    }
    
    if result != KERN_SUCCESS{
        print("Error  - \(#file): \(#function) - kern_result_t = \(result)")
        return nil
    }
    let data = hostInfo.move()
    hostInfo.deallocate()
    return data
}

////
////

func getCPULoadInfo()-> String{
    var cpuUsageInfo = ""
    var cpuInfo: processor_info_array_t!
    var prevCpuInfo: processor_info_array_t?
    var numCpuInfo: mach_msg_type_number_t = 0
    var numPrevCpuInfo: mach_msg_type_number_t = 0
    var numCPUs: uint = 0
    let CPUUsageLock: NSLock = NSLock()
    var usage:Float32 = 0
    
    let mibKeys: [Int32] = [ CTL_HW, HW_NCPU ]
    mibKeys.withUnsafeBufferPointer() { mib in
        var sizeOfNumCPUs: size_t = MemoryLayout<uint>.size
        let status = sysctl(processor_info_array_t(mutating: mib.baseAddress), 2, &numCPUs, &sizeOfNumCPUs, nil, 0)
        if status != 0 {
            numCPUs = 1
        }
    }
    
    var numCPUsU: natural_t = 0
    let err: kern_return_t = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo);
    if err == KERN_SUCCESS {
        CPUUsageLock.lock()
        
        for i in 0 ..< Int32(numCPUs) {
            var inUse: Int32
            var total: Int32
            if let prevCpuInfo = prevCpuInfo {
                inUse = cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_USER)]
                    - prevCpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_USER)]
                    + cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_SYSTEM)]
                    - prevCpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_SYSTEM)]
                    + cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_NICE)]
                    - prevCpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_NICE)]
                total = inUse + (cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_IDLE)]
                    - prevCpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_IDLE)])
            } else {
                inUse = cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_USER)]
                    + cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_SYSTEM)]
                    + cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_NICE)]
                total = inUse + cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_IDLE)]
            }
            let coreInfo = Float(inUse) / Float(total)
            usage += coreInfo
            print(String(format: "Core: %u Usage: %f", i, Float(inUse) / Float(total)))
        }
        cpuUsageInfo = String(format:"%.2f",100 * Float(usage) / Float(numCPUs))
        CPUUsageLock.unlock()
        
        if let prevCpuInfo = prevCpuInfo {
            let prevCpuInfoSize: size_t = MemoryLayout<integer_t>.stride * Int(numPrevCpuInfo)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prevCpuInfo), vm_size_t(prevCpuInfoSize))
        }
        
        prevCpuInfo = cpuInfo
        numPrevCpuInfo = numCpuInfo
        
        cpuInfo = nil
        numCpuInfo = 0
    } else {
        print("Error!")
    }
    
    return cpuUsageInfo
}

func appCPUUsage() -> Double {
    var kr: kern_return_t
    var task_info_count: mach_msg_type_number_t
    
    task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
    var tinfo = [integer_t](repeating: 0, count: Int(task_info_count))
    
    kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), &tinfo, &task_info_count)
    if kr != KERN_SUCCESS {
        return -1
    }
    
    var thread_list: thread_act_array_t? = UnsafeMutablePointer(mutating: [thread_act_t]())
    var thread_count: mach_msg_type_number_t = 0
    defer {
        if let thread_list = thread_list {
            vm_deallocate(mach_task_self_, vm_address_t(UnsafePointer(thread_list).pointee), vm_size_t(thread_count))
        }
    }
    
    kr = task_threads(mach_task_self_, &thread_list, &thread_count)
    
    if kr != KERN_SUCCESS {
        return -1
    }
    
    var tot_cpu: Double = 0
    
    if let thread_list = thread_list {
        
        for j in 0 ..< Int(thread_count) {
            var thread_info_count = mach_msg_type_number_t(THREAD_INFO_MAX)
            var thinfo = [integer_t](repeating: 0, count: Int(thread_info_count))
            kr = thread_info(thread_list[j], thread_flavor_t(THREAD_BASIC_INFO),
                             &thinfo, &thread_info_count)
            if kr != KERN_SUCCESS {
                return -1
            }
            
            let threadBasicInfo = convertThreadInfoToThreadBasicInfo(thinfo)
            
            if threadBasicInfo.flags != TH_FLAGS_IDLE {
                tot_cpu += (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
            }
        } // for each thread
    }
    
    return tot_cpu
}

func convertThreadInfoToThreadBasicInfo(_ threadInfo: [integer_t]) -> thread_basic_info {
    var result = thread_basic_info()
    
    result.user_time = time_value_t(seconds: threadInfo[0], microseconds: threadInfo[1])
    result.system_time = time_value_t(seconds: threadInfo[2], microseconds: threadInfo[3])
    result.cpu_usage = threadInfo[4]
    result.policy = threadInfo[5]
    result.run_state = threadInfo[6]
    result.flags = threadInfo[7]
    result.suspend_count = threadInfo[8]
    result.sleep_time = threadInfo[9]
    
    return result
}
