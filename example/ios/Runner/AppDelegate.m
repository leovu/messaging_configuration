#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  PushToken.shared.setupAnalyzing(window: window, application: application)
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
