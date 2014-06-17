//
//  ES1Renderer.m
//  GLEarth
//
//  Created by Tomohiro Tashiro on 2014/04/13.
//  Copyright (c) 2014年 test. All rights reserved.
//

#import "ES1Renderer.h"

#include "Quaternion.hpp"

struct Animation {
    Quaternion Start;
    Quaternion End;
    Quaternion Current;
    float Elapsed;
    float Duration;
};

Animation m_animation;

// 深度バッファのハンドルを格納するグローバル関数
static GLuint depthBuffer = 0;

static void createDepthBuffer(GLuint screenWidth, GLuint screenHeight) {
    if(depthBuffer) {
        glDeleteRenderbuffersOES(1, &depthBuffer);
        depthBuffer = 0;
    }
    glGenRenderbuffersOES(1, &depthBuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthBuffer);
    glRenderbufferStorageOES(GL_RENDERBUFFER_OES,
                             GL_DEPTH_COMPONENT16_OES,
                             screenWidth, screenHeight);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES,
                                 GL_DEPTH_ATTACHMENT_OES,
                                 GL_RENDERBUFFER_OES,
                                 depthBuffer);
    glEnable(GL_DEPTH_TEST);
}

// VBOのハンドルを格納するグローバル変数
static GLuint sphereVBO;
static GLuint sphereIBO;

// 頂点のデータ構造を定義する構造体
typedef struct _Vertex {
    GLfloat x, y, z;
    GLfloat nx, ny, nz;
    GLfloat u, v;
} Vertex;

static int ynum = 32;  // 8
static int xnum = 64;  // 16

static void createSphere() {
    Vertex   sphereVertices[(xnum+1) * (ynum+1)];     // 17 * 9
    GLushort sphereIndices[3 * 2 * xnum * ynum];  // 3 * 32 * 8
    
    // 頂点データを生成
    Vertex* vertex = sphereVertices;
    for(int i = 0 ; i <= ynum ; ++i) {
        GLfloat v = i / (float)ynum;
        GLfloat y = cosf(M_PI * v);
        GLfloat r = sinf(M_PI * v);
        for(int j = 0 ; j <= xnum ; ++j) {
            GLfloat u = j / (float)xnum;
            Vertex data = {
                cosf(2 * M_PI * u) * r,  y, -sinf(2 * M_PI * u) * r, // 座標
                cosf(2 * M_PI * u) * r,  y, -sinf(2 * M_PI * u) * r, // 法線
                u, v                                                // UV
            };
            *vertex++ = data;
        }
    }
    
    // インデックスデータを生成
    GLushort* index = sphereIndices;
    for(int j = 0 ; j < ynum ; ++j) {
        int base = j * (xnum+1);
        for(int i = 0 ; i < xnum ; ++i) {
            *index++ = base + i;
            *index++ = base + i + 1;
            *index++ = base + i + (xnum+1);
            *index++ = base + i + (xnum+1);
            *index++ = base + i + 1;
            *index++ = base + i + 1 + (xnum+1);
        }
    }
    
    // VBOを作成
    GLuint buffers[2];
    glGenBuffers(2, buffers);
    sphereVBO = buffers[0];
    sphereIBO = buffers[1];
    
    // VBOを初期化し、データをコピー。
    glBindBuffer(GL_ARRAY_BUFFER, sphereVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sphereVertices),sphereVertices,GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    // IBOを初期化し、データをコピー。
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, sphereIBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(sphereIndices), sphereIndices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

@implementation ES1Renderer

// Create an ES 1.1 context
- (id)init
{
	if (self = [super init])
	{
        NSLog(@"%s", __FUNCTION__);
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context])
            return nil;
        
        angleX = angleY = angleZ = 0.0f;
        scale = 1.0f;
        
		// Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
		glGenFramebuffersOES(1, &defaultFramebuffer);
		glGenRenderbuffersOES(1, &colorRenderbuffer);
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
		
        NSLog(@"createSphare start");
        createSphere();

		//[self loadTextureName:@"hexmap2.jpg" texture:&earthTexture];
        [self loadTextureName:@"earth.jpg" texture:&earthTexture];
		//[self loadTextureName:@"cloud.jpg"   texture:&cloudTexture];
        //earthMatrixInitiallized = NO;
	}
	
	return self;
}

