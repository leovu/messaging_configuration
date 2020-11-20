#import <Flutter/Flutter.h>

@interface MessagingConfigurationPlugin : NSObject<FlutterPlugin>
- (void)callbackFlutterNotification:(NSDictionary *)userInfo;
@end
