//
//  AppDelegate.swift
//  iOS_SupportPlug
//
//  Created by macbook pro on 05/09/18.
//  Copyright © 2018 Omni-Bridge. All rights reserved.
//

import UIKit
import DropDown
import IQKeyboardManagerSwift
import UserNotifications
import Firebase
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        DropDown.startListeningToKeyboard()
        IQKeyboardManager.shared.enable = true
        UIApplication.shared.applicationIconBadgeNumber = 0
        self.registerPushNotification()
        if UserDefaults.standard.value(forKey: "StartURLFromServer") == nil{
            self.callToSetConfigeUrl()
        }else{
            self.loadInitialViewController()
        }
        // Override point for customization after application launch.
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    /// register Push Notification
    func registerPushNotification(){
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            DispatchQueue.main.async {
                UIApplication.shared.registerUserNotificationSettings(settings)
            }
        }
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    /// Submit FCM Token to server
    func callPostApiToSubmitToken(strToken : String) {
        let jsonData = ["userId": 1004,
                        "FirebaseToken": strToken] as [String : Any]
        APIs.performPost(requestStr: "/notification/SaveToken", jsonData: jsonData) { (response) in
            if let respDict = response as? NSDictionary{
                if respDict.value(forKey: "message") as! String == "Token Updated succesfully."{
                    UserDefaults.standard.setValue("YES", forKey: "SaveToken")
                }
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate : UNUserNotificationCenterDelegate{
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 1. Convert device token to string
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        Messaging.messaging().apnsToken = deviceToken as Data
        print("Firebase deviceToken registration token: \(deviceToken)")
        // 2. Print device token to use for PNs payloads
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // 1. Print out error if PNs registration not successful
        print("Failed to register for remote notifications with error: \(error)")
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(userInfo )
        // if UIApplication.shared.applicationState != .active {
        if userInfo["gcm.notification.type"] as? String == "Support"{
            window = UIWindow(frame: UIScreen.main.bounds)
            let suppDetailsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DetailSupportHistoryController") as! DetailSupportHistoryController
            if let strQueryId = userInfo["gcm.notification.QueryId"] as? String{
                suppDetailsVC.queryId = Int(strQueryId)!
            }
            let navigationController = UINavigationController(rootViewController: suppDetailsVC)
            navigationController.navigationBar.isTranslucent = false
            self.window?.rootViewController = navigationController
            self.window?.makeKeyAndVisible()
        }else if userInfo["gcm.notification.type"] as? String == "Custom"{
            window = UIWindow(frame: UIScreen.main.bounds)
            let notificationVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NotificationController") as! NotificationController
            let navigationController = UINavigationController(rootViewController: notificationVC)
            navigationController.navigationBar.isTranslucent = false
            self.window?.rootViewController = navigationController
            self.window?.makeKeyAndVisible()
        }
        // }
    }
    
    // MARK:- Confige URL
    
    /// Uset to set confige url from server
    private func callToSetConfigeUrl(){
        if General.isConnectedToNetwork(){
            if GetApiConfig.execute(){
                self.loadInitialViewController()
            }else{
                showErrorAlert(message: "Somwthing went wrong. Please contact to your Admin!")
            }
        }else{
            self.showErrorAlert(message: "No internet available. Please check your connection.")
        }
    }
    
    /// Used to load initial view controller
    private func loadInitialViewController(){
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController : UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = initialViewController
    }
    
    /// Used to show Error alert
    func showErrorAlert(message : String){
        let alertVC = UIAlertController(title: "Oops" , message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.cancel) { (alert) in
            exit(0)
        }
        alertVC.addAction(okAction)
        DispatchQueue.main.async {
            let alertWindow = UIWindow(frame: UIScreen.main.bounds)
            alertWindow.rootViewController = UIViewController()
            alertWindow.windowLevel = UIWindowLevelAlert + 1;
            alertWindow.makeKeyAndVisible()
            alertWindow.rootViewController?.present(alertVC, animated: true, completion: nil)
        }
    }
    
}
// MARK: - MessagingDelegate
extension AppDelegate : MessagingDelegate{
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        //UserDefaults.standard.set(fcmToken, forKey: "Token")
        self.callPostApiToSubmitToken(strToken: fcmToken)
        print("Firebase registration token: \(fcmToken)")
    }
}
