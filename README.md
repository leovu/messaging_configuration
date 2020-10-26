# messaging_configuration

A new flutter plugin project.

## Getting Started

In Flutter, don't remove SharePreference with key : "PUSH_TOKEN_KEY" or clear all. If you clear all, get the key before clear and resave it to SharePrefernces.


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
          
          // If you need sound, create folder asset in the same parent with lib folder. ex: project_name/assets/audio/alert_tone.mp3. You need to remove assets when put in the         the sound. If you forget, it will not have sound. Then in pubspec.yaml , you add : 
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
          PushToken.shared.setupAnalyzing(window: window)
          createNotification(application)
          return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
          private func createNotification(_ application: UIApplication) {
              if #available(iOS 10.0, *) {
                  UNUserNotificationCenter.current().delegate = self
                  let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                  UNUserNotificationCenter.current().requestAuthorization(
                      options: authOptions,
                      completionHandler: {_, _ in })
              } else {
                  let settings: UIUserNotificationSettings =
                      UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                  application.registerUserNotificationSettings(settings)
              }
              application.registerForRemoteNotifications()
          }

          // Get Push Notification Token
          override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
              let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
              // Save push notification token to share pref -- clear prefs, ios must resaved by flutter. Because this function usually called 1 time.
              Common.PUSH_TOKEN = token
              print(token)
          }


          // Start
          // When have notification from server, call Flutter function
          @available(iOS 10.0, *)
          // When foreground
          override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
              print(notification.request.content.userInfo)
              callbackFlutterNotifcation(notification.request.content.userInfo)
          }
          // When background/kill app
          override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
              print(userInfo)
              callbackFlutterNotifcation(userInfo)
              completionHandler(UIBackgroundFetchResult.newData)
          }
          // When background/kill app
          override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
              print(userInfo)
              callbackFlutterNotifcation(userInfo)
          }
          // End
          @available(iOS 10.0, *)
          override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
              callbackFlutterNotifcation(response.notification.request.content.userInfo)
          }

          // Parse value data from notification before push to Flutter
          func callbackFlutterNotifcation(_ userInfo:[AnyHashable : Any]) {
              // [Anyhashable:Any] -> Map<String,dynamic>
              var dictionary:[String:Any] = [:]
              if let controller = window.rootViewController as? FlutterViewController , let dict = userInfo as? [String:Any] {
                  dictionary = dict
                  // iOS : notification - aps.
                  if let aps:[String:Any] = dict["aps"] as? [String : Any] {
                      dictionary["notification"] = aps["alert"]
                      dictionary.removeValue(forKey: "aps")
                  }
                  let state = UIApplication.shared.applicationState
                  let channel =  FlutterMethodChannel(name: "flutter.io/notificationTap", binaryMessenger: controller.binaryMessenger)
                  if state == .active {
                      channel.invokeMethod("onMessage", arguments: dictionary)
                  } else {
                      channel.invokeMethod("onLaunch", arguments: dictionary)
                  }
              }
          }
    }
   
      let PUSH_TOKEN_KEY = "flutter.PUSH_TOKEN_KEY"
      class Common {
          static let shared = Common()
          static var PUSH_TOKEN: String {
              get {
                  return UserDefaults.standard.string(forKey: PUSH_TOKEN_KEY) ?? ""
              }set {
                  UserDefaults.standard.set(newValue, forKey: PUSH_TOKEN_KEY)
              }
          }
          var deviceUIID : String {
              return UIDevice.current.identifierForVendor!.uuidString
          }
      }

      class PushToken {
          func receivePushNotificationToken(result: FlutterResult) {
              result(Common.PUSH_TOKEN)
          }
          static let shared = PushToken()
          func setupAnalyzing(window:UIWindow) {
              let controller : FlutterViewController = window.rootViewController as! FlutterViewController
              let channel = FlutterMethodChannel(name: "flutter.io/receivePushNotificationToken",
                                                 binaryMessenger: controller.binaryMessenger)
              channel.setMethodCallHandler({
                  [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                  guard call.method == "receivePushNotificationToken" else {
                      result(FlutterMethodNotImplemented)
                      return
                  }
                  self?.receivePushNotificationToken(result: result)
              })
          }
      }

    
