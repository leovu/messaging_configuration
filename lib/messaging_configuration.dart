import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:messaging_configuration/messaging_config.dart';
import 'package:firebase_core/firebase_core.dart';

class MessagingConfiguration {
  static setUpMessagingConfiguration(BuildContext context,
      {Function(Map<String, dynamic>) onMessageCallback,
      Function(Map<String, dynamic>) onMessageBackgroundCallback,
      bool isAWSNotification = true,
      String iconApp,
      Function notificationInForeground,
      bool isVibrate,
      String sound,
      int channelId}) async {
    if (kIsWeb) {
      return;
    }
    String asset;
    if (sound != null) {
      AudioCache player = AudioCache();
      if (Platform.isIOS) {
        asset = sound;
      } else {
        asset = await getAbsoluteUrl(sound, player);
      }
    }
    MessagingConfig.singleton.init(
        context, onMessageCallback, onMessageBackgroundCallback,
        iconApp: iconApp,
        isAWSNotification: isAWSNotification,
        notificationInForeground: notificationInForeground,
        isVibrate: isVibrate,
        sound: (asset != null && channelId != null)
            ? {"asset": asset, "channelId": channelId}
            : null);
  }

  static const iOSPushToken = const MethodChannel('flutter.io/awsMessaging');
  static Future<String> getPushToken({bool isAWS = false}) async {
    String deviceToken = "";
    if (!kIsWeb) {
      if (Platform.isIOS && isAWS) {
        try {
          deviceToken = await iOSPushToken.invokeMethod('getToken');
        } on PlatformException {
          print("Error receivePushNotificationToken");
          deviceToken = "";
        }
      } else {
        if (Firebase.apps.length == 0) {
          await Firebase.initializeApp();
        }
        deviceToken = await FirebaseMessaging.instance.getToken();
      }
    }
    return deviceToken;
  }

  static Future<String> getAbsoluteUrl(
      String fileName, AudioCache cache) async {
    String prefix = 'assets/';
    if (kIsWeb) {
      return 'assets/$prefix$fileName';
    }
    Uri file = await cache.load(fileName);
    return file.path;
  }
}
