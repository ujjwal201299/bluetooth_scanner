import UIKit
import Flutter
import snowm_scanner

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let noTouchJob: BackgroundReceiver = BackgroundReceiver.shared
    BackgroundBeaconScanner.shared.delegate = noTouchJob
    BackgroundBeaconScanner.shared.setLocationDelegate(locationDelegate: noTouchJob)
    NotificationHelper().requestPermission()
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}

