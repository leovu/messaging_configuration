import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:messaging_configuration/messaging_config.dart';
import 'package:firebase_core/firebase_core.dart';

class MessagingConfiguration {
  static init({bool isAWS = false, FirebaseOptions? options}) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (defaultTargetPlatform == TargetPlatform.iOS && isAWS) {
    } else {
      if (kIsWeb) {
        await Firebase.initializeApp(options: options);
      } else {
        await Firebase.initializeApp();
      }
      await FirebaseMessaging.instance.requestPermission();
      if(defaultTargetPlatform == TargetPlatform.android){
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
  }

  static setUpMessagingConfiguration(BuildContext context,
      {required Function(Map<String, dynamic>?) onMessageCallback,
      required Function(Map<String, dynamic>?) onMessageBackgroundCallback,
      required BackgroundMessageHandler onMessageBackground,
      bool isAWSNotification = true,
      String? iconApp,
      bool isCustomForegroundNotification = false,
      Function(Map<String, dynamic>?)? notificationInForeground,
      bool? isVibrate,
      int? channelId}) async {
    MessagingConfig.singleton.init(context, onMessageCallback,
        onMessageBackgroundCallback, onMessageBackground,
        iconApp: iconApp,
        isAWSNotification: isAWSNotification,
        isCustomForegroundNotification: isCustomForegroundNotification,
        notificationInForeground: notificationInForeground,
        isVibrate: isVibrate);
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
    String? deviceToken = "";
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.iOS && isAWS) {
        try {
          deviceToken = await (iOSPushToken.invokeMethod('getToken'));
        } on PlatformException {
          print("Error receivePushNotificationToken");
          deviceToken = "";
        }
      } else {
        deviceToken = (await FirebaseMessaging.instance.getToken())!;
        if (deviceToken == "") {
          await FirebaseMessaging.instance.onTokenRefresh.last;
          deviceToken = (await FirebaseMessaging.instance.getToken())!;
        }
      }
    } else {
      deviceToken =
          (await FirebaseMessaging.instance.getToken(vapidKey: vapidKey))!;
      if (deviceToken == "") {
        await FirebaseMessaging.instance.onTokenRefresh.last;
        deviceToken = (await FirebaseMessaging.instance.getToken())!;
      }
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
