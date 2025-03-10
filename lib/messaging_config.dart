import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

class MessagingConfig {
  static final MessagingConfig _singleton = new MessagingConfig._internal();
  static MessagingConfig get singleton => _singleton;
  static int semaphore = 0;

  factory MessagingConfig() {
    return _singleton;
  }

  MessagingConfig._internal();

  BuildContext? context;
  Function(Map<String, dynamic>?)? onMessageBackgroundCallback;
  Function(Map<String, dynamic>?)? onMessageCallback;
  Function(Map<String, dynamic>?)? notificationInForeground;
  bool isCustomForegroundNotification = false;
  String? iconApp;
  bool? isVibrate;

  final _awsMessaging = const MethodChannel('flutter.io/awsMessaging');
  final _vibrate = const MethodChannel('flutter.io/vibrate');

  init(
      BuildContext context,
      Function(Map<String, dynamic>?) onMessageCallback,
      Function(Map<String, dynamic>?) onMessageBackgroundCallback,
      BackgroundMessageHandler onMessageBackground,
      Function(Map<String, dynamic>?)? notificationInForeground,
      bool isCustomForegroundNotification,
      String? iconApp,
      bool isVibrate) {
    this.context = context;
    this.iconApp = iconApp;
    this.onMessageBackgroundCallback = onMessageBackgroundCallback;
    this.onMessageCallback = onMessageCallback;
    this.notificationInForeground = notificationInForeground;
    this.isVibrate = isVibrate;
    this.isCustomForegroundNotification = isCustomForegroundNotification;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _awsMessaging.setMethodCallHandler(methodCallHandler);
    } else {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (semaphore != 0) {
          return;
        }
        semaphore = 1;
        Future.delayed(Duration(seconds: 1)).then((_) => semaphore = 0);
        print("FirebaseMessaging.onMessage");
        inAppMessageHandlerRemoteMessage(message);
      });
      FirebaseMessaging.onBackgroundMessage(onMessageBackground);
      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        if (message != null) {
          print("FirebaseMessaging.instance.getInitialMessage");
          myBackgroundMessageHandler(message.data);
        }
      });
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("FirebaseMessaging.onMessageOpenedApp");
        myBackgroundMessageHandler(message.data);
      });
    }
  }

  Future<dynamic> methodCallHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'onMessage':
        if (semaphore != 0) {
          return;
        }
        semaphore = 1;
        Future.delayed(Duration(seconds: 1)).then((_) => semaphore = 0);
        print("FirebaseMessaging.onMessage");
        Map<String, dynamic> message =
            Map<String, dynamic>.from(methodCall.arguments);
        this.inAppMessageHandler(message);
        return;
      case 'onLaunch':
        print("FirebaseMessaging.onLaunch");
        Map<String, dynamic> message =
            Map<String, dynamic>.from(methodCall.arguments);

        dynamic data;
        if (message["data"] != null) {
          data = message["data"];
        } else {
          data = message;
        }

        try {
          this.myBackgroundMessageHandler(json.decode(data));
        } catch (e) {
          this.myBackgroundMessageHandler(
              json.decode(json.encode(data)) as Map<String, dynamic>?);
        }
        return;
      default:
        throw PlatformException(code: 'notimpl', message: 'not implemented');
    }
  }

  Future<dynamic> inAppMessageHandlerRemoteMessage(
      RemoteMessage message) async {
    String? title = "";
    String? body = "";

    if (message.notification?.title != null) {
      title = message.notification!.title;
    } else if (message.data["title"] != null) {
      title = message.data["title"];
    }
    if (message.notification?.body != null) {
      body = message.notification!.body;
    } else if (message.data["body"] != null) {
      body = message.data["body"];
    }
    showAlertNotificationForeground(title, body, message.data);
  }

  Future<dynamic> inAppMessageHandler(Map<String, dynamic> message) async {
    String notiTitle;
    String notiDes;
    if (message.containsKey("notification")) {
      notiTitle = message["notification"]["title"].toString();
      notiDes = message["notification"]["body"].toString();
    } else {
      notiTitle = message["aps"]["alert"]["title"].toString();
      notiDes = message["aps"]["alert"]["body"].toString();
    }

    dynamic data;
    if (message["data"] != null) {
      data = message["data"];
    } else {
      data = message;
    }

    try {
      showAlertNotificationForeground(notiTitle, notiDes, json.decode(data));
    } catch (e) {
      showAlertNotificationForeground(notiTitle, notiDes,
          json.decode(json.encode(data)) as Map<String, dynamic>?);
    }
  }

  void showAlertNotificationForeground(
      String? notiTitle, String? notiDes, Map<String, dynamic>? message) {
    if (isCustomForegroundNotification) {
      if (onMessageCallback != null) {
        message!["title"] = notiTitle;
        message["body"] = notiDes;
        onMessageCallback!(message);
      }
    } else {
      showNotificationDefault(notiTitle, notiDes, message, omCB: () {
        if (onMessageCallback != null) {
          onMessageCallback!(message);
        }
      });
    }
  }

  Future<dynamic> myBackgroundMessageHandler(
      Map<String, dynamic>? message) async {
    if (onMessageBackgroundCallback != null) {
      onMessageBackgroundCallback!(message);
    }
  }

  void showNotificationDefault(
      String? notiTitle, String? notiDes, Map<String, dynamic>? message,
      {Function? omCB}) async {
    if (notiTitle != null && notiDes != null) {
      showOverlayNotification((context) {
        return BannerNotification(
          notiTitle: notiTitle,
          notiDescription: notiDes,
          iconApp: iconApp,
          onReplay: () {
            omCB!();
            OverlaySupportEntry.of(context)!.dismiss();
          },
        );
      }, duration: Duration(seconds: 5));
      if (!kIsWeb) {
        try {
          if (isVibrate!) {
            _vibrate.invokeMethod('vibrate');
          }
        } catch (e) {
          print(e);
        }
      }
    }
    notificationInForeground?.call(message);
  }
}

class BannerNotification extends StatefulWidget {
  final String? notiTitle;
  final String? notiDescription;
  final String? iconApp;
  final Function? onReplay;

  BannerNotification(
      {this.notiTitle, this.notiDescription, this.onReplay, this.iconApp});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return BannerNotificationState();
  }
}

class BannerNotificationState extends State<BannerNotification> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SafeArea(
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.up,
        onDismissed: (direction) {
          OverlaySupportEntry.of(context)!.dismiss(animate: false);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
              boxShadow: [
                BoxShadow(
                  color: HexColor("DEE7F1"),
                  blurRadius: 3.0,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Card(
              margin: EdgeInsets.zero,
              color: Colors.white,
              child: ListTile(
                onTap: () {
                  if (widget.onReplay != null) widget.onReplay!();
                },
                title: Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                          maxWidth: 40,
                          maxHeight: 40,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Container(
                            child: widget.iconApp == null
                                ? Container()
                                : Image.asset(widget.iconApp!,
                                    fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                widget.notiTitle!,
                                maxLines: 1,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 5.0, top: 5.0, bottom: 5.0),
                              child: Text(widget.notiDescription!,
                                  maxLines: 2,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 12),
                                  textAlign: TextAlign.left),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                subtitle: Container(
                  padding: EdgeInsets.only(top: 15, bottom: 5),
                  alignment: Alignment.center,
                  child: Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(2.5)),
                        color: HexColor("E2E4EC")),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
