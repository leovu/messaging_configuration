#import "MessagingConfigurationPlugin.h"
#import <AudioToolbox/AudioToolbox.h>
#import <UserNotifications/UserNotifications.h>

@interface MessagingConfigurationPlugin ()
@end

@implementation MessagingConfigurationPlugin {
  FlutterMethodChannel *_channel;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter.io/vibrate"
            binaryMessenger:[registrar messenger]];
    MessagingConfigurationPlugin* instance = [[MessagingConfigurationPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterMethodChannel *awsChannel = [FlutterMethodChannel
        methodChannelWithName:@"flutter.io/awsMessaging"
              binaryMessenger:[registrar messenger]];
    MessagingConfigurationPlugin *awsInstance =
        [[MessagingConfigurationPlugin alloc] initWithChannel:channel];
    [registrar addMethodCallDelegate:awsInstance channel:awsChannel];
    [registrar addApplicationDelegate:awsInstance];
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
  self = [super init];
  if (self) {
    _channel = channel;
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"vibrate" isEqualToString:call.method]) {
    if([[UIDevice currentDevice].model isEqualToString:@"iPhone"])
    {
       AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    else
    {
       AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
    result(@"vibrate completed");
  }
  else if ([@"getToken" isEqualToString:call.method]) {
      NSString *token = [[NSUserDefaults standardUserDefaults]
          stringForKey:@"flutter.PUSH_TOKEN_KEY"];
      result(token);
    }
  else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [self stringWithDeviceToken:deviceToken];
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"flutter.PUSH_TOKEN_KEY"];
    [[NSUserDefaults standardUserDefaults] synchronize];

}

- (NSString *)stringWithDeviceToken:(NSData *)deviceToken {
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];
    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhx", data[i]];
    }
    return [token copy];
}

- (void)callbackFlutterNotification:(NSDictionary *)userInfo {
    NSMutableDictionary *response = [NSMutableDictionary new];
    [response setDictionary:userInfo];
    @try {
        if([userInfo objectForKey:@"aps"]) {
            [response setObject:userInfo[@"aps"][@"alert"] forKey:@"notification"];
            [response removeObjectForKey:@"aps"];
        }
     }
     @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
     }
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateActive) {
        [_channel invokeMethod:@"onMessage" arguments:response];
    } else {
        [_channel invokeMethod:@"onLaunch" arguments:response];
    }
}

@end
