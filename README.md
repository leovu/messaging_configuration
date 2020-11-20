# messaging_configuration

A new flutter plugin project.

## Getting Started

In Flutter, don't remove SharePreference with key : "PUSH_TOKEN_KEY" or clear all. If you clear all, get the key before clear and resave it to SharePrefernces.
You can only choose 1 between AWS and Firebase in iOS. If you choose Firebase, don't do the steps of AWS. 

    import 'package:messaging_configuration/messaging_configuration.dart';
    class MyApp extends StatelessWidget {
      // This widget is the root of your application.
      @override
      Widget build(BuildContext context) {
        changeStatusBarColor(Colors.transparent, true);
        setupLanguage();
        return OverlaySupport(
          child: MaterialApp(
          
    Add OverlaySupport in main.dart or wrap your MaterialApp 
    ..........
    
    
    String deviceToken: await MessagingConfiguration.getPushToken(isAWS: true);
    // If iOS use AWS , set isAWS = true, else it will use the Firebase setting
    
    
    void initState() {
       WidgetsBinding.instance.addPostFrameCallback((_) async {
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
          
          // If you need sound, create folder asset in the same parent with lib folder. ex: project_name/assets/audio/alert_tone.mp3. 
          You need to remove assets when put in the sound. If you forget, it will not have sound. Then in pubspec.yaml , you add : 
                    assets:
                        - assets/audio/alert_tone.mp3
                        - assets/logo/icon-app.png

    }
    Future<void> _notificationType(Map<String, dynamic> message) async {
      if (message["data"]["notification_detail_id"] != null) {
        // todo something
      }
    }
    

***In Android:***

   - download the generated google-services.json file and place it inside android/app.
   - add the classpath to the [project]/android/build.gradle file.
    
          dependencies {
            // Example existing classpath
            classpath 'com.android.tools.build:gradle:3.5.3'
            // Add the google services classpath
            classpath 'com.google.gms:google-services:4.3.2'
          }
   - add the apply plugin to the [project]/android/app/build.gradle file.
   
          dependencies {
            implementation 'com.google.firebase:firebase-messaging:20.0.1'
          }
          apply plugin: 'com.google.gms.google-services'
          
   - add to AndroidManifest
          
          <uses-permission android:name="android.permission.WAKE_LOCK" />
       
          <application
          .....
            <intent-filter>
              <action android:name="FLUTTER_NOTIFICATION_CLICK" />
              <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>
          </application>
          

***In iOS:***

  - download the generated GoogleService-Info.plist file and place it inside project via Xcode.
  - In Xcode, select Runner in the Project Navigator. In the Capabilities Tab turn on Push Notifications and Background Modes, and enable Background fetch and Remote notifications under Background Modes.
  - Upload your APNs certificate
  
 ******AWS Push******
 Copy file PushToken in Example and add into your project. 
 In AppDelegate: 
 
      import UIKit
      import Flutter

      @UIApplicationMain
      @objc class AppDelegate: FlutterAppDelegate {
        override func application(
          _ application: UIApplication,
          didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
          GeneratedPluginRegistrant.register(with: self)
          PushToken.shared.setupAnalyzing(window: window, application: application)
          return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
    }
    
