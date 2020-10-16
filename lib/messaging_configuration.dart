import 'package:flutter/material.dart';
import 'package:messaging_configuration/messaging_config.dart';

class MessagingConfiguration {
  static setUpMessagingConfiguration(BuildContext context,
      {Function(Map<String, dynamic>) onMessageCallback,
      bool isAWSNotification = true,
      String iconApp}) async {
    MessagingConfig.singleton.init(context, onMessageCallback,
        iconApp: iconApp, isAWSNotification: isAWSNotification);
  }
}
