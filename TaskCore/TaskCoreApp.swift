//
//  TaskCoreApp.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//

import SwiftUI
import CloudKit
import UserNotifications

@main
struct TaskCoreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Request notification permission for CloudKit changes
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
        
        // Setup background app refresh and remote notifications
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Check if this is a CloudKit notification
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            print("Received CloudKit notification: \(notification)")
            
            // Post notification to trigger sync
            NotificationCenter.default.post(name: .NSPersistentStoreRemoteChange, object: nil)
            completionHandler(.newData)
            return
        }
        
        completionHandler(.noData)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Successfully registered for remote notifications")
    }
    
    // Handle when app becomes active - good time to check iCloud status
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Post a notification that can be observed by TodoManager to recheck iCloud
        NotificationCenter.default.post(name: NSNotification.Name("AppDidBecomeActive"), object: nil)
    }
}
