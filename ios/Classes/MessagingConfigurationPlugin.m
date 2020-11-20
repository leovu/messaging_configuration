#import "MessagingConfigurationPlugin.h"
#import <AudioToolbox/AudioToolbox.h>
#import <UserNotifications/UserNotifications.h>

@interface MessagingConfigurationPlugin ()
@end

@implementation MessagingConfigurationPlugin {}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter.io/vibrate"
            binaryMessenger:[registrar messenger]];
    MessagingConfigurationPlugin* instance = [[MessagingConfigurationPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
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
  else {
    result(FlutterMethodNotImplemented);
  }
}

@end
