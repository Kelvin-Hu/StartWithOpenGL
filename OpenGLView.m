//
//  OpenGLView.m
//  StartWithOpenGL
//
//  Created by admin on 14-8-12.
//  Copyright (c) 2014年 ___HUSHUHUI___. All rights reserved.
//


#import "OpenGLView.h"
#import "CC3GLMatrix.h"


typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

const Vertex Vertices[] = {
    {{1, -1, 0}, {1, 0, 0, 1}},
    {{1, 1, 0}, {1, 0, 0, 1}},
    {{-1, 1, 0}, {0, 1, 0, 1}},
    {{-1, -1, 0}, {0, 1, 0, 1}},
    {{1, -1, -1}, {1, 0, 0, 1}},
    {{1, 1, -1}, {1, 0, 0, 1}},
    {{-1, 1, -1}, {0, 1, 0, 1}},
    {{-1, -1, -1}, {0, 1, 0, 1}}
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 7, 6,
    // Left
    2, 7, 3,
    7, 6, 2,
    // Right
    0, 4, 1,
    4, 1, 5,
    // Top
    6, 2, 1,
    1, 6, 5,
    // Bottom
    0, 3, 7,
    0, 7, 4
};




@implementation OpenGLView


//默认的layer时CALayer，为了能够显示OpenGL的内容，需要使用CAEAGLLayer
+(Class)layerClass{
    return [CAEAGLLayer class];
}


 
//设置layer为不透明
-(void) setupLayer{
    //将UIView中默认的layer强制类型装换为CAEAGLLayer
    //缺省情况下，CALayer是透明的
    //透明的层对性能负荷很大
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;
}

//创建OpenGL context
-(void) setupContext{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}
 

//以下的所有调用gl原生的方法，都是对于OpenGL currentContext来设置的
//所以上面的方法除了将UIView的context设置成EAGLContext外
//还需要设置[EAGLContext setCurrentContex:---]来配置一个全局的当前的context


//创建renderbuffer
/*
 //1.调⽤用glGenRenderbuffers来创建⼀一个新的render buffer object。这⾥里返 回⼀一个唯⼀一的integer来标记render buffer(这⾥里把这个唯⼀一值赋值到 _colorRenderBuffer)。有时候你会发现这个唯⼀一值被⽤用来作为程序内的⼀一个 OpenGL 的名称。(反正它唯⼀一嘛)
 //2.调⽤用glBindRenderbuffer ,告诉这个OpenGL:我在后⾯面引⽤用 GL_RENDERBUFFER的地⽅方,其实是想⽤用_colorRenderBuffer。其实就是告诉 OpenGL,我们定义的buffer对象是属于哪⼀一种OpenGL对象
￼￼ //3.最后,为render buffer分配空间:renderbufferStorage
*/
-(void) setupRenderbuffer{
    //1代表申请缓存的数量，传递指针进去，获取返回值
    glGenRenderbuffers(1, &_colorRenderbuffer);
    //第一个参数是缓存的类型，由于每个类型的缓存，当前只能绑定一个缓存实例
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    //与layer共享一块内存，因此渲染的东西可以显示在layer上
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}


//创建一个framebuffer
-(void)setupFramebuffer{
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    //frameBuffer包含renderBuffer等其他一系列的buffer
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);
}




- (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {
    //1，获取shader路径
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error;
    //由url中取出内容
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
    
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    //2，创建一个代表shader的对象，实际上是shader的identifier
    GLuint shaderHandle = glCreateShader(shaderType);
    
    //3，告诉OpenGL,shader的源代码是什么，其中涉及将NSString转换成C-String
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    //4，运行时编译shader
    glCompileShader(shaderHandle);
    
    //5，错误信息处理
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar message[256];
        glGetShaderInfoLog(shaderHandle, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"%@", messageString);
        exit(1);
    }

    return shaderHandle;
}

- (void)compileShaders {
    //1，编译vertex和fragment的shader
    GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment" withType:GL_FRAGMENT_SHADER];
    
    //2，调用系统方法，实现将两个着色器组件成一个完整的程序
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    //3，检查并显示错误输出
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar message[256];
        glGetProgramInfoLog(programHandle, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    //4，真正运行该程序(不是现在马上执行程序，是等待有vertex输入时，就执行）
    glUseProgram(programHandle);
    
    //5,获取输入的指针，以便以后设定输入，并且调用函数去启动数组，默认下是关闭的
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    //获取常量的入口（指针）
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    _modelViewUniform = glGetUniformLocation(programHandle, "ModelView");
}


//VBO short for Vertex Buffer Objects
//这里创建的buffer都是跟上面一样，是属于当前context所管理的
//所以当当前context失效了，这些东西也就随之消失了
-(void) setupVBOs
{
    //vertex的类型是GL_ARRAY_BUFFER
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    //index的类型是GL_ELEMENT_ARRAY_BUFFER
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
}


//渲染
-(void)render:(CADisplayLink *)displayLink {
    //清扫屏幕
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    //-----------------------------------------------------------
    //-----------------------------------------------------------
    //-----------------------------------------------------------
    
    
    //计算投影变换矩阵
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    float h = 4.0f * self.frame.size.height / self.frame.size.width;
    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h/2 andTop:h/2 andNear:4 andFar:10];
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    //计算转换矩阵
    CC3GLMatrix *modelView = [CC3GLMatrix matrix];
    [modelView populateFromTranslation:CC3VectorMake(sin(CACurrentMediaTime()), 0, -7)];
    //duration现在到下一次的时间间隔
    //而这个时间间隔是有每秒的刷新频率而定的
    //所以最终达到了每秒90度的旋转
    _currentRotation +=displayLink.duration * 90;
    [modelView rotateBy:CC3VectorMake(_currentRotation, _currentRotation, 0)];
    //把所有变换都设定好后，最后给出一个matrix并加载在vertex上
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
    
    
    
    //-----------------------------------------------------------
    //-----------------------------------------------------------
    //-----------------------------------------------------------
    
    
    
    //1
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    //2
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*)(sizeof(float)*3));
    
    //3
    
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]),
                   GL_UNSIGNED_BYTE, 0);
    
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

-(void) setupDisplayLink
{
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

//把前面的动作串联起来
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContext];
        [self setupRenderbuffer];
        [self setupFramebuffer];
        [self compileShaders];
        [self setupVBOs];
        [self setupDisplayLink];
    }
    return self;
}

- (void)dealloc {
     _context = nil;
}

@end




