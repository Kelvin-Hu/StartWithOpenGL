//
//  KHAppDelegate.m
//  StartWithOpenGL
//
//  Created by admin on 14-8-12.
//  Copyright (c) 2014年 ___HUSHUHUI___. All rights reserved.
//

#import "KHAppDelegate.h"

@implementation KHAppDelegate

@synthesize glView=_glView;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    self.glView = [[OpenGLView alloc] initWithFrame:screenBounds];
    [self.window addSubview:_glView];
    
    [self.window makeKeyAndVisible];
    return YES;
}


@end