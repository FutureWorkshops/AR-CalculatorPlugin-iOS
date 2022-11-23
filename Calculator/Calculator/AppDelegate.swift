//
//  AppDelegate.swift
//  Calculator
//
//

import UIKit
import MobileWorkflowCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// If requried, you can route certain app events here in order to be handled by one of your steps.
    weak var eventDelegate: AppEventDelegate?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    // MARK: UISceneSession Lifecycle
	
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
	
    /// Here you can pass URL events via the `EventService` to your plugin's steps.
    /*
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return self.eventDelegate?.application(app, open: url, options: options) ?? false
    }
    */

    // MARK: Push Notifications

    /// If your app supports push notifications, you should forward the events here.
    /*
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.eventDelegate?.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        self.eventDelegate?.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    */
}
