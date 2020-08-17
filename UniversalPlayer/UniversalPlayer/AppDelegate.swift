//
//  AppDelegate.swift
//  UniversalPlayer
//
//  Created by XC_Young on 2020/7/28.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    /// 后台任务三分钟保活
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AudioTool.shared.setupAudioSession()
        AudioTool.shared.bindAudioSessionNotification()
        
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        backgroundTaskIdentifier = application.beginBackgroundTask(expirationHandler: {
            // * 你自己的任务
            
        })
        
    }


}

