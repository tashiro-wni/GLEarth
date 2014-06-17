//
//  ESRenderer.h
//  GLEarth
//
//  Created by Tomohiro Tashiro on 2014/04/13.
//  Copyright (c) 2014年 test. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

@protocol ESRenderer <NSObject>

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;

@optional
- (void)view:(UIView*)view handleRotationGesture:(UIRotationGestureRecognizer *)sender;
- (void)view:(UIView*)view handlePanGesture:(UIPanGestureRecognizer *)sender;
- (void)view:(UIView*)view handlePinchGesture:(UIPinchGestureRecognizer *)sender;

@end
