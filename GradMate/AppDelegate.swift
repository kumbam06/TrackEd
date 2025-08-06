import UIKit
import Firebase
import GoogleSignIn
import UserNotifications
import FirebaseMessaging
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("[Push] Notification permission error: \(error.localizedDescription)")
            } else {
                print("[Push] Notification permission granted: \(granted)")
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        Messaging.messaging().delegate = self
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Push Notification Delegate Methods
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("[Push] APNS token set successfully")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[Push] Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("[Push] FCM registration token: \(fcmToken ?? "nil")")
        // Save the FCM token to Firestore under the user's document
        if let fcmToken = fcmToken, let user = Auth.auth().currentUser {
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "fcmToken": fcmToken,
                "lastTokenUpdate": FieldValue.serverTimestamp()
            ], merge: true) { error in
                if let error = error {
                    print("[Push] Error saving FCM token: \(error.localizedDescription)")
                } else {
                    print("[Push] FCM token saved successfully")
                }
            }
        }
    }

    // Handle foreground notification display
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("[Push] Received notification in foreground: \(userInfo)")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("[Push] Notification tapped: \(userInfo)")
        
        // Handle message notification navigation
        if let type = userInfo["type"] as? String, type == "message",
           let chatId = userInfo["chatId"] as? String {
            // Post notification to navigate to chat
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToChat"),
                object: nil,
                userInfo: ["chatId": chatId]
            )
        }
        
        completionHandler()
    }
    
    // Handle notification when app is not running
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("[Push] Received remote notification: \(userInfo)")
        
        // Handle message notification navigation
        if let type = userInfo["type"] as? String, type == "message",
           let chatId = userInfo["chatId"] as? String {
            // Post notification to navigate to chat
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToChat"),
                object: nil,
                userInfo: ["chatId": chatId]
            )
        }
        
        completionHandler(.newData)
    }
} 
