//
//  KHAppDelegate.h
//  StartWithOpenGL
//
//  Created by admin on 14-8-12.
//  Copyright (c) 2014年 ___HUSHUHUI___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OpenGLView.h"



@interface KHAppDelegate : UIResponder <UIApplicationDelegate>
{
    OpenGLView* _glView;
}

@property (strong, nonatomic) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet OpenGLView *glView;

@end
