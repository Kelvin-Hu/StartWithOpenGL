//
//  OpenGLView.h
//  StartWithOpenGL
//
//  Created by admin on 14-8-12.
//  Copyright (c) 2014年 ___HUSHUHUI___. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

@interface OpenGLView : UIView
{
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderbuffer;
    
    GLuint _positionSlot;
    GLuint _colorSlot;
    
    GLuint _projectionUniform;
    GLuint _modelViewUniform;
    
    float _currentRotation;
    
    GLuint _depthRenderBuffer;
}

@end