- (void)dealloc
{
	// Tear down GL
	if (defaultFramebuffer)
	{
		glDeleteFramebuffersOES(1, &defaultFramebuffer);
		defaultFramebuffer = 0;
	}
    
	if (colorRenderbuffer)
	{
		glDeleteRenderbuffersOES(1, &colorRenderbuffer);
		colorRenderbuffer = 0;
	}
	
	// Tear down context
	if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	
	context = nil;
}

- (void)render
{
    // EAGLコンテキストを設定する
    [EAGLContext setCurrentContext:context];
    
    // フレームバッファを設定する
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    
    // 球体描画
    [self drawScene];
    [self drawEarthAtx:0.0f y:0.0f z:-3.0f angleX:angleX angleY:angleY angleZ:angleZ scale:scale];
    //[self drawEarthAtx:0.0f y:3.0f z:-5.0f angleX:-angleX angleY:0.0f angleZ:0.0f scale:1.0f];
    
    // バッファを表示する
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
    // Allocate color buffer backing based on the current layer size
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    // 深度バッファを(再)作成する
    createDepthBuffer(backingWidth, backingHeight);
    
    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
    {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}

- (void)drawScene
{
    // 画面をクリア
    glViewport(0, 0, backingWidth, backingHeight);
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // ライトとマテリアルの設定
    //const GLfloat lightPos[]     = { 1.0f, 1.0f, 1.0f, 0.0f };  // 光源座標 x,y,z,w
    const GLfloat lightPos[]     = { 0.1f, 0.1f, 1.0f, 0.0f };  // 光源座標 x,y,z,w (0.2f, 0.2f, 1.0f, 0,0f) ... 正面よりやや右上から光をあてる
    const GLfloat lightColor[]   = { 1.0f, 1.0f, 1.0f, 1.0f };  // 光の色 r,g,b,a
    const GLfloat lightAmbient[] = { 0.0f, 0.0f, 0.0f, 1.0f };
    const GLfloat diffuse[]      = { 0.7f, 0.7f, 0.7f, 1.0f };  // 拡散光
    const GLfloat ambient[]      = { 0.6f, 0.6f, 0.6f, 1.0f };  // 環境光
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glLightfv(GL_LIGHT0, GL_POSITION, lightPos);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, lightColor);
    glLightfv(GL_LIGHT0, GL_AMBIENT, lightAmbient);
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, diffuse);
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, ambient);  // 環境光 (光源以外からの光) に対する反射係数で, 光の当たらない部分の明るさ

    // シーンの射影行列を設定
    glMatrixMode(GL_PROJECTION);
    const GLfloat near  = 0.1f, far = 1000.0f;
    const GLfloat aspect = (GLfloat)backingWidth / (GLfloat)backingHeight;
    const GLfloat width = near * tanf(M_PI * 60.0f / 180.0f / 2.0f);
    glLoadIdentity();
    glFrustumf(-width, width, -width / aspect, width / aspect, near, far);
}

- (void)drawEarthAtx:(GLfloat)x y:(GLfloat)y z:(GLfloat)z
              angleX:(GLfloat)ax angleY:(GLfloat)ay angleZ:(GLfloat)az
               scale:(GLfloat)sc
{
    // 球体の変換行列を設定
    glMatrixMode(GL_MODELVIEW);
//    if( ! earthMatrixInitiallized ){
        glLoadIdentity();
        glTranslatef(x, y, z);  // 地球の中心座標
//        earthMatrixInitiallized = YES;
        
//    } else {
//        glPopMatrix();
//    }
    
    // 頂点データを設定
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glBindBuffer(GL_ARRAY_BUFFER, sphereVBO);
    
    glVertexPointer(   3, GL_FLOAT, sizeof(Vertex), 0);
    glNormalPointer(      GL_FLOAT, sizeof(Vertex), (GLvoid*)(sizeof(GLfloat)*3) );
    glTexCoordPointer( 2, GL_FLOAT, sizeof(Vertex), (GLvoid*)(sizeof(GLfloat)*6) );
    
    // インデックスデータを設定
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, sphereIBO);
    
    // テクスチャを設定して、双線形補完を有効にする
    glEnable(GL_TEXTURE_2D);
    //  glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    //	glEnable(GL_BLEND);
    //  glEnable(GL_ALPHA);
    
    glBindTexture(GL_TEXTURE_2D, earthTexture);
    //glBindTexture(GL_TEXTURE_2D, cloudTexture);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
	// 球体を回転させる
    //GLfloat l = sqrt(ax * ax + ay * ay);
    //if( l > 0 ){
    //    glRotatef(l, ay/l, ax/l, 0.0f);
    //}
    glRotatef(angleX, 0.0f, 1.0f, 0.0f);
    glRotatef(angleY, 1.0f, 0.0f, 0.0f);
    
    glScalef(sc,sc,sc);  // 拡大率
