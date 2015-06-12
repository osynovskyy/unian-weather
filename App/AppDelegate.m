//
//  AppDelegate.m
//  App
//
//  Created by Oleksii Osynovskyi on 6/9/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

#import "AppDelegate.h"
#import <Quartz/Quartz.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet QCView *quartzView;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self.quartzView loadCompositionFromFile:[[NSBundle mainBundle] pathForResource:@"composition" ofType:@"qtz"]];
    
    [self.quartzView startRendering];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
