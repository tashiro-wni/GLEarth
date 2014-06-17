//
//  AppDelegate.m
//  GLEarth
//
//  Created by Tomohiro Tashiro on 2014/04/13.
//  Copyright (c) 2014年 test. All rights reserved.
//

#import "AppDelegate.h"
#import "EAGLView.h"

@implementation AppDelegate

@synthesize window;
@synthesize glView;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog( @"bundle identifier: %@", [NSBundle.mainBundle objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey] );
    NSLog( @"iOS version:%@, %@ version:%@",
          UIDevice.currentDevice.systemVersion,
          [NSBundle.mainBundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey],
          [NSBundle.mainBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] );
    if( [UIDevice.currentDevice respondsToSelector:@selector(identifierForVendor)] )
        NSLog( @"ID for vender:%@", UIDevice.currentDevice.identifierForVendor.UUIDString );
    
    // setup window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    glView = [[EAGLView alloc] initWithFrame:self.window.frame];
    [self.window addSubview:glView];
    [self.window makeKeyAndVisible];
    
    [glView startAnimation];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	[glView stopAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[glView startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[glView stopAnimation];
}

@end
