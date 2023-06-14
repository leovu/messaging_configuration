import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter_mute/flutter_mute.dart';

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

  Function(Map<String, dynamic>?)? onMessageCallback;
  Function(Map<String, dynamic>?)? onMessageBackgroundCallback;
  bool isCustomForegroundNotification = false;
  Function? notificationInForeground;
  String? iconApp;
  bool? isVibrate;
  // List<String> arrId = [];
  Map<String, dynamic>? sound;

  final _awsMessaging = const MethodChannel('flutter.io/awsMessaging');
  final _vibrate = const MethodChannel('flutter.io/vibrate');
  BuildContext? context;
  init(BuildContext context, Function(Map<String, dynamic>?)? onMessageCallback,
      Function(Map<String, dynamic>?)? onMessageBackgroundCallback,
      {bool isAWSNotification = true,
      bool isCustomForegroundNotification = false,
      String? iconApp,
      Function? notificationInForeground,
      bool? isVibrate = false,
      Map<String, dynamic>? sound}) {
    this.context = context;
    this.iconApp = iconApp;
    this.onMessageCallback = onMessageCallback;
    this.onMessageBackgroundCallback = onMessageBackgroundCallback;
    this.notificationInForeground = notificationInForeground;
    this.isVibrate = isVibrate;
    this.isCustomForegroundNotification = isCustomForegroundNotification;
    this.sound = sound;
    if (sound != null) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        const audioSoundSetup =
            const MethodChannel('flutter.io/audioSoundSetup');
        audioSoundSetup
            .invokeMethod('setupSound', sound)
            .then((value) => print(value));
      }
    }
    if (defaultTargetPlatform == TargetPlatform.iOS && isAWSNotification) {
      setHandler();
    } else {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (semaphore != 0) {
          return;
        }
        semaphore = 1;
        Future.delayed(Duration(seconds: 1)).then((_) => semaphore = 0);
        print("onMessage: $message");
        // if (!arrId.contains(message.messageId)) {
        //   arrId.add(message.messageId);
        inAppMessageHandlerRemoteMessage(message);
        // }
      });
      // FirebaseMessaging.onBackgroundMessage((RemoteMessage message) {
      //   print("onBackground: $message");
      //   return myBackgroundMessageHandler(message.data);
      // });
      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        print("getInitialMessage: $message");
        if (message != null) myBackgroundMessageHandler(message.data);
      });
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("onResume: $message");
        myBackgroundMessageHandler(message.data);
      });
    }
  }

  void setHandler() {
    _awsMessaging.setMethodCallHandler(methodCallHandler);
  }

  Future<dynamic> methodCallHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'onMessage':
        print("onMessage: ${methodCall.arguments}");
        Map<String, dynamic> message =
            Map<String, dynamic>.from(methodCall.arguments);
        this.inAppMessageHandler(message);
        return null;
      case 'onLaunch':
        print("onLaunch: ${methodCall.arguments}");
        Map<String, dynamic> message =
            Map<String, dynamic>.from(methodCall.arguments);
        try {
          this.myBackgroundMessageHandler(json.decode(message["data"]));
        } catch (e) {
          print(e);
          final validMap =
              json.decode(json.encode(message["data"])) as Map<String, dynamic>?;
          this.myBackgroundMessageHandler(validMap);
        }
        return null;
      default:
        throw PlatformException(code: 'notimpl', message: 'not implemented');
    }
  }

  Future<dynamic> inAppMessageHandlerRemoteMessage(
      RemoteMessage message) async {
    String? title ="";
    String? body ="";

    if(message?.notification?.title!=null){
      title = message.notification!.title;
    }else if(message.data["title"]!=null){
      title = message.data["title"];
    }
    if(message?.notification?.body!=null){
      body = message.notification!.body;
    }else if(message.data["body"]!=null){
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
    try {
      showAlertNotificationForeground(
          notiTitle, notiDes, json.decode(message["data"]));
    } catch (e) {
      print(e);
      final validMap =
          json.decode(json.encode(message["data"])) as Map<String, dynamic>?;
      showAlertNotificationForeground(notiTitle, notiDes, validMap);
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
      showNotificationDefault(notiTitle, notiDes, message, omCB: (){
        if(onMessageCallback != null) {
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
      if(!kIsWeb) {
        try {
          if (isVibrate!) {
            _vibrate.invokeMethod('vibrate');
          }
          if (defaultTargetPlatform == TargetPlatform.iOS) {
            if (sound != null) {
              RingerMode ringerMode = await FlutterMute.getRingerMode();
              if(ringerMode == RingerMode.Normal) {
                final player = AudioPlayer();
                player.play(AssetSource(sound!["asset"]));
              }
            }
          }
        } catch (e) {
          print(e);
        }
      }
    }
    if (notificationInForeground != null) {
      notificationInForeground!();
    }
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
