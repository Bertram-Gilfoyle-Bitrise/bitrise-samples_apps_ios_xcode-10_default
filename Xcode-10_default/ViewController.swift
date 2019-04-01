//
//  ViewController.swift
//  Xcode-10_default
//
//  Created by Akos Birmacher on 2019. 01. 25..
//  Copyright © 2019. Bitrise. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height / 2.0))
        self.view.addSubview(webView)
        let url = URL(string: "https://www.index.hu")
        webView.load(URLRequest(url: url!))
        
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        
        
    }

    @IBAction func onButtonTapped(_ sender: Any) {
        let cpu_app = appCPUUsage()
        print("app CPU usage:", cpu_app)
        
        let appMemoryUsage = reportMemory()
        print("app Memory usage: ", appMemoryUsage)
        
        let freeSize = deviceRemainingFreeSpaceInBytes()
        print("free size: ", freeSize ?? 0)
        
//        if let URL = NSURL(string: "https://app.bitrise.io/project_file_storage_document/17626") {
//            Downloader.load(URL: URL)
//        }
        
        let networkInfo = DataUsageInfo()
        print("networkInfo: ", networkInfo)
    }
}

func ping() {
    if let url = URL(string: "https://apple.com") {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        URLSession(configuration: .default)
            .dataTask(with: request) { (_, response, error) -> Void in
                guard error == nil else {
                    print("Error:", error ?? "")
                    return
                }
                
                guard (response as? HTTPURLResponse)?
                    .statusCode == 200 else {
                        print("down")
                        return
                }
                
                print("up")
            }
            .resume()
    }
}
