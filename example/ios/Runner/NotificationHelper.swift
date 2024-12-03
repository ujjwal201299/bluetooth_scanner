//
//  NotificationHelper.swift
//  Runner
//
//  Created by Aawaz Gyawali on 8/9/21.
//

import Foundation
import UserNotifications


class NotificationHelper {
    
    let notificationCenter = UNUserNotificationCenter.current()
    let options: UNAuthorizationOptions = [.alert, .sound, .badge]

    
    func requestPermission() {
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
    }
    func scheduleNotification(body: String) {
        
        let content = UNMutableNotificationContent()
        
        content.title = "SnowM Scanner"
        content.body = body
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: "geofence", content: content, trigger: trigger)
        notificationCenter.add(request)
    }
}
