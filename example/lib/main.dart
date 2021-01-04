import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:messaging_configuration/messaging_configuration.dart';
import 'package:overlay_support/overlay_support.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      MessagingConfiguration.setUpMessagingConfiguration(context,
          onMessageCallback: onMessageCallback,
          notificationInForeground: _notificationInForeground,
          onBackgroundMessageHandler: _myBackgroundMessageHandler,
          isAWSNotification: false,
          iconApp: "assets/logo/icon-app.png",
          isVibrate: true,
          sound: "audio/alert_tone.mp3",
          channelId: 105);
      MessagingConfiguration.getPushToken().then((value) {
        Clipboard.setData(new ClipboardData(text: value)).then((_) {
          print(value);
        });
      });
    });
  }

  Future<dynamic> _myBackgroundMessageHandler(Map<String, dynamic> message) async {
    if (message.containsKey('data')) {
      // Handle data message
      final dynamic data = message['data'];
    }

    if (message.containsKey('notification')) {
      // Handle notification message
      final dynamic notification = message['notification'];
    }

    // Or do other work.
  }

  onMessageCallback(Map<String, dynamic> message) {
    print(message);
  }
  _notificationInForeground() {
    print("_notificationInForeground");
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Center(
            child: Text('Setup notification push'),
          ),
        ),
      ),
    );
  }
}
