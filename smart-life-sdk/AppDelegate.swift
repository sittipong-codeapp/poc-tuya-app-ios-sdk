//
//  AppDelegate.swift
//  smart-life-sdk
//
//  Created by Sittipong Suwannatrai on 10/1/23.
//

import UIKit
import SVProgressHUD
import TuyaSmartBaseKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        TuyaSmartSDK.sharedInstance().start(withAppKey: AppKey.appKey, secretKey: AppKey.secretKey)
        
        
        #if DEBUG
        TuyaSmartSDK.sharedInstance().debugMode = true
        #endif
        
//        SVProgressHUD.setDefaultStyle(.dark)
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if #available(iOS 13.0, *) {
            // Will go into scene delegate.
        } else {
            if TuyaSmartUser.sharedInstance().isLogin {
                // User has already logged, launch the app with the main view controller.
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateInitialViewController()
                window?.rootViewController = vc
                window?.makeKeyAndVisible()
            } else {
                // There's no user logged, launch the app with the login and register view controller.
                let storyboard = UIStoryboard(name: "Login", bundle: nil)
                let vc = storyboard.instantiateInitialViewController()
                window?.rootViewController = vc
                window?.makeKeyAndVisible()
            }
        }
        
        return true
    }
    
}
