import 'package:flutter/material.dart';
import 'dart:async';

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
          isAWSNotification: true,
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

  onMessageCallback(Map<String, dynamic> message) {
    print(message);
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
