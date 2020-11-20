//
//  PushToken.swift
//  Runner
//
//  Created by Long Vu on 8/15/19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import UIKit
import Flutter

class PushToken {
    static let shared = PushToken()
    func setupAnalyzing(window:UIWindow, application: UIApplication) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.createNotification(application)
        }
        let controller : FlutterViewController = window.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "flutter.io/awsMessaging",
                                           binaryMessenger: controller.binaryMessenger)
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard call.method == "getToken" else {
                result(FlutterMethodNotImplemented)
                return
            }
            self?.receivePushNotificationToken(result: result)
        })
    }
    func receivePushNotificationToken(result: FlutterResult) {
        result(UserDefaults.standard.string(forKey: "flutter.PUSH_TOKEN_KEY") ?? "")
    }
}

extension AppDelegate {
    func createNotification(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
    }
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(token, forKey: "flutter.PUSH_TOKEN_KEY")
    }
    @available(iOS 10.0, *)
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print(notification.request.content.userInfo)
        callbackFlutterNotifcation(notification.request.content.userInfo)
    }
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(userInfo)
        callbackFlutterNotifcation(userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print(userInfo)
        callbackFlutterNotifcation(userInfo)
    }
    @available(iOS 10.0, *)
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        callbackFlutterNotifcation(response.notification.request.content.userInfo)
    }
    func callbackFlutterNotifcation(_ userInfo:[AnyHashable : Any]) {
        var dictionary:[String:Any] = [:]
        if let controller = window.rootViewController as? FlutterViewController , let dict = userInfo as? [String:Any] {
            dictionary = dict
            if let aps:[String:Any] = dict["aps"] as? [String : Any] {
                dictionary["notification"] = aps["alert"]
                dictionary.removeValue(forKey: "aps")
            }
            let state = UIApplication.shared.applicationState
            let channel =  FlutterMethodChannel(name: "flutter.io/awsMessaging", binaryMessenger: controller.binaryMessenger)
            if state == .active {
                channel.invokeMethod("onMessage", arguments: dictionary)
            } else {
                channel.invokeMethod("onLaunch", arguments: dictionary)
            }
        }
    }
}