/*
    mat4 rotation(m_animation.Current.ToMatrix());
    glMultMatrixf(rotation.Pointer());
*/  
    //glPushMatrix();
    
    // 球体を描画
    glDrawElements(GL_TRIANGLES, 3 * 2 * xnum * ynum, GL_UNSIGNED_SHORT, 0);
    
    // bindを解除
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)loadTextureName:(NSString *)imageFile texture:(GLuint *)texture
{
    // 画像を読み込み、 32bit RGBA フォーマットのデータを取得
    NSLog(@"--aaa--");
    CGImageRef image  = [UIImage imageNamed:imageFile].CGImage;
    NSLog(@"--bbb--");
    GLsizei    width  = (GLsizei)CGImageGetWidth(image);
    GLsizei    height = (GLsizei)CGImageGetHeight(image);
    GLubyte*   bits   = (GLubyte*)malloc(width * height * 4);
    NSLog( @"loadTextureName:%@, width:%d, height:%d, texture:%d", imageFile, width, height, *texture);
    CGContextRef textureContext = CGBitmapContextCreate(bits, width, height, 8, width * 4,
                                                        CGImageGetColorSpace(image),
                                                        (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(textureContext, CGRectMake(0.0, 0.0, width, height), image);
    CGContextRelease(textureContext);
    
    // テクスチャを作成し、データを転送
    glGenTextures(1, texture);
    glBindTexture(GL_TEXTURE_2D, *texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, bits);
    glBindTexture(GL_TEXTURE_2D, 0);
    free(bits);
}

#pragma mark Gestures

- (void)view:(UIView*)view handleRotationGesture:(UIRotationGestureRecognizer *)sender
{
    UIRotationGestureRecognizer *rotation = (UIRotationGestureRecognizer *)sender;
    //NSLog(@"rotation rad=%f, velocity=%f", rotation.rotation, rotation.velocity);
    
    angleZ += rotation.rotation;
    
    if( angleZ <   0.0f )  angleZ += 360.0f;
    if( angleZ > 360.0f )  angleZ -= 360.0f;
    
    //NSLog( @"angleX:%5.1f, angleY:%5.1f, angleZ:%5.1f, scale:%4.2f", angleX, angleY, angleZ, scale );
}

- (void)view:(UIView*)view handlePanGesture:(UIPanGestureRecognizer *)sender
{
    // ドラッグで移動した距離を取得する
    CGPoint p = [sender translationInView:view];
    //NSLog(@"drag dx=%f, dy=%f", p.x, p.y);
    
    angleX += p.x;
    angleY += p.y;
   
    if( angleX <   0.0f )  angleX += 360.0f;
    if( angleX > 360.0f )  angleX -= 360.0f;
    if( angleY <   0.0f )  angleY += 360.0f;
    if( angleY > 360.0f )  angleY -= 360.0f;
     
    //NSLog( @"angleX:%5.1f, angleY:%5.1f, angleZ:%5.1f, scale:%4.2f", angleX, angleY, angleZ, scale );
	
/*
    // 回転軸は Pan の移動方向と垂直
    vec3 axis = vec3( p.y, p.x, 0.0f );
    float rot = sqrt( p.x * p.x + p.y * p.y );
    m_animation.Elapsed = 0;
    m_animation.Start = m_animation.Current = m_animation.End;
    m_animation.End = Quaternion::CreateFromVectors(vec3(0, 1, 0), axis);
*/
    
    // ドラッグで移動した距離を初期化する
    // これを行わないと、[sender translationInView:]が返す距離は、ドラッグが始まってからの蓄積値となるため、
    // 今回のようなドラッグに合わせてImageを動かしたい場合には、蓄積値をゼロにする
    [sender setTranslation:CGPointZero inView:view];
}

- (void)view:(UIView*)view handlePinchGesture:(UIPinchGestureRecognizer *)sender
{
    UIPinchGestureRecognizer* pinch = (UIPinchGestureRecognizer*)sender;
    
    scale *= pinch.scale;
    if( scale < 0.5f )  scale = 0.5f;
    if( scale > 2.0f )  scale = 2.0f;
    
    NSLog( @"angleX:%5.1f, angleY:%5.1f, angleZ:%5.1f, scale:%4.2f", angleX, angleY, angleZ, scale );
    pinch.scale = 1.0f;  // リセット
}

@end
