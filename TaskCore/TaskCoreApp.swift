//
//  TaskCoreApp.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//

import SwiftUI
import CloudKit
import UserNotifications
import BackgroundTasks

@main
struct TaskCoreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .background:
                        print("App moved to background")
                        // Timer state is automatically saved by TimerTabView
                    case .active:
                        print("App became active")
                        // Timer state is automatically restored by TimerTabView
                        // Clear badge using new API
                        if #available(iOS 17.0, *) {
                            UNUserNotificationCenter.current().setBadgeCount(0)
                        } else {
                            UIApplication.shared.applicationIconBadgeNumber = 0
                        }
                    case .inactive:
                        print("App became inactive")
                    @unknown default:
                        break
                    }
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Request notification permission for timer completion
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
        
        // REMOVED: The problematic background task that never ended
        // UIApplication.shared.beginBackgroundTask { }
        
        return true
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Clear badge when notification is tapped using new API
        if #available(iOS 17.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        completionHandler()
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
    
    // Handle when app becomes active - good time to check timer state
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear any badge using new API
        if #available(iOS 17.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        // Post a notification that can be observed by TodoManager to recheck timer
        NotificationCenter.default.post(name: NSNotification.Name("AppDidBecomeActive"), object: nil)
    }
}
