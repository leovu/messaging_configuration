import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:messaging_configuration/messaging_config.dart';
import 'package:firebase_core/firebase_core.dart';

class MessagingConfiguration {
  static init({required FirebaseOptions options}) async {
    await Firebase.initializeApp(options: options);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await FirebaseMessaging.instance.requestPermission();
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
      );
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  static setUpMessagingConfiguration(
      {required BuildContext context,
      required Function(Map<String, dynamic>?) onMessageCallback,
      required Function(Map<String, dynamic>?) onMessageBackgroundCallback,
      required BackgroundMessageHandler onMessageBackground,
      String? iconApp,
      bool isCustomForegroundNotification = false,
      Function(Map<String, dynamic>?)? notificationInForeground,
      bool isVibrate = false}) async {
    MessagingConfig.singleton.init(
        context,
        onMessageCallback,
        onMessageBackgroundCallback,
        onMessageBackground,
        notificationInForeground,
        isCustomForegroundNotification,
        iconApp,
        isVibrate);
  }

  static void showNotificationDefault(String notiTitle, String notiDes,
      Map<String, dynamic> message, Function? onMessageCallback) {
    MessagingConfig.singleton.showNotificationDefault(
        notiTitle, notiDes, message,
        omCB: onMessageCallback);
  }

  static const iOSPushToken = const MethodChannel('flutter.io/awsMessaging');
  static Future<String?> getPushToken(
      {bool isAWS = false, String? vapidKey}) async {
    String? deviceToken;
    try {
      if (!kIsWeb) {
        if (defaultTargetPlatform == TargetPlatform.iOS && isAWS) {
          deviceToken = await (iOSPushToken.invokeMethod('getToken'));
        } else {
          deviceToken = await FirebaseMessaging.instance.getToken();
          if ((deviceToken ?? "").isEmpty) {
            await FirebaseMessaging.instance.onTokenRefresh.last;
            deviceToken = await FirebaseMessaging.instance.getToken();
          }
        }
      } else {
        deviceToken =
            await FirebaseMessaging.instance.getToken(vapidKey: vapidKey);
        if ((deviceToken ?? "").isEmpty) {
          await FirebaseMessaging.instance.onTokenRefresh.last;
          deviceToken = await FirebaseMessaging.instance.getToken();
        }
      }
    } catch (e) {
      print("getPushToken error: ${e.toString()}");
    }
    return deviceToken;
  }

  static Future<bool> requestPermission() async {
    bool status = false;
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      status = true;
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
      status = true;
    } else {
      print('User declined or has not accepted permission');
      status = false;
    }
    return status;
  }
}
