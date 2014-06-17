//
//  EAGLView.m
//  GLEarth
//
//  Created by Tomohiro Tashiro on 2014/04/13.
//  Copyright (c) 2014年 test. All rights reserved.
//

#import "EAGLView.h"

#import "ES1Renderer.h"

@implementation EAGLView

@synthesize animating;
@dynamic animationFrameInterval;

// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:(CGRect)frame]))
	{
        NSLog(@"%s", __FUNCTION__);
        self.contentScaleFactor = [UIScreen mainScreen].scale;  // Retina対応
        
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking : @FALSE,
                                          kEAGLDrawablePropertyColorFormat     : kEAGLColorFormatRGBA8, };
		
        renderer = ES1Renderer.new;
        
        if (!renderer)  return nil;
        
		animating = FALSE;
		animationFrameInterval = 1;
		displayLink = nil;
    }
	
    return self;
}

- (void)drawView:(id)sender
{
    [renderer render];
}

- (void)layoutSubviews
{
	[renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [self drawView:nil];
}

- (NSInteger)animationFrameInterval
{
	return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
	// Frame interval defines how many display frames must pass between each time the
	// display link fires. The display link will only fire 30 times a second when the
	// frame internal is two on a display that refreshes 60 times a second. The default
	// frame interval setting of one will fire 60 times a second when the display refreshes
	// at 60 times a second. A frame interval setting of less than one results in undefined
	// behavior.
	if (frameInterval >= 1)
	{
		animationFrameInterval = frameInterval;
		
		if (animating)
		{
			[self stopAnimation];
			[self startAnimation];
		}
	}
}

- (void)startAnimation
{
	if (!animating) {
        displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
        [displayLink setFrameInterval:animationFrameInterval];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
		animating = TRUE;
        
        // add GestureRecognizer
        [self addGestureRecognizers];
	}
}

- (void)stopAnimation
{
	if (animating)
	{
        [displayLink invalidate];
        displayLink = nil;
        
		animating = FALSE;
        
        // remove GestureRecognizers
        [self removeGestureRecognizers];
	}
}

# pragma mark Gesture
- (void)addGestureRecognizers
{
    NSLog( @"%s", __FUNCTION__ );
    //UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotationGesture:)];
    //[self addGestureRecognizer:rotationGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:panGesture];
    
    UIPinchGestureRecognizer* pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self addGestureRecognizer:pinchGesture];
}

- (void)removeGestureRecognizers
{
    NSLog( @"%s", __FUNCTION__ );
    for (UIGestureRecognizer *gesture in self.gestureRecognizers)
        [self removeGestureRecognizer:gesture];
}

- (void)handleRotationGesture:(UIRotationGestureRecognizer *)sender
{
    [renderer view:self handleRotationGesture:sender];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender
{
    [renderer view:self handlePanGesture:sender];
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)sender
{
    [renderer view:self handlePinchGesture:sender];
}

@end
