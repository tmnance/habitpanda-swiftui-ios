//
//  AppDelegate.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/20/22.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    var router: Router? = nil

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        setupNotificationCenter()
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // TODO: may not work anymore; see https://www.hackingwithswift.com/books/ios-swiftui/how-to-be-notified-when-your-swiftui-app-moves-to-the-background
        ReminderNotificationService.refreshNotificationsForAllReminders()
    }
}

// MARK: - Notification Center Methods
extension AppDelegate: UNUserNotificationCenterDelegate {
    func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            NotificationHelper.isGranted = true
        }
        NotificationHelper.setCategories()
        NotificationHelper.cleanRepeatingNotifications()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // enables local notifications to be viewed when the app is focused
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationHelper.cleanRepeatingNotifications()
        print("Did recieve response: \(response.actionIdentifier)")

        let userInfo = response.notification.request.content.userInfo
        if
            let reminderUUID = UUID(uuidString: userInfo["reminderUUID"] as? String ?? ""),
            let reminder = Reminder.get(withUUID: reminderUUID),
            let habit = reminder.habit
            {
            // TODO: find a way to do this without relying on a class singleton
            Router.shared.navigateToHabit(habit)
        }

        if response.notification.request.identifier == "testIdentifier" {
            print("handling testIdentifier")
        }
        if response.actionIdentifier == "clear.repeat.action" {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [response.notification.request.identifier]
            )
        }

        completionHandler()
    }
}
