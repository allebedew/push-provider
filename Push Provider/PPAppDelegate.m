//
//  PPAppDelegate.m
//  Push Provider
//
//  Created by Alex Lebedev on 31/1/13.
//  Copyright (c) 2013 Alex Lebedev. All rights reserved.
//

#import "PPAppDelegate.h"

@implementation PPAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//    [NSApp registerForRemoteNotificationTypes:NSRemoteNotificationTypeBadge|NSRemoteNotificationTypeSound|NSRemoteNotificationTypeAlert];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (void)application:(NSApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"registered: %@", deviceToken);
}

- (void)application:(NSApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"filed to register: %@", error);
}

@end
