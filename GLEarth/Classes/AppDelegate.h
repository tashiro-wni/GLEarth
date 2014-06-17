//
//  AppDelegate.h
//  GLEarth
//
//  Created by Tomohiro Tashiro on 2014/04/13.
//  Copyright (c) 2014年 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EAGLView;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) EAGLView *glView;

@end
