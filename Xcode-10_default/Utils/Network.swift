//
//  Network.swift
//  Xcode-10_default
//
//  Created by Akos Birmacher on 2019. 04. 01..
//  Copyright © 2019. Bitrise. All rights reserved.
//

import Foundation

extension SystemDataUsage {
    
    public static var wifiCompelete: UInt64 {
        return SystemDataUsage.getDataUsage().wifiSent + SystemDataUsage.getDataUsage().wifiReceived
    }
    
    public static var wwanCompelete: UInt64 {
        return SystemDataUsage.getDataUsage().wirelessWanDataSent + SystemDataUsage.getDataUsage().wirelessWanDataReceived
    }
    
}

class SystemDataUsage {
    
    private static let wwanInterfacePrefix = "pdp_ip"
    private static let wifiInterfacePrefix = "en"
    
    class func getDataUsage() -> DataUsageInfo {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var dataUsageInfo = DataUsageInfo()
        
        guard getifaddrs(&ifaddr) == 0 else { return dataUsageInfo }
        while let addr = ifaddr {
            guard let info = getDataUsageInfo(from: addr) else {
                ifaddr = addr.pointee.ifa_next
                continue
            }
            dataUsageInfo.updateInfoByAdding(info)
            ifaddr = addr.pointee.ifa_next
        }
        
        freeifaddrs(ifaddr)
        
        return dataUsageInfo
    }
    
    private class func getDataUsageInfo(from infoPointer: UnsafeMutablePointer<ifaddrs>) -> DataUsageInfo? {
        let pointer = infoPointer
        let name: String! = String(cString: pointer.pointee.ifa_name)
        let addr = pointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_LINK) else { return nil }
        
        return dataUsageInfo(from: pointer, name: name)
    }
    
    private class func dataUsageInfo(from pointer: UnsafeMutablePointer<ifaddrs>, name: String) -> DataUsageInfo {
        var networkData: UnsafeMutablePointer<if_data>?
        var dataUsageInfo = DataUsageInfo()
        
        if name.hasPrefix(wifiInterfacePrefix) {
            networkData = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
            if let data = networkData {
                dataUsageInfo.wifiSent += UInt64(data.pointee.ifi_obytes)
                dataUsageInfo.wifiReceived += UInt64(data.pointee.ifi_ibytes)
            }
            
        } else if name.hasPrefix(wwanInterfacePrefix) {
            networkData = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
            if let data = networkData {
                dataUsageInfo.wirelessWanDataSent += UInt64(data.pointee.ifi_obytes)
                dataUsageInfo.wirelessWanDataReceived += UInt64(data.pointee.ifi_ibytes)
            }
        }
        return dataUsageInfo
    }
}

struct DataUsageInfo {
    var wifiReceived: UInt64 = 0
    var wifiSent: UInt64 = 0
    var wirelessWanDataReceived: UInt64 = 0
    var wirelessWanDataSent: UInt64 = 0
    
    mutating func updateInfoByAdding(_ info: DataUsageInfo) {
        wifiSent += info.wifiSent
        wifiReceived += info.wifiReceived
        wirelessWanDataSent += info.wirelessWanDataSent
        wirelessWanDataReceived += info.wirelessWanDataReceived
    }
}

class Downloader {
    class func load(URL: NSURL) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: URL as URL)
        request.httpMethod = "GET"
        let task = session.dataTask(with: request, completionHandler: { (data: Data!, response: URLResponse!, error: Error!) -> Void in
        
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("Success: \(statusCode)")
                
                // This is your file-variable:
                // data
            }
            else {
                // Failure
                print("Failure: %@", error.localizedDescription);
            }
        })
        task.resume()
    }
}

