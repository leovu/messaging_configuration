import 'dart:io';

import 'package:audioplayers/audio_cache.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:messaging_configuration/messaging_config.dart';

class MessagingConfiguration {
  static setUpMessagingConfiguration(BuildContext context,
      {Function(Map<String, dynamic>) onMessageCallback,
        bool isAWSNotification = true,
        String iconApp,
        Function notificationInForeground,
        dynamic onBackgroundMessageHandler,
        bool isVibrate,
        String sound,
        int channelId}) async {
    if (kIsWeb) { return; }
    String asset;
    if (sound != null) {
      AudioCache player = AudioCache();
      if(Platform.isIOS) {
        asset = sound;
      }
      else {
        asset = await player.getAbsoluteUrl(sound);
      }
    }
    MessagingConfig.singleton.init(context, onMessageCallback,
        iconApp: iconApp,
        isAWSNotification: isAWSNotification,
        notificationInForeground: notificationInForeground,
        onBackgroundMessageHandler:onBackgroundMessageHandler,
        isVibrate: isVibrate,
        sound: (asset != null && channelId != null)
            ? {"asset": asset, "channelId": channelId}
            : null);
  }

  static const iOSPushToken =
  const MethodChannel('flutter.io/awsMessaging');
  static Future<String> getPushToken({bool isAWS = false}) async {
    String deviceToken = "";
    if (!kIsWeb) {
      if (Platform.isIOS && isAWS) {
        try {
          deviceToken =
          await iOSPushToken.invokeMethod('getToken');
        } on PlatformException {
          print("Error receivePushNotificationToken");
          deviceToken = "";
        }
      } else {
        await Firebase.initializeApp();
        deviceToken = await FirebaseMessaging.instance.getToken();
      }
    }
    return deviceToken;
  }
}
