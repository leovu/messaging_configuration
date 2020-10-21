import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:messaging_configuration/messaging_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MessagingConfiguration {
  static setUpMessagingConfiguration(BuildContext context,
      {Function(Map<String, dynamic>) onMessageCallback,
      bool isAWSNotification = true,
      String iconApp,
      Function notificationInForeground}) async {
    MessagingConfig.singleton.init(context, onMessageCallback,
        iconApp: iconApp,
        isAWSNotification: isAWSNotification,
        notificationInForeground: notificationInForeground);
  }

  static const iOSPushToken =
      const MethodChannel('flutter.io/receivePushNotificationToken');
  static Future<String> getPushToken({bool isAWS = false}) async {
    String deviceToken = "";
    if (!kIsWeb) {
      if (Platform.isIOS && isAWS) {
        try {
          deviceToken =
              await iOSPushToken.invokeMethod('receivePushNotificationToken');
        } on PlatformException {
          print("Error receivePushNotificationToken");
          deviceToken = "";
        }
      } else {
        deviceToken = await FirebaseMessaging().getToken() ?? "";
      }
    }
    return deviceToken;
  }
}
