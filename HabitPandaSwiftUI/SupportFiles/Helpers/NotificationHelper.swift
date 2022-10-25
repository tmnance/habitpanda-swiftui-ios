//
//  NotificationHelper.swift
//  HabitPandaSwiftUI
//
//  Created by Tim Nance on 10/19/22.
//

import Foundation
import UserNotifications

class NotificationHelper {
    static var isGranted = false

    static func requestAuthorization() {
//        UIApplication.shared.registerForRemoteNotifications() // used for push notifications
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { success, error in
            if let error = error {
                print("ERROR: \(error.localizedDescription)")
            } else {
                NotificationHelper.isGranted = true
            }
        }
    }

    static func setCategories() {
        let clearRepeatAction = UNNotificationAction(
            identifier: "clear.repeat.action",
            title: "Stop Repeat",
            options: [])
        let habitCategory = UNNotificationCategory(
            identifier: "habit.reminder.category",
            actions: [clearRepeatAction],
            intentIdentifiers: [],
            options: [])
        UNUserNotificationCenter.current().setNotificationCategories([habitCategory])
    }

    static func cleanRepeatingNotifications() {
        // cleans notification with a userInfo key endDate which have expired.
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            for request in requests {
                if let endDate = request.content.userInfo["endDate"] {
                    if Date() >= (endDate as! Date) {
                        center.removePendingNotificationRequests(
                            withIdentifiers: [request.identifier]
                        )
                    }
                }
            }
        }
    }

    static func removeAllPendingNotifications() {
        let center = UNUserNotificationCenter.current()
        // remove all pending notifications which are scheduled but not yet delivered
        center.removeAllPendingNotificationRequests()
    }

    static func removeAllDeliveredNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
    }
}
