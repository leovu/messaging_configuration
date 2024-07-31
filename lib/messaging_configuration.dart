import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:messaging_configuration/messaging_config.dart';
import 'package:firebase_core/firebase_core.dart';

class MessagingConfiguration {
  static init({bool isAWS = false, FirebaseOptions? options}) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);



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
      String? sound,
      int? channelId}) async {
    String? asset;
    if (sound != null) {
      AudioCache player = AudioCache();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        asset = sound;
      } else {
        asset = await getAbsoluteUrl(sound, player);
      }
    }
    MessagingConfig.singleton.init(context, onMessageCallback,
        onMessageBackgroundCallback, onMessageBackground,
        iconApp: iconApp,
        isAWSNotification: isAWSNotification,
        isCustomForegroundNotification: isCustomForegroundNotification,
        notificationInForeground: notificationInForeground,
        isVibrate: isVibrate,
        sound: (asset != null && channelId != null)
            ? {"asset": asset, "channelId": channelId}
            : null);
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

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCRXOJwNtna3EKFtDSFEBYasVBhaPri0oo',
    appId: '1:230523064998:android:3dc7d4c6eb4cce5a55da67',
    messagingSenderId: '230523064998',
    projectId: 'hocgiagacon',
    storageBucket: 'hocgiagacon.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDwyLGsqx4VXW-9bbEdIAtG0tn_UalMkec',
    appId: '1:230523064998:ios:4b51083c391cc64a55da67',
    messagingSenderId: '230523064998',
    projectId: 'hocgiagacon',
    storageBucket: 'hocgiagacon.appspot.com',
    iosBundleId: 'chickencombat',
  );
}
