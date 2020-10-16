import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:messaging_configuration/messaging_configuration.dart';

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
    MessagingConfiguration.setUpMessagingConfiguration(context,
        onMessageCallback: onMessageCallback,
        isAWSNotification: true,
        iconApp: "assets/logo/icon-app.png");
  }

  onMessageCallback(Map<String, dynamic> message) {
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Setup notification push'),
        ),
      ),
    );
  }
}
